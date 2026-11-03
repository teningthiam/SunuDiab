package com.sunudiab.service;

import com.sunudiab.dto.Dtos.*;
import com.sunudiab.dto.Mapper;
import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import com.sunudiab.exception.ApiException;
import com.sunudiab.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatService {
    private static final String URGENCE_TEXTE = "Ces signes peuvent être graves. Appelle immédiatement le SAMU au 1515 "
            + "ou rends-toi aux urgences les plus proches. Ne reste pas seul(e) : demande à un proche de rester avec toi.";
    private static final String INDISPONIBLE_TEXTE = "L'assistant n'est pas disponible pour le moment. "
            + "En cas de malaise ou de doute, contacte ton médecin ou appelle le SAMU au 1515.";
    private static final List<String> MOTS_URGENCE = List.of(
            "perdu connaissance", "perte de connaissance", "évanoui", "evanoui", "inconscient", "convulsion",
            "confus", "malaise", "douleur dans la poitrine", "douleur poitrine", "douleur thoracique",
            "respire mal", "difficulté à respirer", "difficulte a respirer", "haleine fruitée", "coma",
            "vomis", "vomissements");

    private static final String SYSTEME = """
            Tu es l'assistant SunuDiab, un guide d'information sur le diabète pour des patients au Sénégal. Tu n'es pas médecin.
            Règles strictes :
            - Réponds en français simple, avec des phrases courtes. Si la personne écrit en wolof, réponds quand même en français simple et propose d'écouter l'audio.
            - Ne pose JAMAIS de diagnostic et ne donne JAMAIS de pourcentage de probabilité de maladie.
            - Ne modifie JAMAIS un traitement, une dose, ni l'insuline. Renvoie vers le médecin.
            - Pour tout symptôme inquiétant, conseille de consulter un professionnel de santé. En cas de signes graves (perte de connaissance, confusion, vomissements, douleur thoracique, difficulté à respirer), dis d'appeler le SAMU au 1515.
            - Adapte les conseils alimentaires à la cuisine sénégalaise (thiéboudiène, mafé, yassa, fonio, mil, gombo...).
            - Reste dans le domaine de la santé et du diabète. Réponds en 120 mots maximum.
            """;

    private final ChatRepository chats;
    private final MesureRepository mesures;
    private final AlerteService alertes;

    @org.springframework.beans.factory.annotation.Value("${anthropic.api-key:}")
    private String apiKey;
    @org.springframework.beans.factory.annotation.Value("${anthropic.model}")
    private String model;

    private final org.springframework.web.client.RestClient http = buildClient();

    private static org.springframework.web.client.RestClient buildClient() {
        var f = new org.springframework.http.client.SimpleClientHttpRequestFactory();
        f.setConnectTimeout(5000);
        f.setReadTimeout(30000);
        return org.springframework.web.client.RestClient.builder().baseUrl("https://api.anthropic.com").requestFactory(f).build();
    }

    public ChatReply repondre(PatientProfile p, String message) {
        sauver(p, AuteurChat.PATIENT, message, false);
        if (detecterUrgence(message)) {
            alertes.symptomes(p, message);
            ChatMessage m = sauver(p, AuteurChat.ASSISTANT, URGENCE_TEXTE, true);
            return new ChatReply(URGENCE_TEXTE, true, true, m.getCreatedAt());
        }
        if (apiKey == null || apiKey.isBlank()) {
            ChatMessage m = sauver(p, AuteurChat.ASSISTANT, INDISPONIBLE_TEXTE, false);
            return new ChatReply(INDISPONIBLE_TEXTE, false, false, m.getCreatedAt());
        }
        try {
            String texte = appelerModele(p);
            ChatMessage m = sauver(p, AuteurChat.ASSISTANT, texte, false);
            return new ChatReply(texte, false, true, m.getCreatedAt());
        } catch (Exception e) {
            log.warn("Appel à l'assistant IA impossible : {}", e.getMessage());
            ChatMessage m = sauver(p, AuteurChat.ASSISTANT, INDISPONIBLE_TEXTE, false);
            return new ChatReply(INDISPONIBLE_TEXTE, false, false, m.getCreatedAt());
        }
    }

    @Transactional(readOnly = true)
    public List<ChatMessageDto> historique(Long patientId) {
        List<ChatMessage> l = new ArrayList<>(chats.findTop50ByPatientIdOrderByCreatedAtDesc(patientId));
        Collections.reverse(l);
        return l.stream().map(c -> Mapper.toDto(c)).toList();
    }

    private ChatMessage sauver(PatientProfile p, AuteurChat auteur, String contenu, boolean urgence) {
        ChatMessage m = new ChatMessage();
        m.setPatient(p);
        m.setAuteur(auteur);
        m.setContenu(contenu);
        m.setUrgence(urgence);
        return chats.save(m);
    }

    static boolean detecterUrgence(String message) {
        String m = message.toLowerCase(Locale.ROOT);
        return MOTS_URGENCE.stream().anyMatch(m::contains);
    }

    private String appelerModele(PatientProfile p) {
        // Contexte minimal et sans identité : type de diabète et dernière glycémie uniquement.
        String contexte = "Contexte du patient (sans identité) : type de diabète = " + p.getTypeDiabete();
        var derniere = mesures.findFirstByPatientIdAndSupprimeFalseOrderByMesureLeDesc(p.getId());
        if (derniere.isPresent()) {
            contexte += " ; dernière glycémie = " + String.format(Locale.ROOT, "%.2f", derniere.get().getValeur())
                    + " g/L (cible " + p.getCibleMin() + " à " + p.getCibleMax() + ").";
        }

        List<ChatMessage> hist = new ArrayList<>(chats.findTop12ByPatientIdOrderByCreatedAtDesc(p.getId()));
        Collections.reverse(hist);
        List<Map<String, String>> msgs = new ArrayList<>();
        for (ChatMessage c : hist) {
            String role = c.getAuteur() == AuteurChat.PATIENT ? "user" : "assistant";
            if (!msgs.isEmpty() && msgs.get(msgs.size() - 1).get("role").equals(role)) {
                Map<String, String> last = msgs.get(msgs.size() - 1);
                last.put("content", last.get("content") + "\n" + c.getContenu());
            } else {
                Map<String, String> n = new HashMap<>();
                n.put("role", role);
                n.put("content", c.getContenu());
                msgs.add(n);
            }
        }
        while (!msgs.isEmpty() && !"user".equals(msgs.get(0).get("role"))) msgs.remove(0);

        Map<String, Object> body = new HashMap<>();
        body.put("model", model);
        body.put("max_tokens", 600);
        body.put("system", SYSTEME + "\n" + contexte);
        body.put("messages", msgs);

        com.fasterxml.jackson.databind.JsonNode root = http.post().uri("/v1/messages")
                .header("x-api-key", apiKey)
                .header("anthropic-version", "2023-06-01")
                .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(com.fasterxml.jackson.databind.JsonNode.class);
        String texte = root == null ? "" : root.path("content").path(0).path("text").asText("");
        if (texte.isBlank()) throw new IllegalStateException("Réponse vide");
        return texte;
    }
}

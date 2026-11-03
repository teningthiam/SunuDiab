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
public class RisqueService {
    public static final int SCORE_MAX = 26;
    private static final String AVERTISSEMENT = "Ce résultat est une estimation statistique (score FINDRISC), pas un diagnostic. "
            + "Seule une mesure de la glycémie à jeun ou de l'HbA1c, interprétée par un médecin, permet de confirmer un diabète. "
            + "Le score n'a pas été calibré spécifiquement sur la population sénégalaise.";

    private static final Map<String, String> TEXTES = new LinkedHashMap<>();

    static {
        TEXTES.put("CEREALES_LOCALES", "Remplace une partie du riz blanc par du mil, du sorgho ou du fonio, plus riches en fibres.");
        TEXTES.put("REDUIRE_SUCRES", "Limite les boissons sucrées industrielles et réduis le sucre dans l'ataya.");
        TEXTES.put("LEGUMES_LOCAUX", "Mange des légumes et des fruits chaque jour (chou, carotte, gombo, navet...).");
        TEXTES.put("ACTIVITE_PHYSIQUE", "Vise au moins 30 minutes d'activité physique par jour (marche rapide, travaux, sport).");
        TEXTES.put("PERDRE_POIDS", "Une perte de poids, même modeste, réduit nettement le risque de diabète.");
        TEXTES.put("SURVEILLER_TENSION", "Fais contrôler régulièrement ta tension artérielle.");
        TEXTES.put("CONSULTER_GLYCEMIE_JEUN", "Fais mesurer ta glycémie à jeun dans un poste de santé ou un laboratoire et parles-en à un médecin.");
    }

    private final EvaluationRisqueRepository evaluations;
    private final com.fasterxml.jackson.databind.ObjectMapper mapper;

    public static NiveauRisque niveau(int score) {
        if (score < 7) return NiveauRisque.FAIBLE;
        if (score <= 11) return NiveauRisque.LEGER;
        if (score <= 14) return NiveauRisque.MODERE;
        if (score <= 20) return NiveauRisque.ELEVE;
        return NiveauRisque.TRES_ELEVE;
    }

    private static String probabilite(NiveauRisque n) {
        return switch (n) {
            case FAIBLE -> "environ 1 personne sur 100";
            case LEGER -> "environ 1 personne sur 25";
            case MODERE -> "environ 1 personne sur 6";
            case ELEVE -> "environ 1 personne sur 3";
            case TRES_ELEVE -> "environ 1 personne sur 2";
        };
    }

    @Transactional
    public RisqueResult evaluer(PatientProfile p, RisqueRequest r) {
        int score = 0;
        int age = r.age();
        score += age < 45 ? 0 : age <= 54 ? 2 : age <= 64 ? 3 : 4;
        double m = r.tailleCm() / 100.0;
        double imc = r.poidsKg() / (m * m);
        score += imc < 25 ? 0 : imc <= 30 ? 1 : 3;
        double t = r.tourTailleCm();
        if (r.sexe() == Sexe.M) score += t < 94 ? 0 : t <= 102 ? 3 : 4;
        else score += t < 80 ? 0 : t <= 88 ? 3 : 4;
        score += switch (r.activite()) {
            case QUOTIDIEN -> 0;
            case PARFOIS -> 1;
            case RAREMENT -> 2;
        };
        score += r.fruitsLegumesQuotidien() ? 0 : 1;
        score += r.traitementHypertension() ? 2 : 0;
        score += r.glycemieElevee() ? 5 : 0;
        score += switch (r.antecedents()) {
            case AUCUN -> 0;
            case SECOND_DEGRE -> 3;
            case PREMIER_DEGRE -> 5;
        };

        NiveauRisque niveau = niveau(score);
        List<String> codes = new ArrayList<>();
        if (score >= 7) {
            codes.add("CEREALES_LOCALES");
            codes.add("REDUIRE_SUCRES");
        }
        if (imc >= 25) codes.add("PERDRE_POIDS");
        if (r.activite() != ActiviteFindrisc.QUOTIDIEN) codes.add("ACTIVITE_PHYSIQUE");
        if (!r.fruitsLegumesQuotidien()) codes.add("LEGUMES_LOCAUX");
        if (r.traitementHypertension()) codes.add("SURVEILLER_TENSION");
        if (niveau.ordinal() >= NiveauRisque.MODERE.ordinal() || r.glycemieElevee()) codes.add("CONSULTER_GLYCEMIE_JEUN");

        EvaluationRisque e = new EvaluationRisque();
        e.setPatient(p);
        e.setScore(score);
        e.setNiveau(niveau);
        e.setRecommandationsCodes(String.join(",", codes));
        try {
            e.setReponsesJson(mapper.writeValueAsString(r));
        } catch (com.fasterxml.jackson.core.JsonProcessingException ex) {
            e.setReponsesJson(null);
        }
        return toResult(evaluations.save(e));
    }

    @Transactional(readOnly = true)
    public List<RisqueResult> historique(Long patientId) {
        return evaluations.findByPatientIdOrderByCreatedAtDesc(patientId).stream().map(e -> toResult(e)).toList();
    }

    @Transactional
    public RisqueResult valider(User medecin, Long evaluationId, Long patientId) {
        EvaluationRisque e = evaluations.findById(evaluationId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Évaluation introuvable"));
        if (!e.getPatient().getId().equals(patientId)) throw new ApiException(HttpStatus.NOT_FOUND, "Évaluation introuvable");
        e.setValidee(true);
        e.setValidePar(medecin);
        e.setValideeLe(Instant.now());
        return toResult(evaluations.save(e));
    }

    private RisqueResult toResult(EvaluationRisque e) {
        List<String> codes = (e.getRecommandationsCodes() == null || e.getRecommandationsCodes().isBlank())
                ? List.of() : Arrays.asList(e.getRecommandationsCodes().split(","));
        List<String> textes = codes.stream().map(c -> TEXTES.getOrDefault(c, c)).toList();
        return new RisqueResult(e.getId(), e.getScore(), SCORE_MAX, e.getNiveau(), probabilite(e.getNiveau()),
                codes, textes, AVERTISSEMENT, e.getCreatedAt(), e.isValidee());
    }
}

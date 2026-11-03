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
public class GlycemieService {
    private final MesureRepository mesures;
    private final AlerteService alertes;

    /** Seuils en g/L. Hypoglycémie sévère < 0,54 g/L (54 mg/dL). La cible du patient est modifiable par son médecin. */
    public static StatutGlycemie evaluer(double v, double cibleMin, double cibleMax) {
        if (v < 0.54) return StatutGlycemie.HYPO_SEVERE;
        if (v < cibleMin) return StatutGlycemie.HYPO;
        if (v <= cibleMax) return StatutGlycemie.NORMAL;
        if (v <= 1.80) return StatutGlycemie.LEGEREMENT_ELEVE;
        if (v <= 2.50) return StatutGlycemie.ELEVE;
        return StatutGlycemie.CRITIQUE;
    }

    /** Création ou mise à jour idempotente (clé = clientUuid généré sur le téléphone). */
    @Transactional
    public MesureGlycemie enregistrerOuMaj(PatientProfile p, String clientUuid, double valeur, MomentMesure moment,
                                           MethodeSaisie methode, String contexte, String note, Instant mesureLe,
                                           boolean supprime) {
        MesureGlycemie m = (clientUuid == null) ? null : mesures.findByClientUuid(clientUuid).orElse(null);
        boolean nouvelle = (m == null);
        if (!nouvelle && !m.getPatient().getId().equals(p.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Mesure appartenant à un autre patient");
        }
        if (nouvelle) {
            m = new MesureGlycemie();
            m.setPatient(p);
            m.setClientUuid(clientUuid != null ? clientUuid : UUID.randomUUID().toString());
        }
        Instant maintenant = Instant.now();
        Instant quand = mesureLe != null ? mesureLe : maintenant;
        if (quand.isAfter(maintenant.plusSeconds(300))) quand = maintenant;   // horloge du téléphone en avance
        m.setValeur(valeur);
        m.setMoment(moment);
        m.setMethode(methode != null ? methode : MethodeSaisie.CLAVIER);
        m.setContexte(contexte);
        m.setNote(note);
        m.setMesureLe(quand);
        m.setStatut(evaluer(valeur, p.getCibleMin(), p.getCibleMax()));
        m.setSupprime(supprime);
        m = mesures.save(m);
        if (nouvelle && !supprime) alertes.depuisMesure(p, m);
        return m;
    }

    @Transactional
    public MesureResponse enregistrer(PatientProfile p, MesureRequest r) {
        MesureGlycemie m = enregistrerOuMaj(p, r.clientUuid(), r.valeur(), r.moment(), r.methode(), r.contexte(),
                r.note(), r.mesureLe(), false);
        boolean urgence = m.getStatut() == StatutGlycemie.HYPO_SEVERE || m.getStatut() == StatutGlycemie.CRITIQUE;
        return new MesureResponse(Mapper.toDto(m), urgence, Mapper.interpretation(m.getStatut()));
    }

    @Transactional(readOnly = true)
    public PageResponse<MesureDto> liste(Long patientId, Pageable pageable) {
        return PageResponse.of(mesures.findByPatientIdAndSupprimeFalseOrderByMesureLeDesc(patientId, pageable)
                .map(m -> Mapper.toDto(m)));
    }

    @Transactional
    public void supprimer(PatientProfile p, Long id) {
        MesureGlycemie m = mesures.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Mesure introuvable"));
        if (!m.getPatient().getId().equals(p.getId())) throw new ApiException(HttpStatus.FORBIDDEN, "Accès refusé");
        m.setSupprime(true);   // suppression logique : le client la retire à la prochaine synchronisation
        mesures.save(m);
    }

    @Transactional(readOnly = true)
    public GlycemieStats stats(PatientProfile p, int jours) {
        Instant depuis = Instant.now().minus(jours, ChronoUnit.DAYS);
        List<MesureGlycemie> l = mesures.findByPatientIdAndSupprimeFalseAndMesureLeAfterOrderByMesureLeAsc(p.getId(), depuis);
        int n = l.size();
        Double moyenne = n == 0 ? null : Math.round(l.stream().mapToDouble(m -> m.getValeur()).average().orElse(0) * 100.0) / 100.0;
        long dansCible = l.stream().filter(m -> m.getStatut() == StatutGlycemie.NORMAL).count();
        int hypo = (int) l.stream().filter(m -> m.getStatut() == StatutGlycemie.HYPO || m.getStatut() == StatutGlycemie.HYPO_SEVERE).count();
        double pct = n == 0 ? 0 : Math.round(dansCible * 1000.0 / n) / 10.0;
        double parJour = Math.round(n * 10.0 / Math.max(jours, 1)) / 10.0;
        return new GlycemieStats(jours, moyenne, n, pct, hypo, parJour, l.stream().map(m -> Mapper.toDto(m)).toList());
    }
}

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
public class DashboardService {
    private final PatientRepository patients;
    private final AlerteRepository alertes;
    private final MesureRepository mesures;
    private final RendezVousRepository rdvs;
    private final EvaluationRisqueRepository evaluations;

    public static TirDto tir(List<Object[]> lignes) {
        long normal = 0, bas = 0, eleve = 0, critique = 0;
        for (Object[] l : lignes) {
            StatutGlycemie s = (StatutGlycemie) l[0];
            long n = ((Number) l[1]).longValue();
            switch (s) {
                case NORMAL -> normal += n;
                case HYPO -> bas += n;
                case LEGEREMENT_ELEVE, ELEVE -> eleve += n;
                case HYPO_SEVERE, CRITIQUE -> critique += n;
            }
        }
        long total = normal + bas + eleve + critique;
        double pct = total == 0 ? 0 : Math.round(normal * 1000.0 / total) / 10.0;
        return new TirDto(total, normal, bas, eleve, critique, pct);
    }

    @Transactional(readOnly = true)
    public DashboardMedecin dashboard(User staff) {
        Long uid = staff.getId();
        LocalDate aujourdhui = LocalDate.now();
        List<RendezVous> jour = rdvs.findByMedecinIdAndDateHeureBetweenOrderByDateHeureAsc(uid,
                aujourdhui.atStartOfDay(), aujourdhui.plusDays(1).atStartOfDay());
        long presentiel = jour.stream().filter(r -> r.getMode() == ModeRdv.PRESENTIEL && r.getStatut() != StatutRdv.ANNULE).count();
        long tele = jour.stream().filter(r -> r.getMode() == ModeRdv.TELECONSULTATION && r.getStatut() != StatutRdv.ANNULE).count();
        Instant depuis = Instant.now().minus(30, ChronoUnit.DAYS);
        return new DashboardMedecin(
                patients.compterSuivis(uid),
                alertes.compterOuvertes(uid, StatutAlerte.TRAITEE),
                alertes.compterOuvertesParGravite(uid, StatutAlerte.TRAITEE, GraviteAlerte.URGENCE_VITALE),
                presentiel + tele, presentiel, tele,
                evaluations.compterARisque(uid, List.of(NiveauRisque.ELEVE, NiveauRisque.TRES_ELEVE), TypeDiabete.AUCUN),
                tir(mesures.statutsPourPersonnel(uid, depuis)));
    }
}

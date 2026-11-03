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
public class PlanificateurService {
    private final PatientRepository patients;
    private final TraitementRepository traitements;
    private final MesureRepository mesures;
    private final AlerteService alertes;

    /** Tous les jours à 07h00 (UTC = heure du Sénégal) : ruptures de transmission, de traitement et dérives. */
    @org.springframework.scheduling.annotation.Scheduled(cron = "0 0 7 * * *")
    public void verifierSuivi() {
        Instant maintenant = Instant.now();

        for (PatientProfile p : patients.sansMesureDepuis(TypeDiabete.AUCUN, maintenant.minus(7, ChronoUnit.DAYS))) {
            alertes.creer(p, TypeAlerte.RUPTURE_TRANSMISSION, GraviteAlerte.MODEREE,
                    "Aucune mesure reçue depuis plus de 7 jours", null, 72);
        }
        for (Traitement t : traitements.findByActifTrueAndStockRestantLessThanEqual(5)) {
            alertes.creer(t.getPatient(), TypeAlerte.RUPTURE_TRAITEMENT, GraviteAlerte.ELEVEE,
                    "Stock de " + t.getMedicament() + " presque épuisé (" + t.getStockRestant() + " prises)", null, 72);
        }
        for (Object[] l : mesures.derives(maintenant.minus(14, ChronoUnit.DAYS), 5L, 1.60)) {
            Long patientId = (Long) l[0];
            double moyenne = ((Number) l[1]).doubleValue();
            patients.findById(patientId).ifPresent(p -> alertes.creer(p, TypeAlerte.DERIVE_GLYCEMIQUE, GraviteAlerte.MODEREE,
                    "Glycémie moyenne élevée sur 14 jours : " + String.format(Locale.ROOT, "%.2f", moyenne) + " g/L",
                    moyenne, 72));
        }
        log.info("Vérification quotidienne du suivi terminée");
    }
}

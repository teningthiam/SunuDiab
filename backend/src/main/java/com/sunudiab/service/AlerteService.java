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
public class AlerteService {
    private final AlerteRepository alertes;
    private final AccessService access;

    @Transactional
    public void depuisMesure(PatientProfile p, MesureGlycemie m) {
        String v = String.format(Locale.ROOT, "%.2f", m.getValeur());
        if (m.getStatut() == StatutGlycemie.HYPO_SEVERE) {
            creer(p, TypeAlerte.HYPO_SEVERE, GraviteAlerte.URGENCE_VITALE,
                    "Hypoglycémie sévère : " + v + " g/L", m.getValeur(), 2);
        } else if (m.getStatut() == StatutGlycemie.CRITIQUE) {
            creer(p, TypeAlerte.HYPER_CRITIQUE, GraviteAlerte.URGENCE_VITALE,
                    "Hyperglycémie critique : " + v + " g/L", m.getValeur(), 2);
        }
    }

    @Transactional
    public void symptomes(PatientProfile p, String texte) {
        String extrait = texte.length() > 200 ? texte.substring(0, 200) + "…" : texte;
        creer(p, TypeAlerte.SYMPTOMES_SIGNALES, GraviteAlerte.URGENCE_VITALE,
                "Symptômes signalés à l'assistant : " + extrait, null, 1);
    }

    /** Crée une alerte sauf si une alerte non traitée du même type existe déjà dans la fenêtre indiquée. */
    @Transactional
    public void creer(PatientProfile p, TypeAlerte type, GraviteAlerte gravite, String message, Double valeur,
                      int fenetreHeures) {
        Instant depuis = Instant.now().minus(fenetreHeures, ChronoUnit.HOURS);
        if (alertes.existsByPatientIdAndTypeAndStatutNotAndCreatedAtAfter(p.getId(), type, StatutAlerte.TRAITEE, depuis)) {
            return;
        }
        Alerte a = new Alerte();
        a.setPatient(p);
        a.setType(type);
        a.setGravite(gravite);
        a.setMessage(message);
        a.setValeur(valeur);
        alertes.save(a);
    }

    @Transactional(readOnly = true)
    public PageResponse<AlerteDto> liste(User staff, StatutAlerte statut, Pageable pageable) {
        return PageResponse.of(alertes.pourPersonnel(staff.getId(), statut, pageable).map(a -> Mapper.toDto(a)));
    }

    @Transactional
    public AlerteDto changerStatut(User staff, Long id, StatutAlerte statut) {
        Alerte a = alertes.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Alerte introuvable"));
        access.loadForStaff(staff, a.getPatient().getId(), "ALERTE_" + statut);
        a.setStatut(statut);
        if (statut == StatutAlerte.TRAITEE) {
            a.setTraitePar(staff);
            a.setTraiteLe(Instant.now());
        }
        return Mapper.toDto(alertes.save(a));
    }
}

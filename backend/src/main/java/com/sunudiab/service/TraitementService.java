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
public class TraitementService {
    private final TraitementRepository traitements;
    private final PriseRepository prises;

    @Transactional(readOnly = true)
    public List<TraitementDto> liste(Long patientId) {
        return traitements.findByPatientIdOrderByCreatedAtDesc(patientId).stream().map(t -> Mapper.toDto(t)).toList();
    }

    @Transactional
    public TraitementDto creer(User medecin, PatientProfile p, TraitementRequest r) {
        Traitement t = new Traitement();
        t.setPatient(p);
        t.setMedicament(r.medicament());
        t.setDosage(r.dosage());
        t.setPosologie(r.posologie());
        t.setHoraires(r.horaires());
        t.setDateDebut(r.dateDebut() != null ? r.dateDebut() : LocalDate.now());
        t.setDateFin(r.dateFin());
        t.setStockRestant(r.stockRestant());
        t.setPrescripteur(medecin);
        return Mapper.toDto(traitements.save(t));
    }

    @Transactional
    public TraitementDto arreter(Long patientId, Long traitementId) {
        Traitement t = traitements.findById(traitementId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Traitement introuvable"));
        if (!t.getPatient().getId().equals(patientId)) throw new ApiException(HttpStatus.NOT_FOUND, "Traitement introuvable");
        t.setActif(false);
        if (t.getDateFin() == null) t.setDateFin(LocalDate.now());
        return Mapper.toDto(traitements.save(t));
    }

    /** Enregistre une prise (idempotent sur clientUuid) et décrémente le stock restant. */
    @Transactional
    public PriseMedicament enregistrerPrise(PatientProfile p, String clientUuid, Long traitementId, Instant prisLe,
                                            StatutPrise statut) {
        if (clientUuid != null) {
            Optional<PriseMedicament> existante = prises.findByClientUuid(clientUuid);
            if (existante.isPresent()) return existante.get();
        }
        Traitement t = traitements.findById(traitementId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Traitement introuvable"));
        if (!t.getPatient().getId().equals(p.getId())) throw new ApiException(HttpStatus.FORBIDDEN, "Accès refusé");
        PriseMedicament pm = new PriseMedicament();
        pm.setClientUuid(clientUuid != null ? clientUuid : UUID.randomUUID().toString());
        pm.setTraitement(t);
        pm.setPrisLe(prisLe != null ? prisLe : Instant.now());
        pm.setStatut(statut != null ? statut : StatutPrise.PRIS);
        if (pm.getStatut() == StatutPrise.PRIS && t.getStockRestant() != null && t.getStockRestant() > 0) {
            t.setStockRestant(t.getStockRestant() - 1);
            traitements.save(t);
        }
        return prises.save(pm);
    }

    @Transactional(readOnly = true)
    public List<PriseDto> prisesRecentes(Long patientId) {
        return prises.findTop50ByTraitementPatientIdOrderByPrisLeDesc(patientId).stream().map(x -> Mapper.toDto(x)).toList();
    }
}

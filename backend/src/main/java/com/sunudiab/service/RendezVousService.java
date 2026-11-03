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
public class RendezVousService {
    private final RendezVousRepository rdvs;
    private final UserRepository users;

    @Transactional
    public RdvDto patientCreer(PatientProfile p, RdvRequest r) {
        Long medecinId = r.medecinId() != null ? r.medecinId()
                : (p.getMedecinReferent() != null ? p.getMedecinReferent().getId() : null);
        if (medecinId == null) throw new ApiException(HttpStatus.BAD_REQUEST, "Choisis d'abord un médecin");
        User med = users.findById(medecinId).filter(u -> u.getRole() == Role.MEDECIN && u.isActif())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Médecin introuvable"));
        return creer(p, med, r, StatutRdv.EN_ATTENTE);
    }

    @Transactional
    public RdvDto staffCreer(User medecin, PatientProfile p, RdvRequest r) {
        return creer(p, medecin, r, StatutRdv.CONFIRME);
    }

    private RdvDto creer(PatientProfile p, User med, RdvRequest r, StatutRdv statut) {
        if (r.dateHeure().isBefore(LocalDateTime.now())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "La date du rendez-vous doit être dans le futur");
        }
        if (rdvs.existsByMedecinIdAndDateHeureAndStatutNot(med.getId(), r.dateHeure(), StatutRdv.ANNULE)) {
            throw new ApiException(HttpStatus.CONFLICT, "Ce créneau est déjà pris");
        }
        RendezVous rdv = new RendezVous();
        rdv.setPatient(p);
        rdv.setMedecin(med);
        rdv.setDateHeure(r.dateHeure());
        rdv.setMode(r.mode());
        rdv.setMotif(r.motif());
        rdv.setStatut(statut);
        rdv.setLieu(r.mode() == ModeRdv.TELECONSULTATION ? "Téléconsultation" : med.getStructure());
        return Mapper.toDto(rdvs.save(rdv));
    }

    @Transactional(readOnly = true)
    public List<RdvDto> patientListe(Long patientId) {
        return rdvs.findByPatientIdOrderByDateHeureDesc(patientId).stream().map(r -> Mapper.toDto(r)).toList();
    }

    @Transactional
    public RdvDto patientAnnuler(PatientProfile p, Long id) {
        RendezVous r = rdvs.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Rendez-vous introuvable"));
        if (!r.getPatient().getId().equals(p.getId())) throw new ApiException(HttpStatus.FORBIDDEN, "Accès refusé");
        r.setStatut(StatutRdv.ANNULE);
        return Mapper.toDto(rdvs.save(r));
    }

    @Transactional(readOnly = true)
    public List<RdvDto> staffJour(User staff, LocalDate jour) {
        return rdvs.findByMedecinIdAndDateHeureBetweenOrderByDateHeureAsc(staff.getId(), jour.atStartOfDay(),
                jour.plusDays(1).atStartOfDay()).stream().map(r -> Mapper.toDto(r)).toList();
    }

    @Transactional
    public RdvDto staffStatut(User medecin, Long id, StatutRdv statut) {
        RendezVous r = rdvs.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Rendez-vous introuvable"));
        if (!r.getMedecin().getId().equals(medecin.getId())) throw new ApiException(HttpStatus.FORBIDDEN, "Accès refusé");
        r.setStatut(statut);
        return Mapper.toDto(rdvs.save(r));
    }
}

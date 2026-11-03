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
public class AccessService {
    private final PatientRepository patients;
    private final AuditService audit;

    /** Profil du patient connecté. */
    public PatientProfile patientOf(User u) {
        return patients.findByUserId(u.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Profil patient introuvable"));
    }

    /** Dossier d'un patient pour un médecin / infirmier relais : seulement s'il est référent ET que le patient partage son dossier. */
    public PatientProfile loadForStaff(User staff, Long patientId, String action) {
        PatientProfile p = patients.findById(patientId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Patient introuvable"));
        boolean referent = p.getMedecinReferent() != null && p.getMedecinReferent().getId().equals(staff.getId());
        boolean relais = p.getInfirmierRelais() != null && p.getInfirmierRelais().getId().equals(staff.getId());
        if (!referent && !relais) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Ce patient n'est pas dans votre file active");
        }
        if (!p.isPartageDossier()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Le patient n'a pas autorisé le partage de son dossier");
        }
        audit.log(staff, action, p.getId(), null);
        return p;
    }

    public void exigerMedecin(User staff) {
        if (staff.getRole() != Role.MEDECIN) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Action réservée aux médecins");
        }
    }
}

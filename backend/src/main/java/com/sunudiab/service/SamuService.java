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
public class SamuService {
    private final InterventionRepository interventions;

    /**
     * Enregistre un ordre d'intervention dans SunuDiab (traçabilité). Aucune transmission réelle au SAMU 1515 :
     * cette intégration (API ou téléphonie) reste à convenir avec les autorités sanitaires.
     */
    @Transactional
    public InterventionDto declencher(User medecin, PatientProfile p, SamuRequest r) {
        InterventionUrgence i = new InterventionUrgence();
        i.setPatient(p);
        i.setDeclenchePar(medecin);
        i.setLocalisation(r.localisation());
        i.setRepere(r.repere());
        i.setHopitalReception(r.hopitalReception());
        i.setOrdre("SAMU-" + Year.now().getValue() + "-" + String.format("%04d", interventions.count() + 1));
        return Mapper.toDto(interventions.save(i));
    }

    @Transactional(readOnly = true)
    public List<InterventionDto> mesInterventions(User medecin) {
        return interventions.findByDeclencheParIdOrderByCreatedAtDesc(medecin.getId()).stream().map(i -> Mapper.toDto(i)).toList();
    }
}

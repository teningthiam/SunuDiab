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
public class OrdonnanceService {
    private final OrdonnanceRepository ordonnances;

    @Transactional
    public OrdonnanceDto creer(User medecin, PatientProfile p, OrdonnanceRequest r) {
        Ordonnance o = new Ordonnance();
        o.setPatient(p);
        o.setMedecin(medecin);
        o.setLignes(r.lignes());
        o.setPharmacie(r.pharmacie());
        o.setDureeMois(r.dureeMois());
        o.setDateEmission(LocalDate.now());
        o.setDateExpiration(LocalDate.now().plusMonths(r.dureeMois()));
        long n = ordonnances.count() + 1;
        String numero;
        do {
            numero = "ORD-" + Year.now().getValue() + "-SN-" + String.format("%04d", n++);
        } while (ordonnances.existsByNumero(numero));
        o.setNumero(numero);
        return Mapper.toDto(ordonnances.save(o));
    }

    @Transactional(readOnly = true)
    public List<OrdonnanceDto> liste(Long patientId) {
        return ordonnances.findByPatientIdOrderByDateEmissionDesc(patientId).stream().map(o -> Mapper.toDto(o)).toList();
    }
}

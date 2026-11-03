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
public class NoteService {
    private final NoteRepository notes;

    @Transactional
    public NoteDto ajouter(User auteur, PatientProfile p, NoteRequest r) {
        NoteMedicale n = new NoteMedicale();
        n.setPatient(p);
        n.setAuteur(auteur);
        n.setContenu(r.contenu());
        n.setVisibleRelais(auteur.getRole() == Role.INFIRMIER_RELAIS || r.visibleRelais());
        return Mapper.toDto(notes.save(n));
    }

    /** Le relais ne voit que les notes qui lui sont destinées ou qu'il a écrites. */
    @Transactional(readOnly = true)
    public List<NoteDto> liste(User staff, Long patientId) {
        return notes.findByPatientIdOrderByCreatedAtDesc(patientId).stream()
                .filter(n -> staff.getRole() == Role.MEDECIN || n.isVisibleRelais() || n.getAuteur().getId().equals(staff.getId()))
                .map(n -> Mapper.toDto(n)).toList();
    }
}

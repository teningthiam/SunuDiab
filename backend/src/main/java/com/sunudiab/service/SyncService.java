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
public class SyncService {
    private final GlycemieService glycemie;
    private final TraitementService traitementService;
    private final PatientService patientService;
    private final MesureRepository mesures;
    private final TraitementRepository traitements;
    private final RendezVousRepository rdvs;
    private final OrdonnanceRepository ordonnances;
    private final ConseilRepository conseils;

    /** Envoi des données saisies hors ligne. Idempotent : le même clientUuid ne crée jamais de doublon. */
    public SyncPushResponse push(PatientProfile p, SyncPushRequest req) {
        List<SyncItemResult> res = new ArrayList<>();
        if (req.mesures() != null) {
            for (SyncMesure s : req.mesures()) {
                try {
                    if (s.valeur() == null || s.moment() == null || s.valeur() < 0.2 || s.valeur() > 6.0) {
                        res.add(new SyncItemResult(s.clientUuid(), "ERREUR", null, "Valeur ou moment invalide"));
                        continue;
                    }
                    MesureGlycemie m = glycemie.enregistrerOuMaj(p, s.clientUuid(), s.valeur(), s.moment(),
                            s.methode(), s.contexte(), s.note(), s.mesureLe(), s.supprime());
                    res.add(new SyncItemResult(s.clientUuid(), "OK", m.getId(), null));
                } catch (Exception e) {
                    res.add(new SyncItemResult(s.clientUuid(), "ERREUR", null, e.getMessage()));
                }
            }
        }
        if (req.prises() != null) {
            for (SyncPrise s : req.prises()) {
                try {
                    PriseMedicament pm = traitementService.enregistrerPrise(p, s.clientUuid(), s.traitementId(),
                            s.prisLe(), s.statut());
                    res.add(new SyncItemResult(s.clientUuid(), "OK", pm.getId(), null));
                } catch (Exception e) {
                    res.add(new SyncItemResult(s.clientUuid(), "ERREUR", null, e.getMessage()));
                }
            }
        }
        return new SyncPushResponse(res, Instant.now());
    }

    /** Récupération des changements depuis la dernière synchronisation (since = serverTime précédent). */
    @Transactional(readOnly = true)
    public SyncPullResponse pull(PatientProfile p, Instant since) {
        Instant depuis = since != null ? since : Instant.EPOCH;
        Instant maintenant = Instant.now();
        return new SyncPullResponse(maintenant, patientService.detail(p),
                mesures.findByPatientIdAndUpdatedAtAfter(p.getId(), depuis).stream().map(m -> Mapper.toDto(m)).toList(),
                traitements.findByPatientIdAndUpdatedAtAfter(p.getId(), depuis).stream().map(t -> Mapper.toDto(t)).toList(),
                rdvs.findByPatientIdAndUpdatedAtAfter(p.getId(), depuis).stream().map(r -> Mapper.toDto(r)).toList(),
                ordonnances.findByPatientIdAndUpdatedAtAfter(p.getId(), depuis).stream().map(o -> Mapper.toDto(o)).toList(),
                conseils.findByUpdatedAtAfter(depuis).stream().map(c -> Mapper.toDto(c)).toList());
    }
}

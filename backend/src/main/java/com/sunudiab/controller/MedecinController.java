package com.sunudiab.controller;

import com.sunudiab.dto.Dtos.*;
import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import com.sunudiab.service.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.*;
import java.util.*;

@RestController
@RequestMapping("/api/medecin")
@PreAuthorize("hasAnyRole('MEDECIN','INFIRMIER_RELAIS')")
@RequiredArgsConstructor
public class MedecinController {
    private final AccessService access;
    private final DashboardService dashboard;
    private final PatientService patientService;
    private final GlycemieService glycemie;
    private final RisqueService risque;
    private final NoteService notes;
    private final TraitementService traitements;
    private final OrdonnanceService ordonnances;
    private final RendezVousService rdvs;
    private final AlerteService alertes;
    private final ChatService chat;
    private final SamuService samu;

    private static Pageable pg(int page, int size) {
        return PageRequest.of(page, Math.min(Math.max(size, 1), 100));
    }

    @GetMapping("/dashboard")
    public DashboardMedecin dashboard(@AuthenticationPrincipal User u) {
        return dashboard.dashboard(u);
    }

    // ----- Patients -----
    @GetMapping("/patients")
    public PageResponse<PatientResume> patients(@AuthenticationPrincipal User u,
                                                @RequestParam(defaultValue = "") String q,
                                                @RequestParam(required = false) TypeDiabete type,
                                                @RequestParam(defaultValue = "0") int page,
                                                @RequestParam(defaultValue = "20") int size) {
        return patientService.liste(u, q, type, page, size);
    }

    @GetMapping("/patients/{id}")
    public PatientDetail patient(@AuthenticationPrincipal User u, @PathVariable Long id) {
        return patientService.detail(access.loadForStaff(u, id, "CONSULTATION_DOSSIER"));
    }

    @PutMapping("/patients/{id}/diagnostic")
    @PreAuthorize("hasRole('MEDECIN')")
    public PatientDetail diagnostic(@AuthenticationPrincipal User u, @PathVariable Long id, @RequestParam TypeDiabete type) {
        return patientService.definirDiagnostic(access.loadForStaff(u, id, "DIAGNOSTIC_" + type), type);
    }

    @GetMapping("/patients/{id}/mesures")
    public PageResponse<MesureDto> mesures(@AuthenticationPrincipal User u, @PathVariable Long id,
                                           @RequestParam(defaultValue = "0") int page,
                                           @RequestParam(defaultValue = "30") int size) {
        access.loadForStaff(u, id, "CONSULTATION_GLYCEMIES");
        return glycemie.liste(id, pg(page, size));
    }

    @GetMapping("/patients/{id}/mesures/stats")
    public GlycemieStats stats(@AuthenticationPrincipal User u, @PathVariable Long id,
                               @RequestParam(defaultValue = "30") int jours) {
        return glycemie.stats(access.loadForStaff(u, id, "CONSULTATION_STATS"), Math.min(Math.max(jours, 1), 365));
    }

    @GetMapping("/patients/{id}/risque")
    public List<RisqueResult> risque(@AuthenticationPrincipal User u, @PathVariable Long id) {
        access.loadForStaff(u, id, "CONSULTATION_RISQUE");
        return risque.historique(id);
    }

    @PutMapping("/patients/{id}/risque/{evaluationId}/valider")
    @PreAuthorize("hasRole('MEDECIN')")
    public RisqueResult validerRisque(@AuthenticationPrincipal User u, @PathVariable Long id, @PathVariable Long evaluationId) {
        access.loadForStaff(u, id, "VALIDATION_RISQUE");
        return risque.valider(u, evaluationId, id);
    }

    // ----- Notes -----
    @GetMapping("/patients/{id}/notes")
    public List<NoteDto> notes(@AuthenticationPrincipal User u, @PathVariable Long id) {
        access.loadForStaff(u, id, "CONSULTATION_NOTES");
        return notes.liste(u, id);
    }

    @PostMapping("/patients/{id}/notes")
    @ResponseStatus(HttpStatus.CREATED)
    public NoteDto ajouterNote(@AuthenticationPrincipal User u, @PathVariable Long id, @Valid @RequestBody NoteRequest r) {
        return notes.ajouter(u, access.loadForStaff(u, id, "AJOUT_NOTE"), r);
    }

    // ----- Traitements / ordonnances / bilans -----
    @GetMapping("/patients/{id}/traitements")
    public List<TraitementDto> traitements(@AuthenticationPrincipal User u, @PathVariable Long id) {
        access.loadForStaff(u, id, "CONSULTATION_TRAITEMENTS");
        return traitements.liste(id);
    }

    @PostMapping("/patients/{id}/traitements")
    @PreAuthorize("hasRole('MEDECIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public TraitementDto prescrire(@AuthenticationPrincipal User u, @PathVariable Long id, @Valid @RequestBody TraitementRequest r) {
        return traitements.creer(u, access.loadForStaff(u, id, "PRESCRIPTION_TRAITEMENT"), r);
    }

    @PutMapping("/patients/{id}/traitements/{traitementId}/arreter")
    @PreAuthorize("hasRole('MEDECIN')")
    public TraitementDto arreter(@AuthenticationPrincipal User u, @PathVariable Long id, @PathVariable Long traitementId) {
        access.loadForStaff(u, id, "ARRET_TRAITEMENT");
        return traitements.arreter(id, traitementId);
    }

    @GetMapping("/patients/{id}/ordonnances")
    public List<OrdonnanceDto> ordonnances(@AuthenticationPrincipal User u, @PathVariable Long id) {
        access.loadForStaff(u, id, "CONSULTATION_ORDONNANCES");
        return ordonnances.liste(id);
    }

    @PostMapping("/patients/{id}/ordonnances")
    @PreAuthorize("hasRole('MEDECIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public OrdonnanceDto ordonner(@AuthenticationPrincipal User u, @PathVariable Long id, @Valid @RequestBody OrdonnanceRequest r) {
        return ordonnances.creer(u, access.loadForStaff(u, id, "EMISSION_ORDONNANCE"), r);
    }

    @GetMapping("/patients/{id}/bilans")
    public List<BilanDto> bilans(@AuthenticationPrincipal User u, @PathVariable Long id) {
        access.loadForStaff(u, id, "CONSULTATION_BILANS");
        return patientService.bilans(id);
    }

    @PostMapping("/patients/{id}/bilans")
    @PreAuthorize("hasRole('MEDECIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public BilanDto ajouterBilan(@AuthenticationPrincipal User u, @PathVariable Long id, @Valid @RequestBody BilanRequest r) {
        return patientService.ajouterBilan(access.loadForStaff(u, id, "AJOUT_BILAN"), r);
    }

    @GetMapping("/patients/{id}/chat")
    public List<ChatMessageDto> chat(@AuthenticationPrincipal User u, @PathVariable Long id) {
        access.loadForStaff(u, id, "CONSULTATION_ECHANGES_IA");
        return chat.historique(id);
    }

    // ----- Alertes -----
    @GetMapping("/alertes")
    public PageResponse<AlerteDto> alertes(@AuthenticationPrincipal User u,
                                           @RequestParam(required = false) StatutAlerte statut,
                                           @RequestParam(defaultValue = "0") int page,
                                           @RequestParam(defaultValue = "20") int size) {
        return alertes.liste(u, statut, pg(page, size));
    }

    @PutMapping("/alertes/{id}")
    public AlerteDto majAlerte(@AuthenticationPrincipal User u, @PathVariable Long id, @Valid @RequestBody AlerteUpdateRequest r) {
        return alertes.changerStatut(u, id, r.statut());
    }

    // ----- Rendez-vous -----
    @GetMapping("/rendez-vous")
    public List<RdvDto> rendezVous(@AuthenticationPrincipal User u,
                                   @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return rdvs.staffJour(u, date != null ? date : LocalDate.now());
    }

    @PostMapping("/patients/{id}/rendez-vous")
    @PreAuthorize("hasRole('MEDECIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public RdvDto planifier(@AuthenticationPrincipal User u, @PathVariable Long id, @Valid @RequestBody RdvRequest r) {
        return rdvs.staffCreer(u, access.loadForStaff(u, id, "PLANIFICATION_RDV"), r);
    }

    @PutMapping("/rendez-vous/{id}/statut")
    @PreAuthorize("hasRole('MEDECIN')")
    public RdvDto statutRdv(@AuthenticationPrincipal User u, @PathVariable Long id, @Valid @RequestBody RdvStatutRequest r) {
        return rdvs.staffStatut(u, id, r.statut());
    }

    // ----- Urgence -----
    @PostMapping("/patients/{id}/samu")
    @PreAuthorize("hasRole('MEDECIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public InterventionDto declencherSamu(@AuthenticationPrincipal User u, @PathVariable Long id, @Valid @RequestBody SamuRequest r) {
        return samu.declencher(u, access.loadForStaff(u, id, "ORDRE_INTERVENTION_SAMU"), r);
    }

    @GetMapping("/samu")
    public List<InterventionDto> interventions(@AuthenticationPrincipal User u) {
        return samu.mesInterventions(u);
    }
}

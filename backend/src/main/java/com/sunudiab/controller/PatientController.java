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
@RequestMapping("/api/patient")
@PreAuthorize("hasRole('PATIENT')")
@RequiredArgsConstructor
public class PatientController {
    private final AccessService access;
    private final PatientService patientService;
    private final GlycemieService glycemie;
    private final RisqueService risque;
    private final TraitementService traitements;
    private final OrdonnanceService ordonnances;
    private final RendezVousService rdvs;
    private final ChatService chat;

    // ----- Profil -----
    @GetMapping("/profil")
    public PatientDetail profil(@AuthenticationPrincipal User u) {
        return patientService.detail(access.patientOf(u));
    }

    @PutMapping("/profil")
    public PatientDetail majProfil(@AuthenticationPrincipal User u, @RequestBody ProfilUpdateRequest r) {
        return patientService.majProfil(access.patientOf(u), r);
    }

    @PutMapping("/medecin-referent")
    public PatientDetail choisirMedecin(@AuthenticationPrincipal User u, @Valid @RequestBody MedecinChoixRequest r) {
        return patientService.choisirMedecin(access.patientOf(u), r.medecinId());
    }

    @GetMapping("/contacts")
    public List<ContactDto> contacts(@AuthenticationPrincipal User u) {
        return patientService.listerContacts(access.patientOf(u));
    }

    @PostMapping("/contacts")
    @ResponseStatus(HttpStatus.CREATED)
    public ContactDto ajouterContact(@AuthenticationPrincipal User u, @Valid @RequestBody ContactRequest r) {
        return patientService.ajouterContact(access.patientOf(u), r);
    }

    @DeleteMapping("/contacts/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void supprimerContact(@AuthenticationPrincipal User u, @PathVariable Long id) {
        patientService.supprimerContact(access.patientOf(u), id);
    }

    // ----- Glycémie -----
    @GetMapping("/mesures")
    public PageResponse<MesureDto> mesures(@AuthenticationPrincipal User u,
                                           @RequestParam(defaultValue = "0") int page,
                                           @RequestParam(defaultValue = "20") int size) {
        PatientProfile p = access.patientOf(u);
        return glycemie.liste(p.getId(), PageRequest.of(page, Math.min(Math.max(size, 1), 100)));
    }

    @PostMapping("/mesures")
    @ResponseStatus(HttpStatus.CREATED)
    public MesureResponse ajouterMesure(@AuthenticationPrincipal User u, @Valid @RequestBody MesureRequest r) {
        return glycemie.enregistrer(access.patientOf(u), r);
    }

    @DeleteMapping("/mesures/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void supprimerMesure(@AuthenticationPrincipal User u, @PathVariable Long id) {
        glycemie.supprimer(access.patientOf(u), id);
    }

    @GetMapping("/mesures/stats")
    public GlycemieStats stats(@AuthenticationPrincipal User u, @RequestParam(defaultValue = "7") int jours) {
        return glycemie.stats(access.patientOf(u), Math.min(Math.max(jours, 1), 365));
    }

    // ----- Test de risque -----
    @PostMapping("/risque")
    @ResponseStatus(HttpStatus.CREATED)
    public RisqueResult evaluerRisque(@AuthenticationPrincipal User u, @Valid @RequestBody RisqueRequest r) {
        return risque.evaluer(access.patientOf(u), r);
    }

    @GetMapping("/risque")
    public List<RisqueResult> historiqueRisque(@AuthenticationPrincipal User u) {
        return risque.historique(access.patientOf(u).getId());
    }

    // ----- Traitements, ordonnances, bilans -----
    @GetMapping("/traitements")
    public List<TraitementDto> traitements(@AuthenticationPrincipal User u) {
        return traitements.liste(access.patientOf(u).getId());
    }

    @PostMapping("/prises")
    @ResponseStatus(HttpStatus.CREATED)
    public PriseDto prise(@AuthenticationPrincipal User u, @Valid @RequestBody PriseRequest r) {
        PriseMedicament pm = traitements.enregistrerPrise(access.patientOf(u), r.clientUuid(), r.traitementId(),
                r.prisLe(), r.statut());
        return new PriseDto(pm.getId(), pm.getTraitement().getId(), pm.getTraitement().getMedicament(),
                pm.getPrisLe(), pm.getStatut());
    }

    @GetMapping("/prises")
    public List<PriseDto> prises(@AuthenticationPrincipal User u) {
        return traitements.prisesRecentes(access.patientOf(u).getId());
    }

    @GetMapping("/ordonnances")
    public List<OrdonnanceDto> ordonnances(@AuthenticationPrincipal User u) {
        return ordonnances.liste(access.patientOf(u).getId());
    }

    @GetMapping("/bilans")
    public List<BilanDto> bilans(@AuthenticationPrincipal User u) {
        return patientService.bilans(access.patientOf(u).getId());
    }

    // ----- Rendez-vous -----
    @GetMapping("/rendez-vous")
    public List<RdvDto> rendezVous(@AuthenticationPrincipal User u) {
        return rdvs.patientListe(access.patientOf(u).getId());
    }

    @PostMapping("/rendez-vous")
    @ResponseStatus(HttpStatus.CREATED)
    public RdvDto prendreRdv(@AuthenticationPrincipal User u, @Valid @RequestBody RdvRequest r) {
        return rdvs.patientCreer(access.patientOf(u), r);
    }

    @PutMapping("/rendez-vous/{id}/annuler")
    public RdvDto annulerRdv(@AuthenticationPrincipal User u, @PathVariable Long id) {
        return rdvs.patientAnnuler(access.patientOf(u), id);
    }

    // ----- Assistant IA -----
    @GetMapping("/chat")
    public List<ChatMessageDto> historiqueChat(@AuthenticationPrincipal User u) {
        return chat.historique(access.patientOf(u).getId());
    }

    @PostMapping("/chat")
    public ChatReply discuter(@AuthenticationPrincipal User u, @Valid @RequestBody ChatRequest r) {
        return chat.repondre(access.patientOf(u), r.message());
    }
}

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
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {
    private final AdminService admin;
    private final AuditService audit;

    /** Statistiques agrégées et anonymes : administrateurs et superviseurs nationaux. */
    @GetMapping("/observatoire")
    @PreAuthorize("hasAnyRole('ADMIN','SUPERVISEUR')")
    public ObservatoireDto observatoire() {
        return admin.observatoire();
    }

    @PostMapping("/utilisateurs")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public UserInfo creerUtilisateur(@Valid @RequestBody UserCreateRequest r) {
        return admin.creerUtilisateur(r);
    }

    @GetMapping("/utilisateurs")
    @PreAuthorize("hasRole('ADMIN')")
    public PageResponse<UserInfo> utilisateurs(@RequestParam(required = false) Role role,
                                               @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "20") int size) {
        return admin.utilisateurs(role, page, size);
    }

    @GetMapping("/patients-sans-medecin")
    @PreAuthorize("hasRole('ADMIN')")
    public PageResponse<PatientResume> patientsSansMedecin(@RequestParam(defaultValue = "0") int page,
                                                           @RequestParam(defaultValue = "20") int size) {
        return admin.patientsSansMedecin(page, size);
    }

    @PutMapping("/patients/{id}/assignation")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void assigner(@PathVariable Long id, @RequestBody AssignationRequest r) {
        admin.assigner(id, r);
    }

    @GetMapping("/audit")
    @PreAuthorize("hasRole('ADMIN')")
    public PageResponse<AuditDto> audit(@RequestParam(defaultValue = "0") int page,
                                        @RequestParam(defaultValue = "50") int size) {
        return audit.liste(PageRequest.of(page, Math.min(Math.max(size, 1), 200)));
    }

    @PostMapping("/conseils")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public ConseilDto creerConseil(@Valid @RequestBody ConseilRequest r) {
        return admin.creerConseil(r);
    }
}

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
@RequestMapping("/api/sync")
@PreAuthorize("hasRole('PATIENT')")
@RequiredArgsConstructor
public class SyncController {
    private final AccessService access;
    private final SyncService sync;

    /** Le mobile envoie ici tout ce qui a été saisi hors ligne. */
    @PostMapping
    public SyncPushResponse push(@AuthenticationPrincipal User u, @RequestBody SyncPushRequest r) {
        return sync.push(access.patientOf(u), r);
    }

    /** Le mobile récupère les changements depuis le dernier serverTime reçu (date ISO-8601, ex. 2026-11-01T21:57:12Z). */
    @GetMapping
    public SyncPullResponse pull(@AuthenticationPrincipal User u,
                                 @RequestParam(required = false) String since) {
        Instant depuis = null;
        if (since != null && !since.isBlank()) {
            try {
                depuis = Instant.parse(since.trim());
            } catch (java.time.format.DateTimeParseException e) {
                throw new com.sunudiab.exception.ApiException(HttpStatus.BAD_REQUEST, "Paramètre 'since' invalide (format ISO-8601 attendu)");
            }
        }
        return sync.pull(access.patientOf(u), depuis);
    }
}

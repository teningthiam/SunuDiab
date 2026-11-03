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
@RequestMapping("/api")
@RequiredArgsConstructor
public class SharedController {
    private final ConseilService conseils;
    private final PatientService patientService;
    private final MessageService messages;

    @GetMapping("/conseils")
    public List<ConseilDto> conseils() {
        return conseils.liste();
    }

    @GetMapping("/medecins")
    public List<MedecinDto> medecins() {
        return patientService.annuaireMedecins();
    }

    @GetMapping("/regions")
    public Set<String> regions() {
        return Regions.noms();
    }

    // ----- Messagerie patient <-> médecin / relais -----
    @PostMapping("/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public MessageDto envoyer(@AuthenticationPrincipal User u, @Valid @RequestBody MessageRequest r) {
        return messages.envoyer(u, r);
    }

    @GetMapping("/messages/{interlocuteurId}")
    public List<MessageDto> conversation(@AuthenticationPrincipal User u, @PathVariable Long interlocuteurId) {
        return messages.conversation(u, interlocuteurId);
    }

    @GetMapping("/messages/non-lus")
    public Map<String, Long> nonLus(@AuthenticationPrincipal User u) {
        return Map.of("nonLus", messages.nonLus(u));
    }
}

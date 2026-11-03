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
public class AuditService {
    private final AuditLogRepository repo;

    /** Journal d'accès chaîné : chaque ligne contient le hash de la précédente (preuve d'intégrité). */
    @Transactional
    public synchronized void log(User acteur, String typeAction, Long patientId, String details) {
        AuditLog l = new AuditLog();
        l.setActeurId(acteur.getId());
        l.setActeurNom(acteur.getNomComplet());
        l.setActeurRole(acteur.getRole().name());
        l.setTypeAction(typeAction);
        l.setPatientId(patientId);
        l.setDetails(details);
        l.setIp(ip());
        l.setHorodatage(Instant.now());
        String precedent = repo.findFirstByOrderByIdDesc().map(AuditLog::getHash).orElse("GENESIS");
        l.setHashPrecedent(precedent);
        l.setHash(sha256(precedent + "|" + acteur.getId() + "|" + typeAction + "|" + patientId + "|" + details
                + "|" + l.getHorodatage()));
        repo.save(l);
    }

    @Transactional(readOnly = true)
    public PageResponse<AuditDto> liste(Pageable pageable) {
        return PageResponse.of(repo.findAllByOrderByIdDesc(pageable).map(a -> Mapper.toDto(a)));
    }

    private static String ip() {
        var attrs = org.springframework.web.context.request.RequestContextHolder.getRequestAttributes();
        if (attrs instanceof org.springframework.web.context.request.ServletRequestAttributes s) {
            return s.getRequest().getRemoteAddr();
        }
        return null;
    }

    private static String sha256(String s) {
        try {
            var md = java.security.MessageDigest.getInstance("SHA-256");
            return java.util.HexFormat.of().formatHex(md.digest(s.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        } catch (java.security.NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}

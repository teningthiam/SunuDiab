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
public class AuthService {
    private final UserRepository users;
    private final PatientRepository patients;
    private final org.springframework.security.crypto.password.PasswordEncoder encoder;
    private final com.sunudiab.config.JwtService jwt;

    public static String normaliserTelephone(String brut) {
        if (brut == null) return null;
        String s = brut.replaceAll("[^0-9+]", "");
        if (s.startsWith("00")) s = "+" + s.substring(2);
        if (!s.startsWith("+") && s.length() == 9) s = "+221" + s;
        return s;
    }

    @Transactional
    public AuthResponse inscrire(RegisterRequest r) {
        String tel = normaliserTelephone(r.telephone());
        String email = (r.email() == null || r.email().isBlank()) ? null : r.email().trim().toLowerCase();
        if (users.existsByTelephone(tel)) throw new ApiException(HttpStatus.CONFLICT, "Ce numéro est déjà utilisé");
        if (email != null && users.existsByEmailIgnoreCase(email))
            throw new ApiException(HttpStatus.CONFLICT, "Cet e-mail est déjà utilisé");
        String region = Regions.normaliser(r.region());

        User u = new User();
        u.setNom(r.nom().trim());
        u.setPrenom(r.prenom().trim());
        u.setTelephone(tel);
        u.setEmail(email);
        u.setPasswordHash(encoder.encode(r.password()));
        u.setRole(Role.PATIENT);
        u.setLangue(r.langue() != null ? r.langue() : Langue.FR);
        u.setConsentementDonnees(true);
        u.setConsentementDate(Instant.now());
        u = users.save(u);

        PatientProfile p = new PatientProfile();
        p.setUser(u);
        p.setDateNaissance(r.dateNaissance());
        p.setSexe(r.sexe());
        p.setRegion(region);
        p.setLangueVocale(u.getLangue());
        p.setNumeroDossier(genererDossier(region));
        p = patients.save(p);
        return reponse(u, p.getId());
    }

    @Transactional(readOnly = true)
    public AuthResponse connecter(LoginRequest r) {
        String id = r.identifiant().trim();
        Optional<User> opt = id.contains("@") ? users.findByEmailIgnoreCase(id)
                : users.findByTelephone(normaliserTelephone(id));
        User u = opt.filter(x -> x.isActif())
                .filter(x -> encoder.matches(r.password(), x.getPasswordHash()))
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Identifiant ou mot de passe incorrect"));
        Long patientId = patients.findByUserId(u.getId()).map(p -> p.getId()).orElse(null);
        return reponse(u, patientId);
    }

    @Transactional(readOnly = true)
    public AuthResponse rafraichir(String refreshToken) {
        try {
            var claims = jwt.parse(refreshToken);
            if (!"refresh".equals(claims.get("type", String.class))) throw new IllegalArgumentException();
            User u = users.findById(Long.valueOf(claims.getSubject())).filter(x -> x.isActif()).orElseThrow();
            Long patientId = patients.findByUserId(u.getId()).map(p -> p.getId()).orElse(null);
            return reponse(u, patientId);
        } catch (Exception e) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Session expirée, reconnecte-toi");
        }
    }

    @Transactional(readOnly = true)
    public UserInfo moi(User u) {
        Long patientId = patients.findByUserId(u.getId()).map(p -> p.getId()).orElse(null);
        return Mapper.toUserInfo(u, patientId);
    }

    private AuthResponse reponse(User u, Long patientId) {
        return new AuthResponse(jwt.accessToken(u), jwt.refreshToken(u), Mapper.toUserInfo(u, patientId));
    }

    private String genererDossier(String region) {
        long n = patients.count() + 1;
        String num;
        do {
            num = "SN-" + Regions.code(region) + "-" + String.format("%04d", n++);
        } while (patients.existsByNumeroDossier(num));
        return num;
    }
}

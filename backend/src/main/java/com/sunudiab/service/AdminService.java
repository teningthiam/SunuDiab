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
public class AdminService {
    private final UserRepository users;
    private final PatientRepository patients;
    private final AlerteRepository alertes;
    private final MesureRepository mesures;
    private final ConseilRepository conseils;
    private final org.springframework.security.crypto.password.PasswordEncoder encoder;

    @Transactional
    public UserInfo creerUtilisateur(UserCreateRequest r) {
        if (r.role() == Role.PATIENT) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Les patients s'inscrivent depuis l'application mobile");
        }
        String tel = AuthService.normaliserTelephone(r.telephone());
        String email = (r.email() == null || r.email().isBlank()) ? null : r.email().trim().toLowerCase();
        if (email == null && tel == null) throw new ApiException(HttpStatus.BAD_REQUEST, "E-mail ou téléphone obligatoire");
        if (tel != null && users.existsByTelephone(tel)) throw new ApiException(HttpStatus.CONFLICT, "Téléphone déjà utilisé");
        if (email != null && users.existsByEmailIgnoreCase(email)) throw new ApiException(HttpStatus.CONFLICT, "E-mail déjà utilisé");
        User u = new User();
        u.setNom(r.nom());
        u.setPrenom(r.prenom());
        u.setEmail(email);
        u.setTelephone(tel);
        u.setPasswordHash(encoder.encode(r.password()));
        u.setRole(r.role());
        u.setStructure(r.structure());
        u.setSpecialite(r.specialite());
        return Mapper.toUserInfo(users.save(u), null);
    }

    @Transactional(readOnly = true)
    public PageResponse<UserInfo> utilisateurs(Role role, int page, int size) {
        Pageable pg = PageRequest.of(page, Math.min(Math.max(size, 1), 100), Sort.by("id"));
        Page<User> res = role != null ? users.findByRole(role, pg) : users.findAll(pg);
        return PageResponse.of(res.map(u -> Mapper.toUserInfo(u, null)));
    }

    @Transactional
    public void assigner(Long patientId, AssignationRequest r) {
        PatientProfile p = patients.findById(patientId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Patient introuvable"));
        if (r.medecinId() != null) {
            p.setMedecinReferent(users.findById(r.medecinId()).filter(u -> u.getRole() == Role.MEDECIN)
                    .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "Médecin invalide")));
        }
        if (r.infirmierRelaisId() != null) {
            p.setInfirmierRelais(users.findById(r.infirmierRelaisId()).filter(u -> u.getRole() == Role.INFIRMIER_RELAIS)
                    .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "Infirmier relais invalide")));
        }
        patients.save(p);
    }

    /** Statistiques agrégées et anonymes (aucune identité). */
    @Transactional(readOnly = true)
    public ObservatoireDto observatoire() {
        Map<String, Long> parRegion = new LinkedHashMap<>();
        for (Object[] l : patients.compterParRegion()) parRegion.put(l[0] == null ? "Non renseignée" : (String) l[0], ((Number) l[1]).longValue());
        Map<String, Long> parType = new LinkedHashMap<>();
        for (Object[] l : patients.compterParType()) parType.put(((TypeDiabete) l[0]).name(), ((Number) l[1]).longValue());
        return new ObservatoireDto(patients.count(), parRegion, parType,
                DashboardService.tir(mesures.statutsNational(Instant.now().minus(30, ChronoUnit.DAYS))),
                alertes.countByStatutNot(StatutAlerte.TRAITEE));
    }

    @Transactional
    public ConseilDto creerConseil(ConseilRequest r) {
        Conseil c = new Conseil();
        c.setCategorie(r.categorie());
        c.setTitreFr(r.titreFr());
        c.setTitreWo(r.titreWo());
        c.setContenuFr(r.contenuFr());
        c.setContenuWo(r.contenuWo());
        c.setImageUrl(r.imageUrl());
        c.setAudioUrlFr(r.audioUrlFr());
        c.setAudioUrlWo(r.audioUrlWo());
        return Mapper.toDto(conseils.save(c));
    }

    /** Patients en attente d'un médecin référent (identité administrative uniquement, aucune donnée de santé). */
    @Transactional(readOnly = true)
    public PageResponse<PatientResume> patientsSansMedecin(int page, int size) {
        Pageable pg = PageRequest.of(page, Math.min(Math.max(size, 1), 100), Sort.by("id"));
        return PageResponse.of(patients.findByMedecinReferentIsNull(pg).map(p -> new PatientResume(p.getId(), p.getUser().getId(), p.getNumeroDossier(),
                p.getUser().getNomComplet(), null, p.getSexe(), null, null, p.getRegion(), p.getUser().getTelephone(),
                null, null, null)));
    }
}

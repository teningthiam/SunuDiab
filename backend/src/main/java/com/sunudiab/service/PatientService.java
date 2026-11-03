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
public class PatientService {
    private final PatientRepository patients;
    private final ContactRepository contacts;
    private final BilanRepository bilans;
    private final MesureRepository mesures;
    private final UserRepository users;

    @Transactional(readOnly = true)
    public PatientDetail detail(PatientProfile p) {
        List<ContactDto> c = contacts.findByPatientId(p.getId()).stream().map(x -> Mapper.toDto(x)).toList();
        Double hba1c = bilans.findFirstByPatientIdAndTypeIgnoreCaseOrderByDateBilanDesc(p.getId(), "HBA1C")
                .map(b -> b.getValeur()).orElse(null);
        return Mapper.toDetail(p, c, hba1c);
    }

    /** Mise à jour par le patient lui-même. Le type de diabète est un diagnostic : il n'est pas modifiable ici. */
    @Transactional
    public PatientDetail majProfil(PatientProfile p, ProfilUpdateRequest r) {
        PatientProfile cur = patients.findById(p.getId()).orElseThrow();
        if (r.tailleCm() != null) cur.setTailleCm(r.tailleCm());
        if (r.poidsKg() != null) cur.setPoidsKg(r.poidsKg());
        if (r.tourTailleCm() != null) cur.setTourTailleCm(r.tourTailleCm());
        if (r.tensionSystolique() != null) cur.setTensionSystolique(r.tensionSystolique());
        if (r.tensionDiastolique() != null) cur.setTensionDiastolique(r.tensionDiastolique());
        if (r.antecedentsFamiliaux() != null) cur.setAntecedentsFamiliaux(r.antecedentsFamiliaux());
        if (r.couvertureIpm() != null) cur.setCouvertureIpm(r.couvertureIpm());
        if (r.quartier() != null) cur.setQuartier(r.quartier());
        if (r.ville() != null) cur.setVille(r.ville());
        if (r.region() != null) cur.setRegion(Regions.normaliser(r.region()));
        if (r.langueVocale() != null) cur.setLangueVocale(r.langueVocale());
        if (r.rappelSms() != null) cur.setRappelSms(r.rappelSms());
        if (r.partageDossier() != null) cur.setPartageDossier(r.partageDossier());
        return detail(patients.save(cur));
    }

    @Transactional
    public PatientDetail definirDiagnostic(PatientProfile p, TypeDiabete type) {
        PatientProfile cur = patients.findById(p.getId()).orElseThrow();
        cur.setTypeDiabete(type);
        return detail(patients.save(cur));
    }

    @Transactional
    public PatientDetail choisirMedecin(PatientProfile p, Long medecinId) {
        User m = users.findById(medecinId).filter(u -> u.getRole() == Role.MEDECIN && u.isActif())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Médecin introuvable"));
        PatientProfile cur = patients.findById(p.getId()).orElseThrow();
        cur.setMedecinReferent(m);
        return detail(patients.save(cur));
    }

    @Transactional(readOnly = true)
    public List<MedecinDto> annuaireMedecins() {
        return users.findByRoleAndActifTrue(Role.MEDECIN).stream().map(u -> Mapper.toMedecin(u)).toList();
    }

    @Transactional
    public ContactDto ajouterContact(PatientProfile p, ContactRequest r) {
        ContactUrgence c = new ContactUrgence();
        c.setPatient(p);
        c.setNom(r.nom());
        c.setTelephone(AuthService.normaliserTelephone(r.telephone()));
        c.setLien(r.lien());
        return Mapper.toDto(contacts.save(c));
    }

    @Transactional(readOnly = true)
    public List<ContactDto> listerContacts(PatientProfile p) {
        return contacts.findByPatientId(p.getId()).stream().map(c -> Mapper.toDto(c)).toList();
    }

    @Transactional
    public void supprimerContact(PatientProfile p, Long id) {
        ContactUrgence c = contacts.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Contact introuvable"));
        if (!c.getPatient().getId().equals(p.getId())) throw new ApiException(HttpStatus.FORBIDDEN, "Accès refusé");
        contacts.delete(c);
    }

    @Transactional(readOnly = true)
    public PageResponse<PatientResume> liste(User staff, String q, TypeDiabete type, int page, int size) {
        Pageable pg = PageRequest.of(page, Math.min(Math.max(size, 1), 100), Sort.by("id"));
        Page<PatientProfile> res = patients.rechercher(staff.getId(), type, q == null ? "" : q.trim(), pg);
        return PageResponse.of(res.map(p -> Mapper.toResume(p,
                mesures.findFirstByPatientIdAndSupprimeFalseOrderByMesureLeDesc(p.getId()).orElse(null))));
    }

    @Transactional(readOnly = true)
    public List<BilanDto> bilans(Long patientId) {
        return bilans.findByPatientIdOrderByDateBilanDesc(patientId).stream().map(b -> Mapper.toDto(b)).toList();
    }

    @Transactional
    public BilanDto ajouterBilan(PatientProfile p, BilanRequest r) {
        BilanBiologique b = new BilanBiologique();
        b.setPatient(p);
        b.setType(r.type().toUpperCase(Locale.ROOT));
        b.setValeur(r.valeur());
        b.setUnite(r.unite());
        b.setDateBilan(r.dateBilan());
        return Mapper.toDto(bilans.save(b));
    }
}

package com.sunudiab.dto;

import com.sunudiab.dto.Dtos.*;
import com.sunudiab.entity.*;
import com.sunudiab.enums.StatutGlycemie;

import java.util.List;

/** Conversions entités → DTO. */
public final class Mapper {
    private Mapper() {}

    public static String interpretation(StatutGlycemie s) {
        if (s == null) return null;
        return switch (s) {
            case HYPO_SEVERE -> "Hypoglycémie sévère : appelle le SAMU 1515 ou demande de l'aide immédiatement.";
            case HYPO -> "Glycémie basse : prends un apport rapide en sucre (3 morceaux de sucre ou un jus), recontrôle dans 15 minutes et préviens ton médecin.";
            case NORMAL -> "Valeur dans la cible.";
            case LEGEREMENT_ELEVE -> "Légèrement élevée : surveille ton alimentation et refais une mesure plus tard.";
            case ELEVE -> "Élevée : bois de l'eau, évite les aliments sucrés et contacte ton médecin si cela se répète.";
            case CRITIQUE -> "Très élevée : contacte ton médecin sans attendre ; en cas de malaise, appelle le SAMU 1515.";
        };
    }

    public static UserInfo toUserInfo(User u, Long patientId) {
        return new UserInfo(u.getId(), u.getNom(), u.getPrenom(), u.getEmail(), u.getTelephone(),
                u.getRole(), u.getLangue(), patientId);
    }

    public static MedecinDto toMedecin(User u) {
        return new MedecinDto(u.getId(), u.getNomComplet(), u.getSpecialite(), u.getStructure());
    }

    public static MesureDto toDto(MesureGlycemie m) {
        return new MesureDto(m.getId(), m.getClientUuid(), m.getValeur(), m.getMoment(), m.getMethode(),
                m.getContexte(), m.getNote(), m.getMesureLe(), m.getStatut(), interpretation(m.getStatut()),
                m.isSupprime());
    }

    public static ContactDto toDto(ContactUrgence c) {
        return new ContactDto(c.getId(), c.getNom(), c.getTelephone(), c.getLien());
    }

    public static TraitementDto toDto(Traitement t) {
        return new TraitementDto(t.getId(), t.getMedicament(), t.getDosage(), t.getPosologie(), t.getHoraires(),
                t.getDateDebut(), t.getDateFin(), t.isActif(), t.getStockRestant(),
                t.getPrescripteur() == null ? null : t.getPrescripteur().getNomComplet());
    }

    public static PriseDto toDto(PriseMedicament p) {
        return new PriseDto(p.getId(), p.getTraitement().getId(), p.getTraitement().getMedicament(),
                p.getPrisLe(), p.getStatut());
    }

    public static OrdonnanceDto toDto(Ordonnance o) {
        return new OrdonnanceDto(o.getId(), o.getNumero(), o.getLignes(), o.getPharmacie(), o.getDateEmission(),
                o.getDateExpiration(), o.getDureeMois(), o.getStatut(), o.getMedecin().getNomComplet(), o.getNumero());
    }

    public static RdvDto toDto(RendezVous r) {
        return new RdvDto(r.getId(), r.getPatient().getId(), r.getPatient().getUser().getNomComplet(),
                r.getMedecin().getId(), r.getMedecin().getNomComplet(), r.getDateHeure(), r.getMode(),
                r.getMotif(), r.getStatut(), r.getLieu());
    }

    public static AlerteDto toDto(Alerte a) {
        PatientProfile p = a.getPatient();
        return new AlerteDto(a.getId(), p.getId(), p.getUser().getNomComplet(), p.getNumeroDossier(), a.getType(),
                a.getGravite(), a.getStatut(), a.getMessage(), a.getValeur(), a.getCreatedAt(),
                p.getUser().getTelephone());
    }

    public static NoteDto toDto(NoteMedicale n) {
        return new NoteDto(n.getId(), n.getAuteur().getNomComplet(), n.getContenu(), n.isVisibleRelais(), n.getCreatedAt());
    }

    public static BilanDto toDto(BilanBiologique b) {
        return new BilanDto(b.getId(), b.getType(), b.getValeur(), b.getUnite(), b.getDateBilan());
    }

    public static ChatMessageDto toDto(ChatMessage c) {
        return new ChatMessageDto(c.getAuteur().name(), c.getContenu(), c.isUrgence(), c.getCreatedAt());
    }

    public static MessageDto toDto(MessageDirect m) {
        return new MessageDto(m.getId(), m.getExpediteur().getId(), m.getExpediteur().getNomComplet(),
                m.getDestinataire().getId(), m.getContenu(), m.isLu(), m.getCreatedAt());
    }

    public static ConseilDto toDto(Conseil c) {
        return new ConseilDto(c.getId(), c.getCategorie(), c.getTitreFr(), c.getTitreWo(), c.getContenuFr(),
                c.getContenuWo(), c.getImageUrl(), c.getAudioUrlFr(), c.getAudioUrlWo(), c.getUpdatedAt());
    }

    public static InterventionDto toDto(InterventionUrgence i) {
        return new InterventionDto(i.getId(), i.getOrdre(), i.getPatient().getId(),
                i.getPatient().getUser().getNomComplet(), i.getStatut(), i.getLocalisation(), i.getRepere(),
                i.getHopitalReception(), i.getDeclenchePar().getNomComplet(), i.getCreatedAt());
    }

    public static AuditDto toDto(AuditLog a) {
        return new AuditDto(a.getId(), a.getActeurNom(), a.getActeurRole(), a.getTypeAction(), a.getPatientId(),
                a.getDetails(), a.getIp(), a.getHorodatage(), a.getHash());
    }

    public static PatientResume toResume(PatientProfile p, MesureGlycemie derniere) {
        User u = p.getUser();
        return new PatientResume(p.getId(), u.getId(), p.getNumeroDossier(), u.getNomComplet(), p.getAge(),
                p.getSexe(), p.getTypeDiabete(), p.getQuartier(), p.getRegion(), u.getTelephone(),
                derniere == null ? null : derniere.getValeur(),
                derniere == null ? null : derniere.getStatut(),
                derniere == null ? null : derniere.getMesureLe());
    }

    public static PatientDetail toDetail(PatientProfile p, List<ContactDto> contacts, Double hba1c) {
        User u = p.getUser();
        User med = p.getMedecinReferent();
        User rel = p.getInfirmierRelais();
        return new PatientDetail(p.getId(), u.getId(), p.getNumeroDossier(), u.getNom(), u.getPrenom(),
                u.getTelephone(), u.getEmail(), p.getDateNaissance(), p.getAge(), p.getSexe(), p.getTypeDiabete(),
                p.getTailleCm(), p.getPoidsKg(), p.getTourTailleCm(), p.getImc(),
                p.getTensionSystolique(), p.getTensionDiastolique(), p.isAntecedentsFamiliaux(),
                p.getCouvertureIpm(), p.getQuartier(), p.getVille(), p.getRegion(),
                med == null ? null : med.getId(), med == null ? null : med.getNomComplet(),
                rel == null ? null : rel.getId(), rel == null ? null : rel.getNomComplet(),
                rel == null ? null : rel.getTelephone(),
                p.getLangueVocale(), p.isRappelSms(), p.isPartageDossier(), p.getCibleMin(), p.getCibleMax(),
                hba1c, contacts);
    }
}

package com.sunudiab.seed;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import com.sunudiab.repository.*;
import com.sunudiab.service.GlycemieService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

/** Données de démonstration (désactivables avec SEED_ENABLED=false). Ne jamais activer en production. */
@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "app.seed.enabled", havingValue = "true")
public class DataInitializer implements CommandLineRunner {
    private final UserRepository users;
    private final PatientRepository patients;
    private final MesureRepository mesures;
    private final TraitementRepository traitements;
    private final ConseilRepository conseils;
    private final PasswordEncoder encoder;

    private User user(String nom, String prenom, String email, String tel, String mdp, Role role,
                      String structure, String specialite) {
        User u = new User();
        u.setNom(nom);
        u.setPrenom(prenom);
        u.setEmail(email);
        u.setTelephone(tel);
        u.setPasswordHash(encoder.encode(mdp));
        u.setRole(role);
        u.setStructure(structure);
        u.setSpecialite(specialite);
        u.setConsentementDonnees(role == Role.PATIENT);
        return users.save(u);
    }

    @Override
    @Transactional
    public void run(String... args) {
        if (users.count() > 0) return;

        user("Admin", "SunuDiab", "admin@sunudiab.sn", null, "Admin@12345", Role.ADMIN, null, null);
        user("National", "Superviseur", "superviseur@sunudiab.sn", null, "Super@12345", Role.SUPERVISEUR, "MSAS", null);
        User medecin = user("Diop", "Ousmane", "dr.diop@sunudiab.sn", "+221771000001", "Medecin@12345",
                Role.MEDECIN, "Hôpital Principal de Dakar", "Endocrinologie-diabétologie");
        User relais = user("Seck", "Moussa", "moussa.seck@sunudiab.sn", "+221771000002", "Relais@12345",
                Role.INFIRMIER_RELAIS, "Poste de santé Grand Yoff", null);
        User pu = user("Fall", "Aminata", null, "+221774528910", "Patient@12345", Role.PATIENT, null, null);
        pu.setConsentementDate(Instant.now());
        users.save(pu);

        PatientProfile p = new PatientProfile();
        p.setUser(pu);
        p.setNumeroDossier("SN-DKR-0142");
        p.setDateNaissance(LocalDate.now().minusYears(42));
        p.setSexe(Sexe.F);
        p.setTypeDiabete(TypeDiabete.TYPE_2);
        p.setTailleCm(164.0);
        p.setPoidsKg(68.0);
        p.setTourTailleCm(86.0);
        p.setQuartier("Grand Yoff");
        p.setVille("Dakar");
        p.setRegion("Dakar");
        p.setCouvertureIpm("IPM Dakar (80%)");
        p.setMedecinReferent(medecin);
        p.setInfirmierRelais(relais);
        p = patients.save(p);

        double[] valeurs = {1.10, 1.05, 1.18, 1.45, 1.12, 1.22, 1.18};
        for (int i = 0; i < valeurs.length; i++) {
            MesureGlycemie m = new MesureGlycemie();
            m.setClientUuid(UUID.randomUUID().toString());
            m.setPatient(p);
            m.setValeur(valeurs[i]);
            m.setMoment(i == 3 ? MomentMesure.APRES_REPAS : MomentMesure.A_JEUN);
            m.setMesureLe(Instant.now().minus(valeurs.length - 1 - i, ChronoUnit.DAYS));
            m.setStatut(GlycemieService.evaluer(valeurs[i], p.getCibleMin(), p.getCibleMax()));
            mesures.save(m);
        }

        Traitement t = new Traitement();
        t.setPatient(p);
        t.setMedicament("Metformine");
        t.setDosage("500 mg");
        t.setPosologie("1 comprimé le matin et 1 le soir, au milieu des repas");
        t.setHoraires("08:00,20:00");
        t.setDateDebut(LocalDate.now().minusMonths(1));
        t.setStockRestant(36);
        t.setPrescripteur(medecin);
        traitements.save(t);

        // Contenus éducatifs en français. Les versions wolof (titreWo / contenuWo) sont à faire rédiger
        // et valider par un locuteur natif, idéalement un professionnel de santé.
        conseil("Alimentation", "Le gombo (kandia) et vos repas",
                "Riche en fibres, le gombo ralentit l'absorption du sucre après un repas. Associez-le à une petite portion de céréale et à du poisson ou de la viande maigre.");
        conseil("Alimentation", "Thiéboudiène : ajustez les portions",
                "Gardez une petite portion de riz, doublez les légumes (chou, carotte, navet) et privilégiez le poisson. Évitez le riz très gras.");
        conseil("Alimentation", "Ataya : réduisez le sucre",
                "Diminuez progressivement le sucre dans le thé et évitez les boissons industrielles sucrées.");
        conseil("Activité physique", "Marchez 30 minutes",
                "Une marche rapide de 30 minutes presque tous les jours aide à mieux contrôler la glycémie. Une marche douce après le repas est bénéfique.");
        conseil("Urgences", "Hypoglycémie : que faire ?",
                "Signes : sueurs, tremblements, faim soudaine, confusion. Si la personne est consciente : 3 morceaux de sucre ou un jus, puis recontrôler après 15 minutes. "
                        + "Si elle est inconsciente : appeler le SAMU 1515 et ne rien lui faire avaler.");
        log.info("Données de démonstration créées (voir README pour les comptes).");
    }

    private void conseil(String categorie, String titre, String contenu) {
        Conseil c = new Conseil();
        c.setCategorie(categorie);
        c.setTitreFr(titre);
        c.setContenuFr(contenu);
        conseils.save(c);
    }
}

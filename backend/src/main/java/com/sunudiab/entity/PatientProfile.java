package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "patients")
@Getter @Setter @NoArgsConstructor
public class PatientProfile extends BaseEntity {
    @OneToOne(optional = false) @JoinColumn(unique = true) private User user;
    @Column(unique = true, length = 30) private String numeroDossier;
    private LocalDate dateNaissance;
    @Enumerated(EnumType.STRING) @Column(length = 5) private Sexe sexe;
    @Enumerated(EnumType.STRING) @Column(length = 20) private TypeDiabete typeDiabete = TypeDiabete.AUCUN;
    private Double tailleCm;
    private Double poidsKg;
    private Double tourTailleCm;
    private Integer tensionSystolique;
    private Integer tensionDiastolique;
    private boolean antecedentsFamiliaux;
    private String couvertureIpm;
    private String quartier;
    private String ville;
    private String region;
    @ManyToOne private User medecinReferent;
    @ManyToOne private User infirmierRelais;
    @Enumerated(EnumType.STRING) @Column(length = 5) private Langue langueVocale = Langue.FR;
    private boolean rappelSms = true;
    private boolean partageDossier = true;
    private double cibleMin = 0.70;
    private double cibleMax = 1.30;

    public Integer getAge() {
        return dateNaissance == null ? null : Period.between(dateNaissance, LocalDate.now()).getYears();
    }

    public Double getImc() {
        if (tailleCm == null || poidsKg == null || tailleCm <= 0) return null;
        double m = tailleCm / 100.0;
        return Math.round(poidsKg / (m * m) * 10.0) / 10.0;
    }
}

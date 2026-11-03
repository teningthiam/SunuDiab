package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "mesures_glycemie")
@Getter @Setter @NoArgsConstructor
public class MesureGlycemie extends BaseEntity {
    @Column(unique = true, length = 64) private String clientUuid;
    @ManyToOne(optional = false) private PatientProfile patient;
    private double valeur;   // g/L
    @Enumerated(EnumType.STRING) @Column(length = 20) private MomentMesure moment;
    @Enumerated(EnumType.STRING) @Column(length = 20) private MethodeSaisie methode = MethodeSaisie.CLAVIER;
    private String contexte;
    @Column(length = 500) private String note;
    private Instant mesureLe;
    @Enumerated(EnumType.STRING) @Column(length = 20) private StatutGlycemie statut;
    private boolean supprime;
}

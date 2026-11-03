package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "alertes")
@Getter @Setter @NoArgsConstructor
public class Alerte extends BaseEntity {
    @ManyToOne(optional = false) private PatientProfile patient;
    @Enumerated(EnumType.STRING) @Column(length = 30) private TypeAlerte type;
    @Enumerated(EnumType.STRING) @Column(length = 20) private GraviteAlerte gravite;
    @Enumerated(EnumType.STRING) @Column(length = 20) private StatutAlerte statut = StatutAlerte.OUVERTE;
    @Column(length = 500) private String message;
    private Double valeur;
    @ManyToOne private User traitePar;
    private Instant traiteLe;
}

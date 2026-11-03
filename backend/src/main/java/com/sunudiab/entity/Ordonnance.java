package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "ordonnances")
@Getter @Setter @NoArgsConstructor
public class Ordonnance extends BaseEntity {
    @Column(unique = true, nullable = false, length = 40) private String numero;
    @ManyToOne(optional = false) private PatientProfile patient;
    @ManyToOne(optional = false) private User medecin;
    @Column(columnDefinition = "TEXT") private String lignes;
    private String pharmacie;
    private LocalDate dateEmission;
    private LocalDate dateExpiration;
    private int dureeMois;
    @Enumerated(EnumType.STRING) @Column(length = 20) private StatutOrdonnance statut = StatutOrdonnance.ACTIVE;
}

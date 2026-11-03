package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "traitements")
@Getter @Setter @NoArgsConstructor
public class Traitement extends BaseEntity {
    @ManyToOne(optional = false) private PatientProfile patient;
    @Column(nullable = false) private String medicament;
    private String dosage;
    private String posologie;
    private String horaires;          // ex. "08:00,20:00"
    private LocalDate dateDebut;
    private LocalDate dateFin;
    private boolean actif = true;
    private Integer stockRestant;     // nombre de prises restantes
    @ManyToOne private User prescripteur;
}

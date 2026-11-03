package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "interventions_urgence")
@Getter @Setter @NoArgsConstructor
public class InterventionUrgence extends BaseEntity {
    @Column(unique = true, length = 40) private String ordre;
    @ManyToOne(optional = false) private PatientProfile patient;
    @ManyToOne(optional = false) private User declenchePar;
    @Enumerated(EnumType.STRING) @Column(length = 20) private StatutIntervention statut = StatutIntervention.DECLENCHEE;
    private String localisation;
    private String repere;
    private String hopitalReception;
}

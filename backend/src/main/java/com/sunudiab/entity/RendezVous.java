package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "rendez_vous")
@Getter @Setter @NoArgsConstructor
public class RendezVous extends BaseEntity {
    @ManyToOne(optional = false) private PatientProfile patient;
    @ManyToOne(optional = false) private User medecin;
    private LocalDateTime dateHeure;
    @Enumerated(EnumType.STRING) @Column(length = 20) private ModeRdv mode;
    private String motif;
    @Enumerated(EnumType.STRING) @Column(length = 20) private StatutRdv statut = StatutRdv.EN_ATTENTE;
    private String lieu;
}

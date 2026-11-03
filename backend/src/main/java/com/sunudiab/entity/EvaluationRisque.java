package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "evaluations_risque")
@Getter @Setter @NoArgsConstructor
public class EvaluationRisque extends BaseEntity {
    @ManyToOne(optional = false) private PatientProfile patient;
    private int score;
    @Enumerated(EnumType.STRING) @Column(length = 20) private NiveauRisque niveau;
    @Column(columnDefinition = "TEXT") private String reponsesJson;
    @Column(columnDefinition = "TEXT") private String recommandationsCodes;
    private boolean validee;
    @ManyToOne private User validePar;
    private Instant valideeLe;
}

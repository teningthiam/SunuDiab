package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "bilans_biologiques")
@Getter @Setter @NoArgsConstructor
public class BilanBiologique extends BaseEntity {
    @ManyToOne(optional = false) private PatientProfile patient;
    @Column(length = 30, nullable = false) private String type;   // HBA1C, CREATININE...
    private double valeur;
    private String unite;
    private LocalDate dateBilan;
}

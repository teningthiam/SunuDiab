package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "notes_medicales")
@Getter @Setter @NoArgsConstructor
public class NoteMedicale extends BaseEntity {
    @ManyToOne(optional = false) private PatientProfile patient;
    @ManyToOne(optional = false) private User auteur;
    @Column(columnDefinition = "TEXT", nullable = false) private String contenu;
    private boolean visibleRelais;
}

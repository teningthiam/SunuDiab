package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "contacts_urgence")
@Getter @Setter @NoArgsConstructor
public class ContactUrgence extends BaseEntity {
    @ManyToOne(optional = false) private PatientProfile patient;
    @Column(nullable = false) private String nom;
    @Column(nullable = false) private String telephone;
    private String lien;
}

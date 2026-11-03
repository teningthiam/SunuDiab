package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor
public class User extends BaseEntity {
    @Column(nullable = false) private String nom;
    @Column(nullable = false) private String prenom;
    @Column(unique = true) private String email;
    @Column(unique = true, length = 30) private String telephone;
    @Column(nullable = false) private String passwordHash;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30) private Role role;
    @Enumerated(EnumType.STRING) @Column(length = 5) private Langue langue = Langue.FR;
    private boolean consentementDonnees;
    private Instant consentementDate;
    private boolean actif = true;
    private String structure;
    private String specialite;

    public String getNomComplet() { return prenom + " " + nom; }
}

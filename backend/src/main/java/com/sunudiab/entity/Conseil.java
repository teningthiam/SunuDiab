package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "conseils")
@Getter @Setter @NoArgsConstructor
public class Conseil extends BaseEntity {
    private String categorie;
    private String titreFr;
    private String titreWo;
    @Column(columnDefinition = "TEXT") private String contenuFr;
    @Column(columnDefinition = "TEXT") private String contenuWo;
    private String imageUrl;
    private String audioUrlFr;
    private String audioUrlWo;
    private boolean publie = true;
}

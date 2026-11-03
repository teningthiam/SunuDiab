package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "prises_medicament")
@Getter @Setter @NoArgsConstructor
public class PriseMedicament extends BaseEntity {
    @Column(unique = true, length = 64) private String clientUuid;
    @ManyToOne(optional = false) private Traitement traitement;
    private Instant prisLe;
    @Enumerated(EnumType.STRING) @Column(length = 20) private StatutPrise statut = StatutPrise.PRIS;
}

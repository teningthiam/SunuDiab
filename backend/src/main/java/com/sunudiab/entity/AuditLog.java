package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "audit_log")
@Getter @Setter @NoArgsConstructor
public class AuditLog extends BaseEntity {
    private Long acteurId;
    private String acteurNom;
    private String acteurRole;
    private String typeAction;
    private Long patientId;
    @Column(length = 1000) private String details;
    private String ip;
    private Instant horodatage;
    @Column(length = 64) private String hashPrecedent;
    @Column(length = 64) private String hash;
}

package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "chat_messages")
@Getter @Setter @NoArgsConstructor
public class ChatMessage extends BaseEntity {
    @ManyToOne(optional = false) private PatientProfile patient;
    @Enumerated(EnumType.STRING) @Column(length = 20) private AuteurChat auteur;
    @Column(columnDefinition = "TEXT") private String contenu;
    private boolean urgence;
}

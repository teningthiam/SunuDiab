package com.sunudiab.entity;

import com.sunudiab.enums.*;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.*;

@Entity
@Table(name = "messages_directs")
@Getter @Setter @NoArgsConstructor
public class MessageDirect extends BaseEntity {
    @ManyToOne(optional = false) private User expediteur;
    @ManyToOne(optional = false) private User destinataire;
    @Column(columnDefinition = "TEXT", nullable = false) private String contenu;
    private boolean lu;
}

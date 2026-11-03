package com.sunudiab.service;

import com.sunudiab.dto.Dtos.*;
import com.sunudiab.dto.Mapper;
import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import com.sunudiab.exception.ApiException;
import com.sunudiab.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
@RequiredArgsConstructor
public class MessageService {
    private final MessageRepository messages;
    private final UserRepository users;
    private final PatientRepository patients;

    /** Un patient écrit à son médecin référent ou à son relais ; le personnel écrit à ses propres patients. */
    private void verifierDroit(User moi, User autre) {
        boolean ok;
        if (moi.getRole() == Role.PATIENT) {
            PatientProfile p = patients.findByUserId(moi.getId()).orElse(null);
            ok = p != null && ((p.getMedecinReferent() != null && p.getMedecinReferent().getId().equals(autre.getId()))
                    || (p.getInfirmierRelais() != null && p.getInfirmierRelais().getId().equals(autre.getId())));
        } else {
            PatientProfile p = autre.getRole() == Role.PATIENT ? patients.findByUserId(autre.getId()).orElse(null) : null;
            ok = p != null && p.isPartageDossier()
                    && ((p.getMedecinReferent() != null && p.getMedecinReferent().getId().equals(moi.getId()))
                    || (p.getInfirmierRelais() != null && p.getInfirmierRelais().getId().equals(moi.getId())));
        }
        if (!ok) throw new ApiException(HttpStatus.FORBIDDEN, "Vous ne pouvez pas échanger avec cet utilisateur");
    }

    @Transactional
    public MessageDto envoyer(User moi, MessageRequest r) {
        User dest = users.findById(r.destinataireId()).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Destinataire introuvable"));
        verifierDroit(moi, dest);
        MessageDirect m = new MessageDirect();
        m.setExpediteur(moi);
        m.setDestinataire(dest);
        m.setContenu(r.contenu());
        return Mapper.toDto(messages.save(m));
    }

    @Transactional
    public List<MessageDto> conversation(User moi, Long autreId) {
        User autre = users.findById(autreId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Utilisateur introuvable"));
        verifierDroit(moi, autre);
        messages.marquerLus(moi.getId(), autreId);
        return messages.conversation(moi.getId(), autreId).stream().map(m -> Mapper.toDto(m)).toList();
    }

    @Transactional(readOnly = true)
    public long nonLus(User moi) {
        return messages.countByDestinataireIdAndLuFalse(moi.getId());
    }
}

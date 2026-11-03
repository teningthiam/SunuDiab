package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface ChatRepository extends JpaRepository<ChatMessage, Long> {
    List<ChatMessage> findTop12ByPatientIdOrderByCreatedAtDesc(Long patientId);
    List<ChatMessage> findTop50ByPatientIdOrderByCreatedAtDesc(Long patientId);
}

package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface BilanRepository extends JpaRepository<BilanBiologique, Long> {
    List<BilanBiologique> findByPatientIdOrderByDateBilanDesc(Long patientId);
    Optional<BilanBiologique> findFirstByPatientIdAndTypeIgnoreCaseOrderByDateBilanDesc(Long patientId, String type);
}

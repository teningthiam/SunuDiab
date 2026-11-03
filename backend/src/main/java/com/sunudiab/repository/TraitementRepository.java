package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface TraitementRepository extends JpaRepository<Traitement, Long> {
    List<Traitement> findByPatientIdOrderByCreatedAtDesc(Long patientId);
    List<Traitement> findByPatientIdAndActifTrue(Long patientId);
    List<Traitement> findByPatientIdAndUpdatedAtAfter(Long patientId, Instant depuis);
    List<Traitement> findByActifTrueAndStockRestantLessThanEqual(Integer seuil);
}

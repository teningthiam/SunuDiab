package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface MesureRepository extends JpaRepository<MesureGlycemie, Long> {
    Optional<MesureGlycemie> findByClientUuid(String clientUuid);

    Page<MesureGlycemie> findByPatientIdAndSupprimeFalseOrderByMesureLeDesc(Long patientId, Pageable pageable);

    List<MesureGlycemie> findByPatientIdAndSupprimeFalseAndMesureLeAfterOrderByMesureLeAsc(Long patientId, Instant depuis);

    Optional<MesureGlycemie> findFirstByPatientIdAndSupprimeFalseOrderByMesureLeDesc(Long patientId);

    List<MesureGlycemie> findByPatientIdAndUpdatedAtAfter(Long patientId, Instant depuis);

    @Query("select m.statut, count(m) from MesureGlycemie m where m.supprime = false and m.mesureLe >= :depuis "
            + "and m.patient.partageDossier = true "
            + "and (m.patient.medecinReferent.id = :uid or m.patient.infirmierRelais.id = :uid) group by m.statut")
    List<Object[]> statutsPourPersonnel(@Param("uid") Long uid, @Param("depuis") Instant depuis);

    @Query("select m.statut, count(m) from MesureGlycemie m where m.supprime = false and m.mesureLe >= :depuis group by m.statut")
    List<Object[]> statutsNational(@Param("depuis") Instant depuis);

    @Query("select m.patient.id, avg(m.valeur) from MesureGlycemie m where m.supprime = false and m.mesureLe >= :depuis "
            + "group by m.patient.id having count(m) >= :min and avg(m.valeur) > :seuil")
    List<Object[]> derives(@Param("depuis") Instant depuis, @Param("min") long min, @Param("seuil") double seuil);
}

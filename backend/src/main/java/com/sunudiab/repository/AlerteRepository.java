package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface AlerteRepository extends JpaRepository<Alerte, Long> {
    @Query("""
            select a from Alerte a
            where a.patient.partageDossier = true
              and (a.patient.medecinReferent.id = :uid or a.patient.infirmierRelais.id = :uid)
              and (:statut is null or a.statut = :statut)
            order by a.createdAt desc
            """)
    Page<Alerte> pourPersonnel(@Param("uid") Long uid, @Param("statut") StatutAlerte statut, Pageable pageable);

    @Query("select count(a) from Alerte a where a.statut <> :traitee and a.patient.partageDossier = true "
            + "and (a.patient.medecinReferent.id = :uid or a.patient.infirmierRelais.id = :uid)")
    long compterOuvertes(@Param("uid") Long uid, @Param("traitee") StatutAlerte traitee);

    @Query("select count(a) from Alerte a where a.statut <> :traitee and a.gravite = :gravite and a.patient.partageDossier = true "
            + "and (a.patient.medecinReferent.id = :uid or a.patient.infirmierRelais.id = :uid)")
    long compterOuvertesParGravite(@Param("uid") Long uid, @Param("traitee") StatutAlerte traitee,
                                   @Param("gravite") GraviteAlerte gravite);

    long countByStatutNot(StatutAlerte statut);

    boolean existsByPatientIdAndTypeAndStatutNotAndCreatedAtAfter(Long patientId, TypeAlerte type,
                                                                  StatutAlerte statut, Instant depuis);
}

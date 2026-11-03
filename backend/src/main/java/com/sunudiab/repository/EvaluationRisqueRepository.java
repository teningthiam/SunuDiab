package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface EvaluationRisqueRepository extends JpaRepository<EvaluationRisque, Long> {
    List<EvaluationRisque> findByPatientIdOrderByCreatedAtDesc(Long patientId);

    @Query("select count(distinct e.patient.id) from EvaluationRisque e "
            + "where e.niveau in :niveaux and e.patient.typeDiabete = :aucun and e.patient.partageDossier = true "
            + "and (e.patient.medecinReferent.id = :uid or e.patient.infirmierRelais.id = :uid)")
    long compterARisque(@Param("uid") Long uid, @Param("niveaux") Collection<NiveauRisque> niveaux,
                        @Param("aucun") TypeDiabete aucun);
}

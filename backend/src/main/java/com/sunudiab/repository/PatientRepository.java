package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface PatientRepository extends JpaRepository<PatientProfile, Long> {
    Optional<PatientProfile> findByUserId(Long userId);

    boolean existsByNumeroDossier(String numeroDossier);

    @Query("""
            select p from PatientProfile p
            where p.partageDossier = true
              and (p.medecinReferent.id = :uid or p.infirmierRelais.id = :uid)
              and (:type is null or p.typeDiabete = :type)
              and (:q = '' or lower(p.user.nom) like lower(concat('%', :q, '%'))
                   or lower(p.user.prenom) like lower(concat('%', :q, '%'))
                   or lower(p.numeroDossier) like lower(concat('%', :q, '%'))
                   or p.user.telephone like concat('%', :q, '%'))
            """)
    Page<PatientProfile> rechercher(@Param("uid") Long uid, @Param("type") TypeDiabete type,
                                    @Param("q") String q, Pageable pageable);

    @Query("select count(p) from PatientProfile p where p.partageDossier = true "
            + "and (p.medecinReferent.id = :uid or p.infirmierRelais.id = :uid)")
    long compterSuivis(@Param("uid") Long uid);

    @Query("select p.region, count(p) from PatientProfile p group by p.region")
    List<Object[]> compterParRegion();

    @Query("select p.typeDiabete, count(p) from PatientProfile p group by p.typeDiabete")
    List<Object[]> compterParType();

    @Query("""
            select p from PatientProfile p
            where p.typeDiabete <> :aucun
              and not exists (select 1 from MesureGlycemie m
                              where m.patient = p and m.supprime = false and m.mesureLe >= :depuis)
            """)
    List<PatientProfile> sansMesureDepuis(@Param("aucun") TypeDiabete aucun, @Param("depuis") Instant depuis);

    Page<PatientProfile> findByMedecinReferentIsNull(Pageable pageable);
}

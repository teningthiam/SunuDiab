package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface RendezVousRepository extends JpaRepository<RendezVous, Long> {
    List<RendezVous> findByPatientIdOrderByDateHeureDesc(Long patientId);
    List<RendezVous> findByPatientIdAndUpdatedAtAfter(Long patientId, Instant depuis);
    List<RendezVous> findByMedecinIdAndDateHeureBetweenOrderByDateHeureAsc(Long medecinId, LocalDateTime debut, LocalDateTime fin);
    boolean existsByMedecinIdAndDateHeureAndStatutNot(Long medecinId, LocalDateTime dateHeure, StatutRdv statut);
}

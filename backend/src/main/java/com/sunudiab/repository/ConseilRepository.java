package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface ConseilRepository extends JpaRepository<Conseil, Long> {
    List<Conseil> findByPublieTrueOrderByIdAsc();
    List<Conseil> findByUpdatedAtAfter(Instant depuis);
}

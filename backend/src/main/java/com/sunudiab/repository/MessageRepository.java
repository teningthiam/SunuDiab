package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface MessageRepository extends JpaRepository<MessageDirect, Long> {
    @Query("select m from MessageDirect m where (m.expediteur.id = :a and m.destinataire.id = :b) "
            + "or (m.expediteur.id = :b and m.destinataire.id = :a) order by m.createdAt asc")
    List<MessageDirect> conversation(@Param("a") Long a, @Param("b") Long b);

    long countByDestinataireIdAndLuFalse(Long destinataireId);

    @Modifying
    @Query("update MessageDirect m set m.lu = true where m.destinataire.id = :moi and m.expediteur.id = :autre and m.lu = false")
    int marquerLus(@Param("moi") Long moi, @Param("autre") Long autre);
}

package com.sunudiab.repository;

import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.*;
import java.util.*;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmailIgnoreCase(String email);
    Optional<User> findByTelephone(String telephone);
    boolean existsByEmailIgnoreCase(String email);
    boolean existsByTelephone(String telephone);
    List<User> findByRoleAndActifTrue(Role role);
    Page<User> findByRole(Role role, Pageable pageable);
}

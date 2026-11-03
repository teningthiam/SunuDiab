package com.sunudiab.service;

import com.sunudiab.dto.Dtos.*;
import com.sunudiab.dto.Mapper;
import com.sunudiab.entity.*;
import com.sunudiab.enums.*;
import com.sunudiab.exception.ApiException;
import com.sunudiab.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

public final class Regions {
    private static final Map<String, String> CODES = new LinkedHashMap<>();

    static {
        CODES.put("Dakar", "DKR");
        CODES.put("Thiès", "THS");
        CODES.put("Diourbel", "DBL");
        CODES.put("Saint-Louis", "STL");
        CODES.put("Kaolack", "KLK");
        CODES.put("Fatick", "FTK");
        CODES.put("Kaffrine", "KFR");
        CODES.put("Kolda", "KLD");
        CODES.put("Louga", "LGA");
        CODES.put("Matam", "MTM");
        CODES.put("Sédhiou", "SDH");
        CODES.put("Tambacounda", "TMB");
        CODES.put("Kédougou", "KDG");
        CODES.put("Ziguinchor", "ZGR");
    }

    private Regions() {}

    private static String sansAccent(String s) {
        return java.text.Normalizer.normalize(s, java.text.Normalizer.Form.NFD).replaceAll("\\p{M}", "").toLowerCase(Locale.ROOT);
    }

    /** Retourne le nom officiel de la région (Dakar par défaut) ou lève une erreur 400. */
    public static String normaliser(String region) {
        if (region == null || region.isBlank()) return "Dakar";
        String cible = sansAccent(region.trim());
        for (String nom : CODES.keySet()) {
            if (sansAccent(nom).equals(cible)) return nom;
        }
        throw new ApiException(HttpStatus.BAD_REQUEST, "Région inconnue : " + region);
    }

    public static String code(String region) {
        return CODES.getOrDefault(region, "SEN");
    }

    public static Set<String> noms() {
        return CODES.keySet();
    }
}

package com.sunudiab.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    public record Erreur(Instant horodatage, int statut, String message, Map<String, String> details) {}

    private ResponseEntity<Erreur> reponse(HttpStatus s, String message, Map<String, String> details) {
        return ResponseEntity.status(s).body(new Erreur(Instant.now(), s.value(), message, details));
    }

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<Erreur> api(ApiException e) {
        return reponse(e.getStatus(), e.getMessage(), null);
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Erreur> statut(ResponseStatusException e) {
        return reponse(HttpStatus.valueOf(e.getStatusCode().value()), e.getReason(), null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Erreur> validation(MethodArgumentNotValidException e) {
        Map<String, String> details = new LinkedHashMap<>();
        e.getBindingResult().getFieldErrors().forEach(f -> details.put(f.getField(), f.getDefaultMessage()));
        return reponse(HttpStatus.BAD_REQUEST, "Données invalides", details);
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<Erreur> illisible(Exception e) {
        return reponse(HttpStatus.BAD_REQUEST, "Requête invalide (format ou valeur non reconnue)", null);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Erreur> interdit(AccessDeniedException e) {
        return reponse(HttpStatus.FORBIDDEN, "Accès refusé", null);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Erreur> integrite(DataIntegrityViolationException e) {
        log.warn("Violation d'intégrité : {}", e.getMostSpecificCause().getMessage());
        return reponse(HttpStatus.CONFLICT, "Conflit de données (doublon ou référence invalide)", null);
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Erreur> inattendue(RuntimeException e) {
        log.error("Erreur inattendue", e);
        return reponse(HttpStatus.INTERNAL_SERVER_ERROR, "Erreur interne du serveur", null);
    }
}

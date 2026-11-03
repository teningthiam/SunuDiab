package com.sunudiab.dto;

import com.sunudiab.enums.*;
import jakarta.validation.constraints.*;
import org.springframework.data.domain.Page;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/** Tous les objets échangés avec les clients (Flutter, Angular). */
public final class Dtos {
    private Dtos() {}

    // ---------- Pagination ----------
    public record PageResponse<T>(List<T> contenu, int page, int taille, long total, int totalPages) {
        public static <T> PageResponse<T> of(Page<T> p) {
            return new PageResponse<>(p.getContent(), p.getNumber(), p.getSize(), p.getTotalElements(), p.getTotalPages());
        }
    }

    // ---------- Auth ----------
    public record RegisterRequest(
            @NotBlank String nom,
            @NotBlank String prenom,
            @NotBlank @Pattern(regexp = "^[+0-9 ]{8,20}$", message = "Numéro de téléphone invalide") String telephone,
            @Email String email,
            @NotBlank @Size(min = 8, message = "8 caractères minimum") String password,
            LocalDate dateNaissance,
            Sexe sexe,
            Langue langue,
            String region,
            @AssertTrue(message = "Le consentement au traitement des données de santé est obligatoire") boolean consentement) {}

    public record LoginRequest(@NotBlank String identifiant, @NotBlank String password) {}
    public record RefreshRequest(@NotBlank String refreshToken) {}
    public record UserInfo(Long id, String nom, String prenom, String email, String telephone, Role role,
                           Langue langue, Long patientId) {}
    public record AuthResponse(String accessToken, String refreshToken, UserInfo utilisateur) {}

    // ---------- Patient ----------
    public record ContactRequest(@NotBlank String nom, @NotBlank String telephone, String lien) {}
    public record ContactDto(Long id, String nom, String telephone, String lien) {}

    public record ProfilUpdateRequest(
            TypeDiabete typeDiabete, Double tailleCm, Double poidsKg, Double tourTailleCm,
            Integer tensionSystolique, Integer tensionDiastolique, Boolean antecedentsFamiliaux,
            String couvertureIpm, String quartier, String ville, String region,
            Langue langueVocale, Boolean rappelSms, Boolean partageDossier) {}

    public record MedecinChoixRequest(@NotNull Long medecinId) {}

    public record MedecinDto(Long id, String nomComplet, String specialite, String structure) {}

    public record PatientResume(Long id, Long userId, String numeroDossier, String nomComplet, Integer age, Sexe sexe,
                                TypeDiabete typeDiabete, String quartier, String region, String telephone,
                                Double derniereGlycemie, StatutGlycemie derniereStatut, Instant derniereMesureLe) {}

    public record PatientDetail(Long id, Long userId, String numeroDossier, String nom, String prenom, String telephone,
                                String email, LocalDate dateNaissance, Integer age, Sexe sexe, TypeDiabete typeDiabete,
                                Double tailleCm, Double poidsKg, Double tourTailleCm, Double imc,
                                Integer tensionSystolique, Integer tensionDiastolique, boolean antecedentsFamiliaux,
                                String couvertureIpm, String quartier, String ville, String region,
                                Long medecinReferentId, String medecinReferentNom,
                                Long infirmierRelaisId, String infirmierRelaisNom, String infirmierRelaisTelephone,
                                Langue langueVocale, boolean rappelSms, boolean partageDossier,
                                double cibleMin, double cibleMax, Double derniereHba1c, List<ContactDto> contacts) {}

    // ---------- Glycémie ----------
    public record MesureRequest(
            @NotNull @DecimalMin(value = "0.2", message = "Valeur trop basse (g/L)") @DecimalMax(value = "6.0", message = "Valeur trop haute (g/L)") Double valeur,
            @NotNull MomentMesure moment, MethodeSaisie methode, @Size(max = 255) String contexte,
            @Size(max = 500) String note, Instant mesureLe, String clientUuid) {}

    public record MesureDto(Long id, String clientUuid, Double valeur, MomentMesure moment, MethodeSaisie methode,
                            String contexte, String note, Instant mesureLe, StatutGlycemie statut,
                            String interpretation, boolean supprime) {}

    public record MesureResponse(MesureDto mesure, boolean urgence, String message) {}

    public record GlycemieStats(int jours, Double moyenne, int nombreMesures, double pourcentageDansCible,
                                int hypoglycemies, double mesuresParJour, List<MesureDto> points) {}

    // ---------- Risque (FINDRISC) ----------
    public record RisqueRequest(
            @NotNull @Min(18) @Max(120) Integer age,
            @NotNull Sexe sexe,
            @NotNull @DecimalMin("100") @DecimalMax("250") Double tailleCm,
            @NotNull @DecimalMin("25") @DecimalMax("300") Double poidsKg,
            @NotNull @DecimalMin("40") @DecimalMax("250") Double tourTailleCm,
            @NotNull ActiviteFindrisc activite,
            @NotNull Boolean fruitsLegumesQuotidien,
            @NotNull Boolean traitementHypertension,
            @NotNull Boolean glycemieElevee,
            @NotNull AntecedentsFamiliaux antecedents) {}

    public record RisqueResult(Long id, int score, int scoreMax, NiveauRisque niveau, String probabilite,
                               List<String> recommandationsCodes, List<String> recommandations,
                               String avertissement, Instant date, boolean validee) {}

    // ---------- Traitements / ordonnances ----------
    public record TraitementRequest(@NotBlank String medicament, String dosage, String posologie, String horaires,
                                    LocalDate dateDebut, LocalDate dateFin, @Min(0) Integer stockRestant) {}
    public record TraitementDto(Long id, String medicament, String dosage, String posologie, String horaires,
                                LocalDate dateDebut, LocalDate dateFin, boolean actif, Integer stockRestant,
                                String prescripteur) {}
    public record PriseRequest(@NotNull Long traitementId, StatutPrise statut, Instant prisLe, String clientUuid) {}
    public record PriseDto(Long id, Long traitementId, String medicament, Instant prisLe, StatutPrise statut) {}

    public record OrdonnanceRequest(@NotBlank String lignes, String pharmacie, @Min(1) @Max(12) int dureeMois) {}
    public record OrdonnanceDto(Long id, String numero, String lignes, String pharmacie, LocalDate dateEmission,
                                LocalDate dateExpiration, int dureeMois, StatutOrdonnance statut,
                                String medecin, String qrPayload) {}

    // ---------- Rendez-vous ----------
    public record RdvRequest(Long medecinId, @NotNull LocalDateTime dateHeure, @NotNull ModeRdv mode, String motif) {}
    public record RdvStatutRequest(@NotNull StatutRdv statut) {}
    public record RdvDto(Long id, Long patientId, String patientNom, Long medecinId, String medecinNom,
                         LocalDateTime dateHeure, ModeRdv mode, String motif, StatutRdv statut, String lieu) {}

    // ---------- Alertes / notes / bilans ----------
    public record AlerteDto(Long id, Long patientId, String patientNom, String numeroDossier, TypeAlerte type,
                            GraviteAlerte gravite, StatutAlerte statut, String message, Double valeur,
                            Instant createdAt, String telephonePatient) {}
    public record AlerteUpdateRequest(@NotNull StatutAlerte statut) {}

    public record NoteRequest(@NotBlank String contenu, boolean visibleRelais) {}
    public record NoteDto(Long id, String auteur, String contenu, boolean visibleRelais, Instant createdAt) {}

    public record BilanRequest(@NotBlank String type, @NotNull Double valeur, String unite, @NotNull LocalDate dateBilan) {}
    public record BilanDto(Long id, String type, Double valeur, String unite, LocalDate dateBilan) {}

    // ---------- Assistant IA ----------
    public record ChatRequest(@NotBlank @Size(max = 1000) String message) {}
    public record ChatReply(String reponse, boolean urgence, boolean assistantDisponible, Instant date) {}
    public record ChatMessageDto(String auteur, String contenu, boolean urgence, Instant createdAt) {}

    // ---------- Messagerie ----------
    public record MessageRequest(@NotNull Long destinataireId, @NotBlank String contenu) {}
    public record MessageDto(Long id, Long expediteurId, String expediteurNom, Long destinataireId,
                             String contenu, boolean lu, Instant createdAt) {}

    // ---------- Conseils ----------
    public record ConseilDto(Long id, String categorie, String titreFr, String titreWo, String contenuFr,
                             String contenuWo, String imageUrl, String audioUrlFr, String audioUrlWo, Instant updatedAt) {}
    public record ConseilRequest(String categorie, @NotBlank String titreFr, String titreWo, @NotBlank String contenuFr,
                                 String contenuWo, String imageUrl, String audioUrlFr, String audioUrlWo) {}

    // ---------- Synchronisation hors ligne ----------
    public record SyncMesure(@NotBlank String clientUuid, @NotNull Double valeur, @NotNull MomentMesure moment,
                             MethodeSaisie methode, String contexte, String note, Instant mesureLe, boolean supprime) {}
    public record SyncPrise(@NotBlank String clientUuid, @NotNull Long traitementId, Instant prisLe, StatutPrise statut) {}
    public record SyncPushRequest(List<SyncMesure> mesures, List<SyncPrise> prises) {}
    public record SyncItemResult(String clientUuid, String statut, Long serverId, String message) {}
    public record SyncPushResponse(List<SyncItemResult> resultats, Instant serverTime) {}
    public record SyncPullResponse(Instant serverTime, PatientDetail profil, List<MesureDto> mesures,
                                   List<TraitementDto> traitements, List<RdvDto> rendezVous,
                                   List<OrdonnanceDto> ordonnances, List<ConseilDto> conseils) {}

    // ---------- Tableaux de bord ----------
    public record TirDto(long total, long normal, long bas, long eleve, long critique, double pctNormal) {}
    public record DashboardMedecin(long patientsSuivis, long alertesOuvertes, long alertesUrgentes,
                                   long consultationsDuJour, long consultationsPresentiel, long consultationsTele,
                                   long risqueAConfirmer, TirDto tir30Jours) {}
    public record ObservatoireDto(long patientsSuivis, Map<String, Long> parRegion, Map<String, Long> parTypeDiabete,
                                  TirDto tirNational30Jours, long alertesOuvertes) {}

    // ---------- Urgence SAMU ----------
    public record SamuRequest(@NotBlank String localisation, String repere, String hopitalReception) {}
    public record InterventionDto(Long id, String ordre, Long patientId, String patientNom, StatutIntervention statut,
                                  String localisation, String repere, String hopitalReception,
                                  String declencheParNom, Instant createdAt) {}

    // ---------- Administration ----------
    public record UserCreateRequest(@NotBlank String nom, @NotBlank String prenom, @Email String email,
                                    @Pattern(regexp = "^[+0-9 ]{8,20}$", message = "Numéro de téléphone invalide") String telephone,
                                    @NotBlank @Size(min = 8) String password, @NotNull Role role,
                                    String structure, String specialite) {}
    public record AssignationRequest(Long medecinId, Long infirmierRelaisId) {}
    public record AuditDto(Long id, String acteurNom, String acteurRole, String typeAction, Long patientId,
                           String details, String ip, Instant horodatage, String hash) {}
}

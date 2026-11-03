# SunuDiab API (Spring Boot 3.3 · Java 17 · MySQL)

Backend de SunuDiab : app mobile patient (Flutter) + web médecin/hôpital (Angular).

## Démarrage

```bash
docker compose up -d                      # MySQL (ou utilise ton MySQL local)
export DB_PASSWORD=root                   # selon ton MySQL (Windows : set DB_PASSWORD=root)
export ANTHROPIC_API_KEY=sk-ant-...       # optionnel : sans clé, l'assistant renvoie une réponse de secours
mvn spring-boot:run
```

- Swagger : http://localhost:8080/swagger-ui.html (bouton **Authorize** → coller l'`accessToken`)
- Les tables sont créées automatiquement (`ddl-auto=update`).
- Variables : `DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD JWT_SECRET CORS_ORIGINS ANTHROPIC_API_KEY ANTHROPIC_MODEL SEED_ENABLED`

## Comptes de démonstration (SEED_ENABLED=true)

| Rôle | Identifiant | Mot de passe |
|---|---|---|
| Admin | admin@sunudiab.sn | Admin@12345 |
| Superviseur national | superviseur@sunudiab.sn | Super@12345 |
| Médecin | dr.diop@sunudiab.sn | Medecin@12345 |
| Infirmier relais | moussa.seck@sunudiab.sn | Relais@12345 |
| Patient | +221774528910 | Patient@12345 |

## Test rapide

```bash
# connexion patient
curl -s -X POST localhost:8080/api/auth/login -H 'Content-Type: application/json' \
  -d '{"identifiant":"+221774528910","password":"Patient@12345"}'

# ajouter une glycémie (g/L)
curl -s -X POST localhost:8080/api/patient/mesures -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{"valeur":0.48,"moment":"A_JEUN"}'
# -> statut HYPO_SEVERE, urgence=true, et une alerte URGENCE_VITALE apparaît chez le médecin
```

## Endpoints principaux

**Auth** : `POST /api/auth/register | login | refresh` · `GET /api/me`

**Patient** (`/api/patient`, rôle PATIENT)
`GET|PUT /profil` · `PUT /medecin-referent` · `GET|POST|DELETE /contacts`
`GET|POST /mesures` · `DELETE /mesures/{id}` · `GET /mesures/stats?jours=7`
`POST|GET /risque` (FINDRISC) · `GET /traitements` · `POST|GET /prises` · `GET /ordonnances` · `GET /bilans`
`GET|POST /rendez-vous` · `PUT /rendez-vous/{id}/annuler` · `GET|POST /chat`

**Hors ligne** : `POST /api/sync` (envoi par lots, idempotent via `clientUuid`) · `GET /api/sync?since=<serverTime>`

**Commun** : `GET /api/conseils` · `GET /api/medecins` · `GET /api/regions` · `POST /api/messages` · `GET /api/messages/{id}` · `GET /api/messages/non-lus`

**Médecin / relais** (`/api/medecin`)
`GET /dashboard` · `GET /patients?q=&type=` · `GET /patients/{id}` · `PUT /patients/{id}/diagnostic?type=`
`GET /patients/{id}/mesures | mesures/stats | risque | notes | traitements | ordonnances | bilans | chat`
`POST /patients/{id}/notes | traitements | ordonnances | bilans | rendez-vous | samu`
`GET /alertes?statut=` · `PUT /alertes/{id}` · `GET /rendez-vous?date=` · `PUT /rendez-vous/{id}/statut` · `GET /samu`

**Admin / superviseur** (`/api/admin`) : `GET /observatoire` (anonyme) · `POST|GET /utilisateurs` · `GET /patients-sans-medecin` · `PUT /patients/{id}/assignation` · `GET /audit` · `POST /conseils`

## Règles métier importantes

- **Glycémie en g/L** (conversion mmol/L côté client). Seuils : < 0,54 hypo sévère ; < cible min hypo ; cible 0,70–1,30 ; ≤ 1,80 légèrement élevée ; ≤ 2,50 élevée ; > 2,50 critique.
- **Alertes automatiques** : hypo sévère / hyper critique à la saisie ; job quotidien (07h) : pas de mesure depuis 7 j, stock de traitement ≤ 5 prises, moyenne 14 j > 1,60 g/L.
- **Test de risque** : score FINDRISC (0–26). C'est une estimation, jamais un diagnostic ; le type de diabète n'est modifiable que par un médecin.
- **Assistant IA** : détection de mots d'alerte AVANT l'appel au modèle (réponse fixe « appelle le 1515 » + alerte médecin), prompt avec garde-fous, contexte sans identité. Réponses en français (le wolof passe par des contenus validés).
- **Confidentialité** : un médecin/relais n'accède qu'aux patients dont il est référent ET qui partagent leur dossier ; chaque accès est tracé dans un journal chaîné par hash (`/api/admin/audit`). Admin et superviseur ne voient aucun dossier patient.

## À faire / non inclus

OTP par SMS à l'inscription, SMS/WhatsApp de rappel, notifications push (FCM), vraie intégration SAMU 1515 (aujourd'hui : ordre enregistré seulement), export FHIR, audio wolof/TTS, migrations Flyway, tests automatisés, limitation de débit sur `/auth/login`, déclaration CDP et validation médicale des contenus.

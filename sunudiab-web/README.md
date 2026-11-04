# SunuDiab Pro : portail web (Angular 21)

Portail pour médecins, infirmiers relais, administrateurs et superviseurs nationaux. Il utilise l'API Spring Boot `sunudiab-api`.

## Prérequis
- Node.js **20.19+, 22.12+ ou 24+** (vérifier : `node -v`)
- Backend démarré sur http://localhost:8080 (comptes de démo actifs : `SEED_ENABLED=true`)
- CORS du backend : l'origine `http://localhost:4200` doit être autorisée (c'est le cas par défaut)

## Lancer
```bash
npm install
npm start          # ouvre http://localhost:4200
```
Autre adresse d'API : sur l'écran de connexion, déplie « Serveur », saisis l'adresse puis « Enregistrer et recharger ».

## Comptes de démonstration
| Rôle | Identifiant | Mot de passe |
|---|---|---|
| Médecin | dr.diop@sunudiab.sn | Medecin@12345 |
| Infirmier relais | moussa.seck@sunudiab.sn | Relais@12345 |
| Administrateur | admin@sunudiab.sn | Admin@12345 |
| Superviseur national | superviseur@sunudiab.sn | Super@12345 |

Les patients n'ont pas accès à ce portail (application mobile).

## Pages par rôle
- **Médecin** : tableau de bord, patients, dossier patient (résumé + courbe, glycémies, traitements, ordonnances, notes, bilans, échanges IA, messagerie, diagnostic, ordre SAMU), alertes, rendez-vous.
- **Infirmier relais** : mêmes pages en lecture, plus notes ; ne peut pas prescrire ni changer le diagnostic.
- **Administrateur** : observatoire, utilisateurs, affectation des patients, journal d'audit.
- **Superviseur** : observatoire (statistiques anonymes) uniquement.

## Construire pour la production
```bash
npm run build      # fichiers dans dist/sunudiab-web (à servir en https)
```
En production : API en https, CORS limité au domaine du portail, retirer les comptes de démo.

## Notes
- Les jetons sont gardés dans le navigateur (localStorage) : en production, prévoir des cookies HttpOnly côté serveur.
- « Ordre SAMU » enregistre un ordre dans SunuDiab ; il n'appelle pas le SAMU.
- Non inclus : bascule FR/Wolof, carte du Sénégal, export PDF/Excel, tests automatisés.

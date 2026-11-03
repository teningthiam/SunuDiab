# SunuDiab : application mobile patient (Flutter)

Offline-first : toutes les données sont lues depuis le téléphone (SQLite) et synchronisées en arrière-plan avec l'API Spring Boot (`sunudiab-api`).

## 1. Installation

Ce dossier contient `lib/` et `pubspec.yaml`. Génère d'abord les dossiers Android/iOS dans ce dossier :

```bash
flutter create --org sn.sunudiab --project-name sunudiab .
rm test/widget_test.dart          # le test d'exemple ne correspond plus à l'app
flutter pub get
```

## 2. Configuration Android (android/app/src/main/AndroidManifest.xml)

```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <queries>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>
    </queries>
    <application ... android:usesCleartextTraffic="true">   <!-- http en développement uniquement ; utilise https en production -->
```

Dans `android/app/build.gradle(.kts)`, `minSdk` doit être **23 ou plus** (flutter_secure_storage) :
`minSdk = 23` (ou `minSdkVersion 23`).

iOS (`ios/Runner/Info.plist`) : ajoute `LSApplicationQueriesSchemes` avec `tel`, et autorise le http local en développement (`NSAppTransportSecurity` > `NSAllowsLocalNetworking`).

## 3. Lancer

Backend démarré (`mvn spring-boot:run`), puis :

```bash
flutter run                                              # émulateur Android (10.0.2.2 = ton PC)
flutter run --dart-define=API_URL=http://192.168.1.20:8080   # téléphone réel : IP de ton PC sur le même Wi-Fi
```

Compte de démonstration : **+221774528910 / Patient@12345** (le backend doit avoir SEED_ENABLED=true).

## 4. Scénarios de test

1. **Connexion**, puis l'accueil affiche la dernière glycémie et le graphique 7 jours.
2. **Mode avion** : ajoute une glycémie (Accueil > Noter ma glycémie). Elle apparaît avec l'icône « en attente » (horloge). Coupe puis rétablis le réseau : elle passe à « synchronisé » (nuage vert).
3. **Valeur 0.48** : alerte « Hypoglycémie sévère » avec bouton d'appel au 1515, et alerte visible côté médecin.
4. **Test de risque** hors ligne : le résultat s'affiche sans internet.
5. **Assistant** : « J'ai un malaise et je vomis » donne une réponse d'urgence fixe + bouton d'appel ; hors ligne : conseils intégrés.
6. **Rendez-vous** (en ligne), **traitements** (« J'ai pris » marche hors ligne), **Pass Santé QR**, contacts d'urgence.
7. **Wolof / Français** : bouton FR | WO en haut de l'app.

## 5. Structure

```
lib/
  main.dart, app.dart            point d'entrée, thème, langues, AuthGate
  core/       api_client (JWT + refresh auto), local_db (SQLite), findrisc (score hors ligne), glycemia (seuils), theme
  models/     modèles
  providers/  auth, data (offline-first + sync), chat, connectivité, langue
  services/   sync_service (push idempotent puis pull), tts_service
  screens/    welcome, login, register, home, tracking, add_measure, risk_test, assistant,
              appointments, treatments, advice, profile, health_profile
  widgets/    composants communs, graphique de glycémie
  l10n/       strings.dart (FR + WO), délégués wolof pour les widgets Flutter
```

## 6. Important

- **Wolof** : `lib/l10n/strings.dart` ne contient que quelques mots courants (oui, non, salutations). Tout le reste retombe sur le français. Les traductions médicales doivent être rédigées et **validées par un locuteur natif** (idéalement un professionnel de santé) avant diffusion. Pour ajouter une traduction : ajouter la clé dans `kWo`.
- **Audio** : lecture vocale en français (voix du téléphone). Le wolof audio nécessite des enregistrements validés (champs `audioUrlWo` déjà prévus côté API).
- **Seuils de glycémie, conseils et recommandations** : à faire valider par un médecin.
- **Non inclus** : rappels par notifications locales, saisie vocale, unité mmol/L, chiffrement de la base (passer à sqflite_sqlcipher), code SMS à l'inscription, notifications push, tests automatisés.
- **Sécurité** : en production, utiliser **https** et retirer `usesCleartextTraffic`.

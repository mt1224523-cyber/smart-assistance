# Sécurité — Smart Assistance

Ce document décrit les mesures de sécurité appliquées au projet et les opérations à exécuter lors des builds release.

## Cycle de vie des secrets

| Secret | Emplacement | Visibilité |
|---|---|---|
| `OPENAI_API_KEY` | `server/.env` (serveur uniquement) | jamais embarquée dans l'APK |
| `APP_API_KEY` | `server/.env` + `smart_assistance/env.json` (build-time) | présente dans l'APK — voir App Check ci-dessous |
| Keystore Android | `android/key.properties` (jamais committé) | local + CI sécurisée |
| Service account Firebase | hors-repo, pointé par `GOOGLE_APPLICATION_CREDENTIALS` | serveur uniquement |

## Build release sécurisé

Android :

```bash
flutter build apk --release \
  --dart-define-from-file=env.json \
  --obfuscate \
  --split-debug-info=build/symbols
```

iOS :

```bash
flutter build ipa --release \
  --dart-define-from-file=env.json \
  --obfuscate \
  --split-debug-info=build/symbols
```

- `--obfuscate` rend la rétro-ingénierie Dart beaucoup plus coûteuse (MASVS-CODE-4).
- `--split-debug-info` extrait les symboles dans un dossier séparé qui ne doit pas être livré avec l'APK — à conserver pour symboliser les crashs.
- ProGuard / R8 est déjà activé (`minifyEnabled`, `shrinkResources` dans [android/app/build.gradle](smart_assistance/android/app/build.gradle)).

## Stockage local chiffré

L'historique des conversations et les préférences sont persistés via `flutter_secure_storage` :

- Android : EncryptedSharedPreferences (AES-256-GCM, clé dans le Keystore matériel).
- iOS : Keychain avec accessibilité `first_unlock_this_device` (clés non synchronisées iCloud, non accessibles tant que l'appareil n'a pas été déverrouillé une fois après reboot).
- Fichiers concernés : [history_repository.dart](smart_assistance/lib/data/repositories/history_repository.dart), [settings_repository.dart](smart_assistance/lib/data/repositories/settings_repository.dart).

⚠️ `flutter pub get` doit être exécuté après la migration pour télécharger la nouvelle dépendance.

## Certificate Pinning

### Android (recommandé : pinning natif)

Le template est en place dans [network_security_config.xml](smart_assistance/android/app/src/main/res/xml/network_security_config.xml). Pour l'activer en production :

1. Récupérer l'empreinte SPKI primaire (certificat actuel) :
   ```bash
   openssl s_client -connect api.exemple.ci:443 -servername api.exemple.ci < /dev/null 2>/dev/null \
     | openssl x509 -pubkey -noout \
     | openssl pkey -pubin -outform DER \
     | openssl dgst -sha256 -binary \
     | openssl enc -base64
   ```
2. Récupérer une empreinte de **secours obligatoire** (clé/CA de la prochaine rotation, jamais déployée encore) — sans elle, vous bricquez l'app le jour du renouvellement.
3. Décommenter le bloc `<domain-config>` dans `network_security_config.xml` et remplacer `api.exemple.ci` + les deux pins.
4. Tester avec un proxy Burp/mitmproxy : la connexion doit échouer.

### iOS

App Transport Security est déjà strict. Pour ajouter du pinning :

1. Ajouter [TrustKit](https://github.com/datatheorem/TrustKit) via CocoaPods.
2. Initialiser TrustKit dans [AppDelegate.swift](smart_assistance/ios/Runner/AppDelegate.swift) avec les mêmes empreintes SPKI.
3. Alternative légère : utiliser `URLSessionDelegate` custom avec validation SPKI dans le code natif iOS, exposé à Flutter via un `MethodChannel`.

## Auth client : Firebase App Check (recommandé pour la prod publique)

Le token statique `APP_API_KEY` est embarqué dans l'APK et donc extractible. App Check ajoute une **attestation cryptographique** que l'appel provient bien d'un binaire signé non altéré (Play Integrity sur Android, App Attest sur iOS).

Le serveur est déjà prêt : il vérifie le header `X-Firebase-AppCheck` quand `FIREBASE_PROJECT_ID` est défini, et ignore sinon (voir [server/main.py](server/main.py)).

### Activation (résumé)

**Côté Firebase Console :**
1. Créer un projet Firebase, y enregistrer votre app Android (bundle `com.smartassistance.smart_assistance`) et iOS.
2. Dans *App Check*, activer Play Integrity (Android) et App Attest (iOS).
3. Créer un service account avec le rôle *Firebase App Check Admin*, télécharger le JSON.

**Côté serveur :**
1. `pip install firebase-admin` (déjà listé en commentaire dans `requirements.txt`).
2. Exporter :
   ```bash
   export FIREBASE_PROJECT_ID=votre-projet
   export GOOGLE_APPLICATION_CREDENTIALS=/chemin/vers/service-account.json
   ```

**Côté Flutter :**
1. `flutter pub add firebase_core firebase_app_check`.
2. Suivre la doc d'installation Firebase (`flutterfire configure`).
3. Dans [main.dart](smart_assistance/lib/main.dart) :
   ```dart
   await Firebase.initializeApp();
   await FirebaseAppCheck.instance.activate(
     androidProvider: AndroidProvider.playIntegrity,
     appleProvider: AppleProvider.appAttest,
   );
   ```
4. Dans [ai_service.dart](smart_assistance/lib/data/services/ai_service.dart), récupérer le token avant chaque appel et l'ajouter aux headers :
   ```dart
   final appCheckToken = await FirebaseAppCheck.instance.getToken();
   request.headers['X-Firebase-AppCheck'] = appCheckToken ?? '';
   ```

Tant que `FIREBASE_PROJECT_ID` reste vide côté serveur, l'app continue de fonctionner avec uniquement `APP_API_KEY` — le câblage est donc déployable progressivement.

## Durcissement Android appliqué

- `android:allowBackup="false"` + `dataExtractionRules` : empêche les sauvegardes ADB/cloud/device-transfer.
- `FLAG_SECURE` ([MainActivity.kt](smart_assistance/android/app/src/main/kotlin/com/smartassistance/smart_assistance/MainActivity.kt)) : bloque captures d'écran et masque le contenu dans le sélecteur d'apps récentes.
- Permissions Bluetooth retirées (n'étaient pas utilisées).
- `cleartextTrafficPermitted="false"` sauf loopback de dev.

## Backend — exposition publique

Avant d'exposer le proxy sur Internet :

1. Mettre `ALLOWED_ORIGINS` dans `.env` (vide bloque tout cross-origin, sain pour une app mobile native).
2. Servir derrière HTTPS (Caddy, nginx, Cloudflare) — l'app refuse le cleartext en prod.
3. Remplacer le rate-limiter in-memory par **slowapi + Redis** si le service tourne en plusieurs réplicas.
4. Activer la **modération OpenAI** (`/v1/moderations`) sur les entrées et sorties si l'app est ouverte au grand public.
5. Logger les `auth_failed`, `app_check_rejected`, `prompt_injection_blocked`, `rate_limit_hit` vers une plate-forme de monitoring (Datadog, Sentry, ELK).
6. Activer Firebase App Check (voir ci-dessus) pour bloquer les appels hors-APK.

## Langues de réponse (expérimental)

L'app propose 4 langues de réponse, sélectionnables dans Paramètres → Langue de réponse :

| Code | Langue | Statut |
|---|---|---|
| `fr` | Français | Stable, STT/TTS pleinement supportés |
| `dioula` | Dioula (Jula) | Expérimental — qualité dépend de GPT-4o |
| `nouchi` | Nouchi (argot Abidjan) | Expérimental |
| `baoule` | Baoulé | Expérimental |

⚠️ **Limites techniques connues :**
- La reconnaissance vocale (`speech_to_text`) reste en `fr-FR` quelle que soit la langue choisie — les moteurs natifs Android (Google Speech) et iOS (Apple Speech) ne supportent pas ces langues d'Afrique de l'Ouest.
- La synthèse vocale (`flutter_tts`) reste en `fr-FR` pour la même raison. Le TTS lira une réponse Dioula avec une prononciation française, ce qui est inintelligible — d'où l'avertissement explicite dans le sélecteur.
- Seul le **texte** de la réponse est dans la langue choisie ; cela reste utile pour les conversations écrites et les copies/partages.

**Améliorations possibles :**
- Remplacer le STT par Whisper API d'OpenAI (proxifié via `/transcribe`) : Whisper supporte mieux les langues sous-représentées que les moteurs natifs.
- Intégrer un TTS adapté (Edge TTS, ElevenLabs avec accent ouest-africain) en tant que fallback pour les langues expérimentales.

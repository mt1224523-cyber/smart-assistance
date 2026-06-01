# Déploiement — Smart Assistance

## Architecture

```
┌────────────┐     HTTPS       ┌──────────────┐    HTTPS    ┌─────────┐
│ App Flutter│ ──────────────► │ Proxy FastAPI│ ──────────► │ OpenAI  │
│  (mobile)  │  X-App-Key      │   (Docker)   │  Bearer key │ + Moder.│
└────────────┘                 └──────────────┘             └─────────┘
```

## Démarrer le proxy en local

```bash
cd server
cp .env.example .env
# éditer .env : renseigner OPENAI_API_KEY et APP_API_KEY au minimum

# Option A : Python natif
pip install -r requirements-dev.txt
uvicorn main:app --reload

# Option B : Docker (recommandé)
docker compose up --build
```

Vérification :
```bash
curl http://localhost:8000/health
# {"status":"ok","version":"1.0.0","uptime_seconds":3}

curl http://localhost:8000/readiness
# {"ready":true,"version":"1.0.0","uptime_seconds":5,"moderation":true,"app_check":false,"sentry":false}
```

## Déploiement rapide sur Render (gratuit, HTTPS auto)

C'est l'approche la plus simple pour mettre le proxy en ligne avec un certificat HTTPS valide. Un fichier [render.yaml](render.yaml) Blueprint est déjà fourni.

### Étapes

1. **Pusher le projet sur GitHub** (privé OK) :
   ```bash
   cd D:/projet/SMART_ASSISTANCE
   git init
   git add .
   git commit -m "Initial commit"
   gh repo create smart-assistance --private --source=. --push
   ```

2. **Créer un compte Render** : https://render.com (Free, signup avec GitHub recommandé).

3. **New → Blueprint** dans le dashboard Render :
   - Sélectionner votre repo GitHub.
   - Render détecte [render.yaml](render.yaml) et propose `smart-assistance-proxy` (plan Free, region Frankfurt).
   - Cliquer **Apply**.

4. **Renseigner `OPENAI_API_KEY`** quand Render le demande (variable marquée `sync: false` dans le YAML).
   `APP_API_KEY` est généré automatiquement par Render — **copiez sa valeur** depuis le dashboard, vous en aurez besoin pour l'app.

5. **Attendre le build** (~3-5 min). L'URL finale ressemble à `https://smart-assistance-proxy.onrender.com`.

6. **Vérifier** :
   ```bash
   curl https://smart-assistance-proxy.onrender.com/health
   # {"status":"ok","version":"1.0.0","uptime_seconds":12}
   ```

7. **Mettre à jour `smart_assistance/env.json`** :
   ```json
   {
     "PROXY_BASE_URL": "https://smart-assistance-proxy.onrender.com",
     "APP_API_KEY": "valeur-generee-par-render",
     "SENTRY_DSN": "",
     "SENTRY_ENVIRONMENT": "production"
   }
   ```

8. **Rebuilder l'APK** :
   ```bash
   cd smart_assistance
   flutter build apk --release --dart-define-from-file=env.json
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

### Limites du plan Free Render

- **Spin-down après 15 min d'inactivité** : le premier appel suivant prend 30-60 s pendant que le conteneur redémarre. L'app a un timeout de 120 s donc ça passe, mais l'UX est mauvaise.
- **750 h/mois** : un seul service tournant 24/7 est OK.
- **Pas de RAM/CPU garantis** : performances variables.

Pour la prod publique : passer au plan Starter ($7/mois) qui supprime le spin-down.

### Alternatives équivalentes

- **Fly.io** : plus puissant, free tier en évolution. Utiliser `fly launch` depuis `./server/`.
- **Railway** : ergonomique mais plus de free tier permanent depuis 2023.
- **VPS** (Hetzner, OVH) : ~5 €/mois, contrôle total, Docker Compose direct.

---

## Déploiement production du proxy

### 1. Image Docker

L'image est multi-stage, non-root (UID 10001), avec un healthcheck intégré et un système de fichiers en lecture seule (configuré dans `docker-compose.yml`).

```bash
docker build -t registry.exemple.ci/smart-assistance-proxy:1.0.0 ./server
docker push registry.exemple.ci/smart-assistance-proxy:1.0.0
```

### 2. Variables d'environnement obligatoires

| Variable | Description |
|---|---|
| `OPENAI_API_KEY` | Clé OpenAI (jamais committée) |
| `APP_API_KEY` | Token partagé exigé du client mobile |
| `ALLOWED_ORIGINS` | (Si web) origines CORS autorisées, séparées par virgule |

Optionnelles : `OPENAI_MODEL`, `MAX_TOKENS`, `RATE_LIMIT_PER_MIN`, `MODERATION_ENABLED`, `FIREBASE_PROJECT_ID`, `SENTRY_DSN`, `APP_VERSION`.

### 3. Reverse proxy HTTPS

Placer le conteneur derrière nginx, Caddy ou Cloudflare. L'app refuse le cleartext en production via `network_security_config.xml`.

Exemple Caddy (`Caddyfile`) :
```
api.smart-assistance.ci {
    reverse_proxy 127.0.0.1:8000
    encode gzip
    header {
        Strict-Transport-Security "max-age=63072000; includeSubDomains"
    }
}
```

### 4. Healthchecks pour Kubernetes / orchestrateur

- **Liveness** : `GET /health` — répond immédiatement, ne dépend d'aucune ressource externe.
- **Readiness** : `GET /readiness` — vérifie que la config minimale est présente. Renvoie `503` sinon.

Exemple manifest Kubernetes :
```yaml
livenessProbe:
  httpGet: { path: /health, port: 8000 }
  periodSeconds: 30
readinessProbe:
  httpGet: { path: /readiness, port: 8000 }
  periodSeconds: 10
```

## Activer Sentry (crash reporting)

### Côté serveur

1. Créer un projet "FastAPI" dans Sentry.
2. Copier le DSN dans `.env` :
   ```
   SENTRY_DSN=https://xxx@oXXX.ingest.sentry.io/YYY
   SENTRY_ENVIRONMENT=production
   SENTRY_TRACES_SAMPLE_RATE=0.1
   ```
3. Redémarrer le conteneur. `/readiness` doit renvoyer `"sentry": true`.

### Côté Flutter

1. Créer un second projet "Flutter" dans Sentry.
2. Ajouter le DSN au build :
   ```bash
   flutter build apk --release \
     --dart-define-from-file=env.json \
     --dart-define=SENTRY_DSN=https://yyy@oXXX.ingest.sentry.io/ZZZ \
     --dart-define=SENTRY_ENVIRONMENT=production \
     --obfuscate \
     --split-debug-info=build/symbols
   ```
3. Uploader les symboles pour des stack traces lisibles :
   ```bash
   dart pub global activate sentry_dart_plugin
   sentry-cli debug-files upload --include-sources build/symbols
   ```

Tant que `SENTRY_DSN` est vide, le SDK n'est pas initialisé — aucune donnée ne quitte l'app/serveur.

## CI/CD

Deux workflows GitHub Actions sont configurés :

- [`.github/workflows/server.yml`](.github/workflows/server.yml) : lint Ruff + pytest + build d'image Docker (sans push).
- [`.github/workflows/flutter.yml`](.github/workflows/flutter.yml) : `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test --coverage`, build APK debug.

Pour publier l'image vers un registry sur tag :
1. Ajouter un secret `DOCKER_TOKEN` dans GitHub Settings.
2. Étendre `server.yml` avec un job `docker-publish` conditionné à `startsWith(github.ref, 'refs/tags/v')`.

Pour signer l'APK en CI :
1. Stocker la keystore en base64 dans le secret `ANDROID_KEYSTORE`, et les mots de passe dans `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.
2. Décoder dans le job avant le build release.

## Procédure de release

1. Bumper `version:` dans `smart_assistance/pubspec.yaml` et `APP_VERSION` dans `server/.env`.
2. Tag git `vX.Y.Z`.
3. La CI build l'APK debug ; déclencher manuellement le build release signé.
4. Releaser l'image Docker `:X.Y.Z` (et `:latest`).
5. Déployer le proxy avant de publier l'APK (compatibilité ascendante).

## Surveillance recommandée

| Signal | Source | Seuil d'alerte |
|---|---|---|
| `auth_failed` / minute | logs proxy | > 10/min |
| `prompt_injection_blocked` / minute | logs proxy | > 5/min |
| `moderation_blocked` / minute | logs proxy | > 5/min |
| `rate_limit_hit` / minute | logs proxy | > 50/min |
| Latence `/chat` P95 | métriques | > 10 s |
| 5xx OpenAI | logs `openai_status` | > 1% |
| Crashes Flutter | Sentry | tout nouveau crash |

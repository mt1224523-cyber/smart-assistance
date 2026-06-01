# Assistant Intelligent Local - Spécifications Techniques

## 1. Aperçu du Projet

**Nom du projet:** Assistant Intelligent Local (Smart Assistance)  
**Type:** Application mobile Flutter (Android/iOS)  
**Résumé:** Application d'assistant vocal intelligent avec IA, adaptée au contexte ivoirien. Les utilisateurs peuvent poser des questions oralement et recevoir des réponses audio et textuelles adaptées au contexte local (Côte d'Ivoire/Afrique de l'Ouest).  
**Utilisateurs cibles:** Populations Ivory coast avec barrière de l'alphabétisation, entrepreneurs, étudiants, professionnels

---

## 2. Spécifications UI/UX

### Structure de Navigation

- **Navigation principale:** Bottom Navigation Bar avec 3 onglets
  - Assistant (page principale)
  - Historique
  - Paramètres

### Écrans

#### Écran Principal (Assistant)
- En-tête avec logo et titre "Assistant Intelligent"
- Zone de conversation (ListView scrollable)
  - Bulles de dialogue utilisateur (alignées à droite, couleur primaire)
  - Bulles de réponse IA (alignées à gauche, couleur grise)
- Indicateur de reconnaissance vocale (animation pulse quand actif)
- Bouton Microflotant (FAB) en bas à droite
- Zone de suggestions rapides en bas (chips cliquables)

#### Écran Historique
- Liste des questions passées avec date
- Possibilité de rejouer la réponse audio
- Suppression d'éléments

#### Écran Paramètres
- Toggle TTS (Lecture audio des réponses)
- Toggle STT (Reconnaissance vocale)
- Sélection langue interface (Français)
- Version app
- À propos

### Design Visuel

**Palette de couleurs:**
- Primaire: #FF6F00 (Orange - couleur locale Côte d'Ivoire)
- Secondaire: #1E88E5 (Bleu)
- Accent: #43A047 (Vert - succès/prosérité)
- Fond: #FAFAFA
- Fond carte: #FFFFFF
- Texte principal: #212121
- Texte secondaire: #757575
- Erreur: #D32F2F

**Typographie:**
- Police principale: Roboto
- Titre: 24sp Bold
- Sous-titre: 18sp Medium
- Corps: 16sp Regular
- Légende: 14sp Regular

**Espacement:**
- Marges écran: 16dp
- Padding cartes: 16dp
- Espacement entre messages: 12dp
- Radius cartes: 12dp

**Animations:**
- Pulse animation sur bouton micro pendant reconnaissance
- Fade in pour les nouveaux messages
- Slide up pour le clavier

---

## 3. Spécifications Fonctionnelles

### Fonctionnalités Core

#### 3.1 Reconnaissance Vocale (STT)
- API: flutter_speech_to_text ou speech_to_text
- Langue: Français (fr-FR)
- Activation: Appui long ou simple sur bouton micro
- Feedback visuel: Animation pulse + texte "Écoute en cours..."
- Timeout: 30 secondes max
- Gestion erreurs: Affichage message si pas de reconnaissance

#### 3.2 Traitement IA
- API: OpenAI GPT-4 ou GPT-3.5 Turbo
- Endpoint: /v1/chat/completions
- Prompt système: Configuré pour contexte ivoirien
- Contexte: Questions sur business, santé, agriculture, vie quotidienne Côte d'Ivoire
- Limite: 500 tokens max pour réponse

#### 3.3 Synthèse Vocale (TTS)
- API: flutter_tts ou google_speech
- Langue: Français
- Vitesse: 0.5 (lent pour clarté)
- Contrôle: Play/Pause/Stop
- Auto-play optionnel après réponse

#### 3.4 Historique Local
- Stockage: SharedPreferences ou sqflite
- Données sauvegardées:
  - Question (texte)
  - Réponse (texte)
  - Date/heure
  - Audio sauvegardé (optionnel)

#### 3.5 Mode Suggestions
- Catégories:
  - Business & Entrepreneuriat
  - Santé & Médecine
  - Agriculture
  - Vie quotidienne
- Suggestions populaires configurables

### Flux Utilisateur

```
1. Ouverture app → Écran Assistant
2. Appui sur micro → Démarrage reconnaissance vocale
3. Utilisateur parle → Conversion texte
4. Envoi question → Appel API IA
5. Réception réponse → Affichage texte + lecture audio
6. Sauvegarde → Ajout à l'historique
```

### Gestion des Erreurs

- Pas de connexion internet: Message "Vérifiez votre connexion"
- API IA unavailable: Message d'erreur avec retry
- Reconnaissance échouée: "Je n'ai pas compris, réessayez"
- Timeout: Message après 30s sans réponse

---

## 4. Spécifications Techniques

### Architecture

**Pattern:** Clean Architecture avec Provider
- **Data Layer:** Repositories, API clients, Local storage
- **Domain Layer:** Use cases, Entities
- **Presentation Layer:** Screens, Widgets, Providers

### Dépendances Pub

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  speech_to_text: ^6.16.0
  flutter_tts: ^4.0.2
  http: ^1.2.0
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  uuid: ^4.3.3
  permission_handler: ^11.3.0
```

### Modèles de Données

```dart
// Message
class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
}

// MessageStatus enum
enum MessageStatus { sending, received, error }

// Conversation
class Conversation {
  final String id;
  final List<Message> messages;
  final DateTime createdAt;
}

// Suggestion
class Suggestion {
  final String text;
  final String category;
  final IconData icon;
}
```

### Configuration API

```dart
// Clés à configurer (à remplacer par les vraies)
const String openAIApiKey = 'VOTRE_CLE_API';
const String openAIEndpoint = 'https://api.openai.com/v1/chat/completions';
```

### Permissions Android

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

---

## 5. Livrables MVP

### Phase 1 (Semaine 1-2)
- [x] UI chat avec zone de messages
- [x] Bouton micro flottant
- [x] Navigation bottom bar
- [x] Écran paramètres basiques

### Phase 2 (Semaine 3-4)
- [ ] Intégration speech-to-text
- [ ] Intégration text-to-speech
- [ ] Appels API IA fonctionnels
- [ ] Sauvegarde historique local

### Phase 3 (Semaine 5-6)
- [ ] Suggestions rapides
- [ ] Tests utilisateurs
- [ ] Bug fixes
- [ ] Build APK debug

---

## 6. Notes Implémentation

### Optimisations
- Debounce sur les requêtes API
- Cache des réponses fréquentes
- Mode offline partiel pour suggestions

### Sécurité
- Clés API en environment variables
- Pas de stockage de données sensibles
- Validation des entrées utilisateur

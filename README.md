# 🌿 Lumad Lingua: Sentiment-Driven Cultural Vitality & Language Revitalization Platform

[![Flutter](https://img.shields.io/badge/Flutter-%5E3.5.0-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.5.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Supabase](https://img.shields.io/badge/Supabase-Storage-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)

**Lumad Lingua** is a mobile platform designed for the revitalization, digital vitality monitoring, and interactive learning of the **Mansaka** indigenous language and heritage. 

By combining sentiment analysis algorithms, gamified interactive learning, audio waveform comparison, multi-role management portals, and edge-offline synchronization, Lumad Lingua bridges ancestral wisdom with modern mobile software architecture to ensure the long-term survival and celebration of indigenous voices.

---

## ✨ Core Features

### 📊 Sentiment-Driven Vitality Dashboard
* **Vitality Monitor**: Real-time monitoring of Mansaka language usage and sentiment distributions (Positive, Neutral, Negative) computed via multi-model machine learning (Naïve Bayes, SVM, BiLSTM).
* **Social Analytics & Visualizations**: Interactive data charts (`fl_chart`) tracking reach, cultural impact index, and temporal sentiment trends across digital archives.

### 🎓 Interactive Learning & Wisdom Progression
* **Structured Mansaka Curriculum**: Unit and level-based lessons featuring dynamic task types: Multiple Choice, Listening, Sentence Reordering, Matching, Pronunciation (Audio Recording), Vocabulary, Scenarios, Word Hunt, True/False, and Fill in the Blanks.
* **Leitner Spaced Repetition System (SRS)**: Smart flashcard reviews that calculate interval scheduling for optimal vocabulary retention.
* **Lingua Duels (Real-time PvP)**: Compete against peers in timed language battles with live scoring, combo multipliers, and streak mechanics.
* **Branching Cultural Scenarios**: Decision-tree storytelling nodes that reward XP based on contextual language choices.
* **Daily Quests & Streak History**: Dynamic daily challenges, quest rewards, and streak tracking to maximize daily learner retention.

### 📖 Ancestral Dictionary & Pronunciation Analysis
* **Mansaka Dictionary**: Searchable lexicon with part-of-speech tags, dialect indicators, contributor attributions, and audio samples.
* **Audio Comparison & Waveform Evaluation**: MFCC feature extraction and waveform rendering (`audio_waveforms`) allowing learners to record their voice and compare pronunciation against native speakers.
* **Voice Submissions**: Community voice recording workflow for contributors, community members, and language elders.

### 🏆 Gamification & Heritage Vault
* **Warriors' Circle (Leaderboards)**: Global, regional, and dialect-specific leaderboards with real-time ranking.
* **Achievements & Wisdom Ranks**: Earn badges, unlock cultural titles, and level up from novice to "Elder" status.
* **Ancestral Vault Shop**: In-app rewards store where learners exchange earned XP for custom app themes, avatar customization, and title badges.
* **Artifact Gallery & Archive Map**: Geotagged heritage sites, interactive artifact cards, and cultural archive maps.

### 👨‍🏫 Multi-Role Ecosystem & Management
* **Learner Portal**: Personal learning statistics, wisdom progression trees, and offline content management.
* **Staff & Researcher Portal**: Integrated console for community researchers and staff to perform content moderation, validate submissions, and manage cultural archives without administrative bottlenecks.
* **Educator Console**:
  * Classroom management and individual student performance tracking.
  * Lesson/Unit authoring and dynamic feedback delivery.
  * Broadcast history and announcement dispatching.
* **Admin Console**:
  * Multi-tab management for Dictionary, Voice Submissions, Lessons, Cultural Scenarios, and Audit Logs.
  * Bulk actions (bulk selection & delete) protected by administrator security re-authentication.
  * System actions: Dialect settings toggles, CSV/JSON data export, and cache management.

### 📶 Offline Wisdom & Edge Synchronization
* **Hive Caching**: Offline-first storage for lessons, flashcards, dictionary entries, and user profiles.
* **Upload Queue Service**: Seamless background queue that automatically syncs offline voice submissions, lesson completions, and progress when connectivity returns.

### 🎨 Indigenous Lumad Design System
* **Authentic Visual Language**: Custom color palettes inspired by Lumad heritage (**Gold**, **Deep Forest Green**, and **Warm Cream**).
* **Immersive UI/UX**: Custom canvas painters, edge-to-edge layout, responsive text scaling, dark/light theme toggle, and smooth physics-based animations (`flutter_animate`, `rive`, `lottie`).

---

## 🛠️ Tech Stack & Dependencies

| Category | Technology / Package |
| :--- | :--- |
| **Framework & Language** | Flutter SDK (^3.5.0), Dart SDK (^3.5.0) |
| **State Management** | Flutter Riverpod (`flutter_riverpod` ^2.6.1) |
| **Routing** | GoRouter (`go_router` ^17.2.3) |
| **Backend & Authentication**| Firebase Core, Cloud Firestore, Firebase Auth, Firebase Storage, Supabase Storage |
| **Local Storage & Database** | Hive (`hive_flutter` ^1.1.0), Shared Preferences (`shared_preferences`) |
| **Audio & Speech** | Audio Waveforms (`audio_waveforms`), Audioplayers (`audioplayers`), Record (`record`), Speech to Text (`speech_to_text`), Flutter TTS (`flutter_tts`) |
| **Charts & Graphics** | FL Chart (`fl_chart`), Rive (`rive`), Lottie (`lottie`), Flutter Animate (`flutter_animate`), Confetti (`confetti`) |
| **Location & Maps** | Geolocator (`geolocator`), Geocoding (`geocoding`) |
| **Notifications & Sharing** | Flutter Local Notifications (`flutter_local_notifications`), Share Plus (`share_plus`) |
| **Exports & Utilities** | CSV (`csv`), PDF (`pdf`), Intl (`intl`), Flutter Dotenv (`flutter_dotenv`) |

---

## 📂 Architecture & Directory Structure

The project follows a modular, layer-first architecture powered by Riverpod state providers:

```text
lib/
├── config/             # App routing (go_router), global constants, system UI setup
├── data/               # Static seed data, fallback dictionary entries, and lesson templates
├── models/             # Data models & JSON/Hive serialization (Lesson, UserProfile, SRS, etc.)
├── providers/          # Riverpod state providers, stream controllers, and state management
├── screens/            # Application UI screens organized by domain:
│   ├── admin/          # Admin console, user management, audit logs, analytics
│   ├── educator_*.dart # Educator dashboards, student management, lesson editor
│   ├── learner_*.dart  # Learning hub, lesson session, quiz, Lingua Duel, flashcards
│   └── ...             # Auth, settings, gallery, profile, and sentiment screens
├── services/           # Core business logic services:
│   ├── auth_service.dart          # Authentication & security verification
│   ├── firebase_service.dart      # Firestore database operations & queries
│   ├── srs_service.dart           # Leitner Spaced Repetition logic
│   ├── mfcc_service.dart          # Audio waveform & pitch feature extraction
│   ├── offline_service.dart       # Hive caching & offline state manager
│   ├── upload_queue_service.dart  # Offline-to-online data sync queue
│   ├── sentiment_service.dart     # Language sentiment & vitality computation
│   └── notification_service.dart  # Local notification scheduler
├── theme/              # Lumad design tokens (AppColors, AppTypography, AppTheme)
├── utils/              # Helper utilities, date formatters, math utilities
└── widgets/            # Reusable brand components (BrandCard, BrandButton, Badges, etc.)
```

---

## 🚀 Getting Started

### Prerequisites
* **Flutter SDK**: `>=3.5.0` ([Install Flutter](https://docs.flutter.dev/get-started/install))
* **Dart SDK**: `>=3.5.0`
* **Android Studio / VS Code** with Flutter and Dart extensions.
* **Firebase Project**: Configured for Android/iOS with Firestore, Authentication, and Storage enabled.
* **Supabase Account**: Configured for audio file storage.

### Environment Configuration
Create a `.env` file in the project root directory with the following keys:

```env
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/marvinkentumando/lumad-lingua-flutter.git
   cd "lumad-lingua-flutter"
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Hive Adapters & Models** *(if modifying models)*:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Code Quality

Run tests and linter checks using:

```bash
# Run unit & widget tests
flutter test

# Run code analysis
flutter analyze
```

---

## 📜 Cultural Preservation Statement

This application is dedicated to the **Mansaka community** and all indigenous peoples of Mindanao, Philippines. All language data, cultural stories, and audio recordings are handled with the utmost respect for indigenous cultural intellectual property rights. The goal of **Lumad Lingua** is to support language transmission, celebrate cultural identity, and empower future generations through accessible mobile technology.

---

Developed with ❤️ by **The Lumad Lingua Team**.

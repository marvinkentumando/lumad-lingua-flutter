# 🌿 KNOWLEDGE.md — Lumad Lingua Domain & Technical Knowledge Base

## Project Overview
**Lumad Lingua** is a mobile platform built with Flutter for the preservation, digital vitality monitoring, and interactive learning of the **Mansaka** indigenous language in Mindanao, Philippines.

## Tech Stack Overview
- **UI Framework**: Flutter SDK (^3.5.0), Dart SDK (^3.5.0)
- **State Management**: Flutter Riverpod (`flutter_riverpod` ^2.6.1)
- **Routing**: GoRouter (`go_router`)
- **Backend Services**: Firebase Core, Cloud Firestore, Firebase Auth, Firebase Storage, Supabase Storage
- **Local Persistence**: Hive (`hive_flutter`), Shared Preferences
- **Audio Processing**: `audio_waveforms`, `audioplayers`, `record`, `flutter_tts`
- **Animations & Visuals**: `flutter_animate`, `rive`, `lottie`, `confetti`, `fl_chart`
- **Utilities**: `intl`, `share_plus`, `connectivity_plus`

## Core Services & Architecture
1. **`AuthService` (`lib/services/auth_service.dart`)**:
   Firebase Authentication with email/password and Google Sign-In, multi-role user profile creation (`learner`, `educator`, `admin`, `validator`).
2. **`FirebaseService` (`lib/services/firebase_service.dart`)**:
   Cloud Firestore transaction and stream management for lessons, dictionary entries, user XP, mist crystals, community feed, and artifact purchases.
3. **`OfflineService` (`lib/services/offline_service.dart`)**:
   Hive persistence management across key boxes (`offline_lessons`, `offline_dictionary`, `offline_artifacts`, `draft_lessons`, `search_history`, `offline_progress`).
4. **`UploadQueueService` (`lib/services/upload_queue_service.dart`)**:
   Background upload queue monitoring network changes via `connectivity_plus` to sync offline lesson drafts and progress entries.
5. **`SRSService` (`lib/services/srs_service.dart`)**:
   Leitner Spaced Repetition System logic calculating review interval scheduling (1, 3, 7, 14, 30 days) and tracking mastery levels across vocabulary.
6. **`MFCCService` & `PronunciationService` (`lib/services/mfcc_service.dart`, `lib/services/pronunciation_service.dart`)**:
   Mel-Frequency Cepstral Coefficients feature extraction, noise gate preprocessing, RMS volume normalization, and DTW / HMM / Cosine speech similarity evaluation.
7. **`SentimentService` (`lib/services/sentiment_service.dart`)**:
   Multi-model text sentiment classification using Naïve Bayes, Support Vector Machines (SVM), and Bidirectional LSTM (BiLSTM).

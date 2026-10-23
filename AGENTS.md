# 🌿 AGENTS.md — AI Agent Guidance for Lumad Lingua

This document serves as the authoritative guide for AI developer agents (Claude, Copilot, Codex, Cursor, etc.) working on the **Lumad Lingua** Flutter application codebase.

---

## 📌 Project Overview

**Lumad Lingua** is a mobile application dedicated to the digital preservation, interactive revitalization, and cultural vitality monitoring of the **Mansaka** indigenous language and Lumad heritage in Mindanao, Philippines.

- **Primary Repository**: `lumad-lingua-flutter`
- **Framework**: Flutter SDK (`^3.5.0`), Dart SDK (`^3.5.0`)
- **Architecture**: Riverpod-based layer-first modular architecture
- **Design Tokens**: Indigenous Lumad palette — **Gold** (`AppColors.gold500`), **Deep Forest Green** (`AppColors.forest900`), **Warm Cream** (`AppColors.creamBg`).

---

## 🛠️ Essential Development Commands

| Task | Command |
| :--- | :--- |
| **Install Dependencies** | `flutter pub get` |
| **Build Code Generation** (Hive Adapters / Models) | `flutter pub run build_runner build --delete-conflicting-outputs` |
| **Run Static Code Analysis** | `flutter analyze` |
| **Run Unit & Widget Tests** | `flutter test` |
| **Run Targeted Single Test** | `flutter test test/password_validator_test.dart` |
| **Run Application** | `flutter run` |

---

## 📂 Architecture & Directory Structure

```text
lib/
├── config/             # GoRouter routes, app initialization, system UI setup
├── data/               # Static fallback data, seed dictionary entries, seed lessons
├── models/             # Data models & Hive serialization (Lesson, UserProfile, SRS, Artifact, etc.)
├── providers/          # Riverpod state providers, stream controllers, and state management
├── screens/            # Application screens organized by domain:
│   ├── admin/          # Admin console, user management, audit logs, analytics
│   ├── profile/        # Role-based profile management
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── dashboard_screen.dart
│   ├── lesson_session_screen.dart
│   ├── lingua_duel_screen.dart
│   ├── audio_comparison_screen.dart
│   └── ...
├── services/           # Core business logic services:
│   ├── auth_service.dart          # Firebase Auth, role claims, password resets
│   ├── firebase_service.dart      # Cloud Firestore CRUD transactions & streams
│   ├── offline_service.dart       # Hive box persistence (lessons, dictionary, progress)
│   ├── upload_queue_service.dart  # Offline-to-online upload queue process
│   ├── srs_service.dart           # Leitner Spaced Repetition System logic
│   ├── mfcc_service.dart          # Audio spectral feature extraction & DTW scoring
│   ├── pronunciation_service.dart # Waveform comparison & evaluation algorithms
│   ├── sentiment_service.dart     # Multi-model sentiment classification (Naïve Bayes, SVM, BiLSTM)
│   └── audio_service.dart         # Audio recording & playback manager
├── theme/              # Lumad design tokens (AppColors, AppTypography, AppTheme)
├── utils/              # AppLocalization (Multi-language EN, TL, BIS), formatters, helpers
└── widgets/            # Reusable components (BrandCard, BrandButton, BrandTextField, ParallaxBackground)
```

---

## 🎨 UI/UX & Coding Conventions

1. **Design System & Components**:
   - Always use branded design widgets (`BrandCard`, `BrandButton`, `BrandTextField`, `ParallaxBackground`, `TopoBackground`).
   - Use `AppColors` for all styling (`AppColors.gold500`, `AppColors.forest900`, `AppColors.creamBg`, `AppColors.semanticRed`, `AppColors.semanticGreen`). Avoid hardcoded color hexes.

2. **Localization (`AppLocalization`)**:
   - All user-facing text **must** be retrieved via `ref.watch(localizationProvider).translate('key_name')` or `l10n.translate('key_name')`.
   - Ensure keys exist across all three supported locales: **English (`en`)**, **Tagalog/Filipino (`tl`)**, and **Bisaya (`bis`)** in `lib/utils/app_localization.dart`.

3. **Error Handling & Auth Messages**:
   - Never display raw technical exceptions (e.g. `e.toString()`) to users.
   - Always route authentication errors through `l10n.getAuthErrorMessage(e)`.

4. **Input Ergonomics & Autofill**:
   - Wrap authentication and multi-field forms in `AutofillGroup`.
   - Provide appropriate `autofillHints` (e.g. `[AutofillHints.email]`, `[AutofillHints.password]`).
   - Set keyboard actions (`textInputAction: TextInputAction.next` / `TextInputAction.done`).
   - Use `FocusNode` focus-change listeners to prevent showing error messages while the user is actively typing for the first time.

5. **System Back Navigation**:
   - Wrap multi-step flow screens (such as `SignupScreen`) in `PopScope` to gracefully handle Android physical back button presses step-by-step (`_prevStep()`) before popping the route.

6. **Offline First & Low-Connectivity**:
   - Bundle static graphic assets and logos locally in `assets/images/` rather than relying on remote network images (`Image.network`).

---

## 🔒 Important Caveats & Guidelines

- **Zero Shell Edits**: Never use shell scripts (`sed`, `perl`) to modify project files. Use IDE/buffer file manipulation tools (`replace_file_content`, `write_file`).
- **Code Generation**: If modifying models annotated with `@HiveType` or `@HiveField`, run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate serialization adapters (`.g.dart` files).
- **Riverpod Providers**: Watch providers using `ref.watch` inside `build()` and read providers using `ref.read` inside callbacks or async event handlers.

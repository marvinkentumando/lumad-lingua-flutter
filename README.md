# 🌿 Lumad Lingua

**Lumad Lingua** is a premium, high-fidelity mobile platform dedicated to the preservation, revitalization, and celebration of the indigenous languages and cultures of the Lumad people in Mindanao, Philippines.

Built with Flutter and powered by Firebase, this application offers a rich, interactive learning experience that bridges ancestral wisdom with modern technology.

---

## ✨ Core Features

### 🎓 Interactive Learning Hub
*   **Structured Lessons**: Comprehensive curriculum covering Mansaka, Mandaya, Manobo, Bagobo, and Kagan, etc.
*   **Intelligent Review**: Leitner-based Spaced Repetition System (SRS) to optimize vocabulary retention.
*   **Gamified Progress**: Earn XP, maintain streaks, and unlock "Elder" ranks as you master new dialects.

### 📖 Ancestral Dictionary & Archive
*   **Multi-Dialect Support**: Unified search across multiple indigenous languages.
*   **Geo-Spatial Mapping**: Interactive map showcasing geo-tagged linguistic documentation and cultural sites.
*   **Audio Pronunciation**: Real-world voice submissions for authentic phonetic learning.
*   **Contribution Pipeline**: Community-driven content where users can submit new terms and recordings.

### 🛡️ Secure Admin & Validation
*   **Expert Validation**: Structured workflow for linguistic experts to verify accuracy before content is published.
*   **Content Moderation**: Robust auditing tools for Dictionary, Recordings, and Lessons.
*   **Identity Verification**: Secure, role-based access control integrated with Firebase Auth.

### 👤 Sacred Profile & Impact
*   **Cultural Impact Tracking**: Visualize your contribution to language preservation.
*   **Achievements**: Earn badges and crystal rewards for consistent learning.
*   **Haptic Feedback**: Immersive sensory experience using advanced haptics and sensors.

---

## 🚀 Tech Stack

*   **Frontend**: Flutter (SDK ^3.5.0)
*   **State Management**: Riverpod (with Stream/Future providers)
*   **Backend**: Firebase (Auth, Cloud Firestore, Firebase Storage) & Supabase Storage.
*   **Mapping**: Flutter Map & Geolocator.
*   **Navigation**: GoRouter
*   **Animations**: Rive, Lottie, Flutter Animate, and Custom Canvas Painters.
*   **Local Storage**: Hive & Shared Preferences.
*   **Media**: Audio Waveforms, Audioplayers, and Pronunciation Assessment (DTW).

---

## 🛠️ Architecture

The project follows a modular, provider-driven architecture:

```text
lib/
├── config/       # Role-based navigation and app constants
├── models/       # Data structures and JSON serialization
├── providers/    # Riverpod state management & business logic
├── screens/      # Feature-specific UI components
├── services/     # Firebase, Storage, Haptics, and SRS services
├── theme/        # Design system (Gold/Forest/Cream palettes)
├── utils/        # Helper functions and formatting utilities
└── widgets/      # Reusable UI components (BrandCard, BrandButton, etc.)
```

---

## 🏁 Getting Started

### Prerequisites
*   Flutter SDK (^3.5.0)
*   Firebase Project (Web/Android/iOS configurations)
*   `.env` file for API keys and environment variables

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/marvinkentumando/lumad-lingua-flutter.git
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Generate Hive adapters (if applicable):
    ```bash
    flutter pub run build_runner build
    ```
4.  Run the application:
    ```bash
    flutter run
    ```

---

## 📜 Cultural Note
This project is developed with deep respect for the Lumad communities. All content is intended to support the empowerment of indigenous voices and the continuity of their rich linguistic heritage.

---

Developed by The Lumad Lingua Team.

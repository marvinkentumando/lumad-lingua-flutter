# 🌿 Lumad Lingua: Sentiment-Driven Cultural Vitality Monitor

**Lumad Lingua** is a premium mobile platform focused on the **Digital Vitality** of the Mansaka language. Pivoting from manual documentation to automated sentiment monitoring, the application tracks the health of the Mansaka culture through social media trends while providing a robust environment for interactive learning.

Built with Flutter and powered by Firebase, this application bridges ancestral wisdom with modern sentiment analysis to ensure the digital survival of indigenous voices.

---

## ✨ Core Features

### 📊 Sentiment-Driven Vitality Dashboard
*   **Vitality Monitor**: Real-time tracking of Mansaka language usage and sentiment (Positive, Neutral, Negative) across digital spaces.
*   **Social Analytics**: Monitor social reach and "Digital Vitality Index" to visualize cultural health beyond manual field documentation.

### 🎓 Interactive Learning Hub
*   **Mansaka Curriculum**: Structured lessons focused exclusively on the Mansaka dialect to ensure depth of linguistic preservation.
*   **Intelligent Review**: Leitner-based Spaced Repetition System (SRS) to optimize vocabulary retention.
*   **Gamified Progress**: Earn XP, maintain streaks, and unlock "Elder" ranks as you master the language.

### 📖 Ancestral Dictionary & Audio
*   **Mansaka Dictionary**: A standalone module for search and discovery of Mansaka terms.
*   **Audio Comparison**: Master pronunciations by comparing your voice with native speaker recordings using advanced waveform analysis.
*   **Shadowing Rituals**: Practice the "Saka" (ascent) through rhythmic audio practice.

### 🛡️ Researcher & Staff Console
*   **Consolidated Workflow**: Merged Researcher/Staff roles with direct database access for efficient content management.
*   **Content Moderation**: Centralized tools for Dictionary, Recordings, and Lesson management without administrative bottlenecks.

---

## 🚀 Tech Stack

*   **Frontend**: Flutter (SDK ^3.5.0)
*   **State Management**: Riverpod (with Stream/Future providers)
*   **Backend**: Firebase (Auth, Cloud Firestore, Firebase Storage) & Supabase Storage.
*   **Sentiment Analysis**: Integrated logic for monitoring linguistic vitality trends.
*   **Navigation**: GoRouter
*   **Animations**: Rive, Lottie, Flutter Animate, and Custom Canvas Painters.
*   **Local Storage**: Hive & Shared Preferences.
*   **Media**: Audio Waveforms, Audioplayers, and Pronunciation Comparison.

---

## 🛠️ Architecture

The project follows a modular, provider-driven architecture:

```text
lib/
├── config/       # Role-based navigation and app constants
├── models/       # Data structures and JSON serialization
├── providers/    # Riverpod state management & business logic
├── screens/      # Feature-specific UI components
├── services/     # Firebase, Storage, Sentiment, and SRS services
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
This project is developed with deep respect for the Mansaka community. All content is intended to support the empowerment of indigenous voices and the continuity of their rich linguistic heritage in the digital age.

---

Developed by The Lumad Lingua Team.

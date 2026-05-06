# Lumad Lingua - System Architecture

## 🏗️ Architectural Overview
Lumad Lingua follows a modernized, layered Flutter architecture leveraging **Riverpod** for reactive state management and **Firebase** for backend services. The architecture is designed to be highly modular, supporting offline capabilities and complex learning logic (Spaced Repetition System - SRS).

## 📂 Project Structure
The `lib` directory is organized by technical domain, ensuring a clear separation of concerns:

- `config/`: Application-wide configuration and constants.
- `data/`: Local data management, persistence implementations, and Hive integration.
- `models/`: Immutable data transfer objects (DTOs) and domain models (e.g., User, Lesson, Word).
- `providers/`: Riverpod providers managing application state and business logic.
- `screens/`: Top-level UI views and routing destinations.
- `services/`: Singleton-like classes handling external APIs, Firebase, and device hardware features.
- `theme/`: Design system, typography, and cultural theme definitions.
- `utils/`: Helper functions, formatters, and extensions.
- `widgets/`: Reusable UI components (buttons, cards, dialogs).

## 🧩 Core Layers

### 1. Presentation Layer (UI)
- **`screens/` & `widgets/`**
- Strictly responsive and stateless where possible.
- Listens to `providers` to rebuild UI reactively based on state changes.
- Contains complex animations, glassmorphism UI, and custom thematic widgets.

### 2. State Management Layer
- **`providers/`**
- Uses **Riverpod** (`Notifier`, `AsyncNotifier`, `FutureProvider`).
- Acts as the bridge between UI and Services.
- **Key Providers**:
  - `learning_provider.dart`: Manages active session state, scoring, and progress.
  - `student_provider.dart`: Manages user data, XP, and profile stats.
  - `quest_provider.dart`: Tracks daily/weekly objectives.
  - `contributor_request_provider.dart`: Manages community submissions and role requests.

### 3. Service Layer (Business Logic & Infrastructure)
- **`services/`**
- Encapsulates complex logic and external integrations.
- **Key Services**:
  - `firebase_service.dart`: The primary gateway for Firestore operations, caching, and data fetching.
  - `srs_service.dart`: Implements the Spaced Repetition System (Leitner system) for computing word mastery and review schedules.
  - `audio_service.dart` / `pronunciation_service.dart`: Handles recording, playback, and voice validation/fingerprinting.
  - `offline_service.dart` / `upload_queue_service.dart`: Manages local caching and syncing pending actions when internet connectivity is restored.
  - `haptic_service.dart`: Standardizes tactile feedback across the app.

### 4. Data Layer (Models & Persistence)
- **`models/`**
- Contains strongly-typed representations of Firestore documents using `freezed` or standard Dart data classes.
- **Persistence**: Relies on Firebase offline persistence combined with local Hive boxes for specialized offline data (like upload queues).

## 🔄 Data Flow
1. **User Action**: The user interacts with the UI (e.g., completes a lesson).
2. **Provider Update**: The UI calls a method on a Riverpod Provider (e.g., `ref.read(learningProvider.notifier).completeLesson()`).
3. **Service Execution**: The Provider updates local state optimistically and delegates background processing to a Service (e.g., `firebaseService` to update XP, `srsService` to recalculate next review dates).
4. **UI Reactivity**: The Provider state updates, causing observing widgets to rebuild with the latest data and trigger success animations/haptics.

## 📡 Offline-First & Synchronization Strategy
The app is designed to function smoothly in low-connectivity areas (vital for indigenous regions):
- Reads are cached aggressively using Firestore's built-in persistence.
- Critical writes (like lesson completions or audio submissions) use the `upload_queue_service` if offline. 
- The queue is processed silently in the background once connectivity is re-established, ensuring no progress is lost.

## 🔐 Security & Access Control
- Handled securely via Firestore Security Rules (`firestore.rules`).
- Custom claims or specific role collections dictate whether a user is a standard `Learner`, a `Contributor`, or an `Admin/Validator`.
- Only Validators can approve words, lessons, and contributor requests.

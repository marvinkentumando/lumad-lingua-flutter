# Lumad Lingua - Development TODO & Project Roadmap

## 📌 Recent Completed Tasks
- [x] **Dictionary Screen (Learner View)**:
  - Added Part of Speech badge/tag to entry cards.
  - Added Part of Speech filter chip row (All, Noun, Verb, Adjective, Phrase, etc.).
  - Removed phonetic pronunciation text display from entry cards.
  - Implemented SRS mastery stars and saved words bookmarking system.
  - Implemented Hive offline caching for global dictionary searches and local fallbacks.
- [x] **Text-To-Speech (TTS) Engine**:
  - Implemented native TTS language check prioritizing Cebuano (`ceb-PH`) for phonetic similarity to Mansaka, falling back to Filipino (`fil-PH`).
- [x] **Admin Dictionary Screen**:
  - Streamlined Add/Edit Entry Modal by removing standalone translation fields while preserving example sentence translations.
  - Supported CSV export and import modal for dictionary bulk uploads.
  - Supported native audio recording and file uploads directly from the Admin Entry Form modal.
- [x] **Admin Gamification Screen**:
  - Added `tryParse` number parsing, form validation, non-negative entry checks, and SnackBar feedback for reward XP and shop item price dialogs.
  - Added delete action buttons with confirmation dialogs calling `deleteShopItem`.
  - Added `isAvailable` visibility toggle switch on shop item cards and edit modals.
  - Removed deprecated Seasons and Duels tabs, focusing the UI strictly on REWARDS and SHOP management.
- [x] **Lesson Session Screen**:
  - Fixed "Finish" button dialog bug on session results overlay by dismissing `dialogContext` before navigating with `GoRouter`.
  - Enhanced post-test survey feedback data submission with star ratings and open-text feedback to Firebase.
- [x] **Gamification & Claim Reward Animations**:
  - Created expanded `ClaimRewardModal` featuring cultural sun-ray rotating badge, spirit particle background overlay, animated count-up for Mist Crystals and XP, and haptic/audio feedback.
  - Upgraded `CrystalBurstAnimation` with multi-symbol particles radiating from center.
  - Integrated rich reward claiming dialogs into Tribal Quests (Dashboard), Daily Challenge sessions, and Streak Milestone claims.
- [x] **Notifications & Reminders**:
  - Implemented `NotificationService` for local push notifications using `flutter_local_notifications`.
  - Added daily repeating streak reminders with custom hour/minute settings modal (`StreakReminderSettingsDialog`).
  - Added instant test streak warning notifications.
- [x] **Learner Village Sanctuary & Dashboard**:
  - Added "My Village Sanctuary 🌿" card on Learner Profile Screen when connected to an educator via code.
  - Built dedicated `VillageDashboardScreen` featuring village header, educator info, code copying, total tribe XP, village member count, village broadcast announcements, tribe leaderboard rankings, and leave village confirmation.

---

## 🚀 High & Medium Priority Tasks

### 📚 Dictionary & Vocabulary
- [x] **Part of Speech Filter Chips**: Add Part of Speech filter chip row to Learner Dictionary Screen.
  - 📁 `lib/screens/dictionary_screen.dart`, `lib/providers/dictionary_provider.dart`
- [x] **Admin Native Audio Uploads**: Support native audio file upload directly from Admin Entry Form modal.
  - 📁 `lib/screens/admin_dictionary_screen.dart`, `lib/services/firebase_service.dart`
- [x] **Offline Hive Caching**: Implement Hive offline caching for global dictionary searches.
  - 📁 `lib/services/hive_service.dart`, `lib/providers/dictionary_provider.dart`
- [ ] **Interactive Phonetic Tooltips**: Interactive IPA pronunciation guides with playable audio chips on term details.
  - 📁 `lib/screens/dictionary_screen.dart`
- [ ] **Bulk Audio Import**: Admin utility to match and bulk-upload audio recordings by dictionary term keys.
  - 📁 `lib/screens/admin_dictionary_screen.dart`, `lib/services/firebase_service.dart`

### ⚙️ Admin Gamification & Economics Screen
- [x] **Number Parsing Crash Prevention**: Add `tryParse` or form validation in reward and shop dialogs to prevent crashes when empty or invalid inputs are submitted.
  - 📁 `lib/screens/admin_gamification_screen.dart`
- [x] **Delete Functionality for Shop Items**: Add delete action buttons with confirmation dialogs to shop cards calling `deleteShopItem`.
  - 📁 `lib/screens/admin_gamification_screen.dart`, `lib/services/firebase_service.dart`
- [x] **Shop Item Availability Toggle**: Add an `isAvailable` switch to shop items and dialogs to allow hiding items without deleting them.
  - 📁 `lib/screens/admin_gamification_screen.dart`, `lib/models/gamification_models.dart`
- [ ] **Admin Action Feedback (Snackbars)**: Wrap Firebase operations in try-catch blocks and display `ScaffoldMessenger` SnackBar feedback on success/failure.
  - 📁 `lib/screens/admin_gamification_screen.dart`

### 🎮 Lessons & Learning Session
- [ ] **Audio Recording Evaluation & Pronunciation Preview**: Live waveform visualizer and pronunciation scoring during speaking activities.
  - 📁 `lib/screens/lesson_session_screen.dart`, `lib/widgets/activity_views/speaking_practice_view.dart`, `lib/services/pronunciation_service.dart`
- [x] **Post-Test Survey Data Submission**: Submit post-test survey ratings and feedback directly to Firebase.
  - 📁 `lib/screens/lesson_session_screen.dart`, `lib/services/firebase_service.dart`
- [ ] **Lesson Audio Pre-Caching**: Pre-download all lesson module audio assets into Hive/Cache before starting a session.
  - 📁 `lib/services/audio_service.dart`, `lib/screens/learning_path_screen.dart`, `lib/providers/learning_provider.dart`
- [ ] **Smart SRS Retention Decay Recommendations**: Dashboard card suggesting low-retention vocabulary based on SuperMemo-2 interval calculations.
  - 📁 `lib/services/srs_service.dart`, `lib/screens/mastery_dashboard_screen.dart`

### 🏆 Gamification, Customization & Social
- [x] **Claim Reward Modal & Animations**: Expand Tribal Quests & Daily Challenge claim reward modal and particle effects.
  - 📁 `lib/widgets/claim_reward_modal.dart`, `lib/widgets/crystal_burst_animation.dart`
- [x] **Local Push Notifications**: Implement daily streak reminders with user-scheduled times.
  - 📁 `lib/services/notification_service.dart`, `lib/widgets/streak_reminder_settings_dialog.dart`, `lib/screens/learner_profile_screen.dart`
- [ ] **Avatar Cultural Customization Shop**: Equip and purchase cultural titles, avatar frames, and badges in the Ancestral Vault using Mist Crystals.
  - 📁 `lib/screens/ancestral_vault_shop_screen.dart`, `lib/providers/student_provider.dart`, `lib/models/artifact.dart`
- [ ] **Leaderboard Encouragement "Salutes"**: Send instant tribal cheer toasts ("Salute! 🛡️") to friends on the leaderboard.
  - 📁 `lib/screens/leaderboard_screen.dart`, `lib/services/firebase_service.dart`

### ⚔️ Community & Multiplayer
- [ ] **Lingua Duel Real-Time Sync**: Optimize Firestore state sync and turn timeouts during live multiplayer duels.
  - 📁 `lib/screens/lingua_duel_screen.dart`, `lib/services/duel_service.dart`
- [ ] **Voice Comments in Community Feed**: Allow learners to attach short voice messages to community discussions.
  - 📁 `lib/screens/community_feed_screen.dart`, `lib/services/audio_service.dart`

---

## 🛠 Low Priority, Refactoring & Infrastructure
- [ ] **State Management Offline Sync Refactor**: Smooth state recovery and background queue retry when reconnecting online.
  - 📁 `lib/services/hive_service.dart`, `lib/providers/student_provider.dart`, `lib/providers/learning_provider.dart`
- [ ] **Shimmer Skeleton Loading Optimization**: Optimize shimmer animations for low-end Android mobile devices.
  - 📁 `lib/widgets/shimmer_loading.dart`, `lib/screens/dictionary_screen.dart`, `lib/screens/learning_hub_screen.dart`

---

## 🧪 Testing & Quality Assurance
- [ ] **Core Service Unit Tests**: Unit tests for `AudioService`, `NotificationService`, and `SrsService`.
  - 📁 `test/services/audio_service_test.dart`, `test/services/notification_service_test.dart`
- [ ] **Provider & Widget Tests**: Widget tests for `DictionaryFilterNotifier`, `ClaimRewardModal`, and `StreakReminderSettingsDialog`.
  - 📁 `test/providers/dictionary_filter_notifier_test.dart`, `test/widgets/claim_reward_modal_test.dart`

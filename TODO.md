# Lumad Lingua - Development TODO & Project Roadmap

## 📌 Recent Completed Tasks
- [x] **Bulk Moderation Transactions Read-After-Write Ordering & Parallelization**:
  - Gathered all document snapshots in an initial `Future.wait` batch before applying transaction updates in `bulkApproveWords`, `bulkRejectWords`, `bulkFlagWords`, `bulkApproveLessons`, `bulkRejectVoiceSubmissions`, and `bulkFlagVoiceSubmissions` to satisfy Firestore transaction read-before-write requirements and eliminate concurrency failures.
  - Added idempotent currency and XP transaction operations to prevent double-rewards.
- [x] **Dictionary Screen (Learner View)**:
  - Added Part of Speech badge/tag to entry cards.
  - Added Part of Speech filter chip row (All, Noun, Verb, Adjective, Phrase, etc.).
  - Removed phonetic pronunciation text display from entry cards.
  - Implemented SRS mastery stars and saved words bookmarking system.
  - Implemented Hive offline caching for global dictionary searches and local fallbacks.
  - Implemented smooth infinite scrolling / lazy loading for optimal mobile vocabulary browsing UX.
- [x] **Community Sentiment Dashboard**:
  - Connected `SentimentService` to load pre-analyzed sentiment posts from Firestore (`sentiment_posts`), local JSON asset (`assets/data/sentiment_posts.json`), or custom local storage.
  - Added "Import JSON Dataset" modal on Sentiment Dashboard Screen supporting direct file picking (`.json`) or raw JSON text pasting.
  - Integrated single fine-tuned sentiment engine model pipeline.
- [x] **Text-To-Speech (TTS) Engine**:
  - Implemented native TTS language check prioritizing Cebuano (`ceb-PH`) for phonetic similarity to Mansaka, falling back to Filipino (`fil-PH`).
- [x] **Admin Dictionary Screen**:
  - Streamlined Add/Edit Entry Modal by removing standalone translation fields while preserving example sentence translations.
  - Supported CSV export and import modal for dictionary bulk uploads.
  - Supported native audio recording and file uploads directly from the Admin Entry Form modal.
  - Implemented multi-criteria dictionary sorting menu (Alphabetical A-Z/Z-A, Newest/Oldest, Part of Speech, Has Audio First).
  - Added "Delete All Words" bulk deletion button with safety confirmation dialog and chunked batch removal.
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
  - Added Avatar Cultural Customization Shop in Ancestral Vault.
- [x] **Notifications & Reminders**:
  - Implemented `NotificationService` for local push notifications using `flutter_local_notifications`.
  - Added daily repeating streak reminders with custom hour/minute settings modal (`StreakReminderSettingsDialog`).
  - Added instant test streak warning notifications.
- [x] **Learner Village Sanctuary & Dashboard**:
  - Added "My Village Sanctuary 🌿" card on Learner Profile Screen when connected to an educator via code.
  - Built dedicated `VillageDashboardScreen` featuring village header, educator info, code copying, total tribe XP, village member count, village broadcast announcements, tribe leaderboard rankings, and leave village confirmation.
- [x] **Audio Recording Evaluation & Pronunciation Preview**:
  - Created `SpeakingPracticeView` with native audio listening button, live real-time waveform visualizer using `AudioWaveforms`, recorded user audio playback ("Play My Echo 🎧"), and re-recording controls.
  - Integrated `PronunciationService` AI waveform analysis in `LessonSessionScreen` to calculate accuracy, fluency, clarity, overall score %, and waveform comparison graph.
- [x] **Lesson Audio Pre-Caching**:
  - Pre-downloaded and cached remote task audio assets into local device storage via `DefaultCacheManager` (`flutter_cache_manager`) in `AudioService`.
  - Added cache fallback to `playFromUrl` to play audio directly from cached local disk files.
  - Integrated automatic background pre-caching for active path lessons and pre-caching triggers on lesson card taps in `LearningPathScreen` and `learning_provider`.
- [x] **Haptic Consistency Audit**:
  - Hardened `HapticService` with platform exception safety (`try-catch` wrappers around vibrator/system haptics).
  - Added new semantic feedback methods (`toggle`, `delete`, `warning`, `salute`).
  - Wired `TactileWrapper` to trigger haptic feedback on tap down.
  - Integrated consistent haptics across shop exchanges, reminder toggles, village leave/code copy, duel victory/defeat, leaderboard salutes, and admin item deletions.
  - Created unit test suite `test/services/haptic_service_test.dart` verifying all 17 haptic methods.
- [x] **State Management Offline Sync Refactor**:
  - Added Hive student profile caching and action queueing in `StudentNotifier`.
  - Implemented pending sync action processor, draft lesson publishing, and auto-retry on reconnect in `UploadQueueService`.
  - Added cached progress and lesson fallback logic in `LearningProvider`.
  - Created unit test suite `test/services/offline_sync_test.dart`.
- [x] **Shimmer Skeleton Loading Optimization**:
  - Replaced high-overhead multi-ticker `.animate().shimmer()` with hardware-accelerated `_OptimizedShimmerBox` wrapped in `RepaintBoundary` for zero parent layout repaints.
  - Added specialized `DictionaryCardSkeleton` and `HubCardSkeleton` structured loading components for `DictionaryScreen` and `LearningHubScreen`.
- [x] **Educator Lessons Screen Layout Improvements**:
  - Set List View as the default layout mode.
  - Added explicit meatball action button (`...`) to list cards to trigger the management bottom sheet.
  - Displayed student count badge (`Icons.people_rounded`) alongside view count on list items.
  - Added metadata badge chips (`Language • Level • Unit N`) for quick lesson scope recognition.
  - Added Unit sorting (`LessonSort.unit` / 'By Unit') option to lesson sorting dropdown.
- [x] **Sentence Reordering Duplicate Word Index Conflict Fix**:
  - Added unique `ValueKey` identifiers (`scrambled_${entry.key}_${entry.value}` and `available_${entry.key}_${entry.value}`) to all Draggable chips in `SentenceReorderingView` to prevent Flutter element reconciliation conflicts when sentences contain duplicate words (e.g. "madyaw na madyaw").
  - Hardened `onWordTap` and `onScrambledWordTap` callbacks in `LessonSessionScreen` and `DailyChallengeSessionScreen` with index bounds and exact word checks before removal.
  - Created widget test suite `test/widgets/sentence_reordering_view_test.dart`.
- [x] **Lingua Duel & Multiplayer Optimizations**:
  - Optimized Firestore state sync and turn timeouts during live multiplayer duels.
  - Deployed `duel_matches` Firestore security rules to production.
  - Implemented `DuelService.canClaimMatchData` and security rules check to prevent room joining race conditions.
  - Fixed Leaderboard Salute build error and wired single-salute limit per session.
- [x] **Firebase Crashlytics Integration**:
  - Wired `firebase_crashlytics` with `runZonedGuarded` root zone, `FlutterError.onError` fatal capture, and `PlatformDispatcher.onError` handler in `main.dart`.
  - Added Crashlytics Gradle plugin (v3.0.6) on Android and upgraded google-services to 4.4.2.
- [x] **Offline Sync Exponential Backoff Retry Fix**:
  - Enhanced `UploadQueueService` to automatically schedule exponential backoff retries (5s, 10s, 20s, 40s, up to 60s max delay) when offline sync operations encounter network dropouts or errors mid-sync.
  - Added `retryAttempt` tracking to `UploadQueueState` and auto-resets attempt count upon successful sync or network reconnect events.
  - Added unit test coverage in `test/services/offline_sync_test.dart`.

---

## 🚀 High & Medium Priority Tasks

### 📚 Dictionary & Vocabulary
- [ ] **Interactive Phonetic Tooltips**: Interactive IPA pronunciation guides with playable audio chips on term details.
  - 📁 `lib/screens/dictionary_screen.dart`
- [ ] **Bulk Audio Import**: Admin utility to match and bulk-upload audio recordings by dictionary term keys.
  - 📁 `lib/screens/admin_dictionary_screen.dart`, `lib/services/firebase_service.dart`
- [ ] **Elder Voice Contributor Verification**: Community validation queue for elder audio recordings submitted via contributor requests before publishing to official dictionary entries.
  - 📁 `lib/screens/admin_requests_screen.dart`, `lib/models/contributor_request.dart`

### 🎮 Lessons & Learning Session
- [ ] **Adaptive Difficulty Scaling**: Dynamically adjust SRS intervals and task distractors based on learner error history and accuracy metrics.
  - 📁 `lib/services/srs_service.dart`, `lib/providers/learning_provider.dart`

### 🏫 Educator & Classroom Management (Village Sanctuary)
- [ ] **Educator Class Analytics Export**: Export student progress, quiz accuracy, and active streak metrics to CSV or PDF reports for village educators.
  - 📁 `lib/screens/educator_analytics_screen.dart`, `lib/screens/educator_students_screen.dart`
- [ ] **Village Custom Mini-Quizzes**: Allow educators to build and assign custom vocabulary checks or short assessments directly to connected village learners.
  - 📁 `lib/screens/educator_lessons_screen.dart`, `lib/models/educator_models.dart`

### 🗺️ Cultural Heritage & Map Archive
- [ ] **Geotagged Heritage Explorer**: Interactive map view displaying cultural stories, oral folklore audio recordings, and tribal landmarks across Mansaka heritage locations.
  - 📁 `lib/screens/archive_map_screen.dart`, `lib/models/geo_recording.dart`
- [ ] **Printable Certificates of Completion**: Generate downloadable PDF completion certificates featuring ancestral artwork when learners finish major units or milestones.
  - 📁 `lib/services/certificate_service.dart`, `lib/screens/learner_profile_screen.dart`

### 📊 Sentiment & Community Analytics
- [ ] **Facebook Graph API Integration**: Replace mock/secondary post data with real retrieval of publicly available Mansaka-language Facebook posts via the Facebook Graph API (unblocks real-data sentiment classification).
  - 📁 `lib/services/sentiment_service.dart`, `lib/screens/sentiment_dashboard_screen.dart`

### ⚔️ Community & Multiplayer
- [ ] **Duel Rematch & Persistent Duel Records**: Add a rematch action on the results screen and store per-user win/loss history (wins, losses, win streaks) in Firestore.
  - 📁 `lib/screens/lingua_duel_screen.dart`, `lib/services/duel_service.dart`
- [ ] **Duel State Riverpod Refactor**: Move matchmaking/battle state out of the screen into a `DuelSessionNotifier` so live duels survive navigation and can re-attach to an in-progress match after an app restart.
  - 📁 `lib/screens/lingua_duel_screen.dart`, `lib/providers/duel_provider.dart` (new)
- [ ] **Duel Anti-Cheat Hardening**: Validate damage deltas and answer correctness server-side (Cloud Functions or stricter rules) so a modified client cannot write arbitrary HP or claim false wins.
  - 📁 `lib/services/duel_service.dart`, `firestore.rules`
- [ ] **Voice Comments in Community Feed**: Allow learners to attach short voice messages to community discussions.
  - 📁 `lib/screens/community_feed_screen.dart`, `lib/services/audio_service.dart`

### 🌐 Accessibility & Full UI Localization
- [ ] **Dynamic Trilingual UI Switching**: Expand localization engine to support instant language switching (English, Tagalog/Filipino, Mansaka) across all app UI components.
  - 📁 `lib/utils/app_localization.dart`, `lib/providers/user_preferences_provider.dart`
- [ ] **High Contrast & Font Scaling**: Implement high contrast color scheme mode and dynamic font scale adjustments for elder community members and visually impaired learners.
  - 📁 `lib/providers/theme_provider.dart`, `lib/screens/learner_profile_screen.dart`

---

## 🛠 Low Priority, Refactoring & Infrastructure
- [ ] **Navigation Consistency**: Standardize back-navigation across all modules (GoRouter vs Navigator mixing) per roadmap Phase 4.
  - 📁 `lib/providers/router_provider.dart`
- [ ] **Audio Asset Compression Pipeline**: Compress recorded WAV files to AAC/Ogg Opus before Cloud Storage uploads to minimize cellular bandwidth usage in remote communities.
  - 📁 `lib/services/supabase_storage_service.dart`, `lib/utils/audio_validator.dart`
- [ ] **Hive Storage Compaction & Cache Pruning**: Scheduled local database box compaction and media cache cleanup to maintain low storage footprint (<100MB) on budget devices.
  - 📁 `lib/services/offline_service.dart`
- [ ] **Encrypted Token Storage**: Migrate user authentication session credentials and sensitive tokens from plain preferences to encrypted storage.
  - 📁 `lib/services/auth_service.dart`

---

## 🧪 Testing & Quality Assurance
- [ ] **Core Service Unit Tests**: Unit tests for `AudioService`, `NotificationService`, and `SrsService`.
  - 📁 `test/services/audio_service_test.dart`, `test/services/notification_service_test.dart`
- [ ] **Provider & Widget Tests**: Widget tests for `DictionaryFilterNotifier`, `ClaimRewardModal`, and `StreakReminderSettingsDialog`.
  - 📁 `test/providers/dictionary_filter_notifier_test.dart`, `test/widgets/claim_reward_modal_test.dart`
- [ ] **Duel Matchmaking Race Tests**: Firestore-emulator integration test where two clients concurrently claim the same waiting match — exactly one joiner must win the lobby.
  - 📁 `test/duel_sync_logic_test.dart`, `test/` (emulator harness)
- [ ] **Automated CI/CD Pipeline Workflow**: Configure GitHub Actions workflow to run static analysis (`flutter analyze`), unit tests, and release APK compilation on pull requests.
  - 📁 `.github/workflows/flutter_ci.yml`
- [ ] **End-to-End Integration Tests**: E2E integration test suite covering onboarding, lesson session execution, reward collection, and offline dictionary lookup.
  - 📁 `integration_test/app_test.dart`

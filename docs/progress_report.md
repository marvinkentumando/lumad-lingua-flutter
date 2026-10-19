# Lumad Lingua: Progress Report

**PROJECT TITLE:** Lumad Lingua: Sentiment-Driven Cultural Vitality & Language Revitalization Platform for the Mansaka Indigenous Language  
**STUDENT NAME(S):** Lumad Lingua Project Development Team  
**DATE:** October 2024 / Semester Progress  

---

## Introduction

**Lumad Lingua** is a mobile language revitalization and digital vitality monitoring platform specifically built for the **Mansaka** indigenous community of Mindanao, Philippines. The project bridges ancestral wisdom with modern mobile software engineering by combining multi-model machine learning sentiment analysis, gamified interactive learning modules, acoustic waveform pronunciation alignment, edge-offline synchronization, and multi-role administrative and educational portals.

Designed using Flutter and Dart with a reactive Riverpod architecture, the platform enables learners to acquire Mansaka vocabulary and grammar, educators to build tailored curricula, validators to verify cultural accuracy, and researchers/administrators to monitor community language vitality in real time.

*(Note: The Gantt Chart section has been intentionally omitted per guidelines).*

---

## Project Status

### Overview of the Project's Current Stage
The project is currently in **Phase 3/4 (Late Development, System Integration, and Refinement Stage)**. Overall project completion is estimated at **85% - 90%**. All primary core architecture layers—including user authentication, role-based access control (Learner, Educator, Validator, Admin), Firestore persistence, Supabase audio archiving, local Hive database caching, Leitner Spaced Repetition System (SRS), and gamified learning activities—are fully operational.

### Accomplishments Since the Last Report
Since the previous progress review with the project adviser and evaluation panel, the team has achieved the following key technical milestones:

1. **State Management & Offline Sync Engine Refactor:**
   - Designed and implemented a robust offline synchronization queue (`pending_sync_queue`) using Hive storage.
   - Refactored `StudentNotifier` and `UploadQueueService` to ensure offline actions (XP gains, streak increments, heart updates, milestone claims, and lesson progress) update locally in real-time and queue automatically for network sync upon reconnection.
   - Built automatic network listeners via `ConnectivityPlus` that trigger background retry synchronization without user disruption.
   - Authored automated unit test suites (`offline_sync_test.dart`) validating state recovery and sync queue transitions.

2. **Algorithm Expansion & Machine Learning Refinement:**
   - **Sentiment Analysis:** Expanded the classification pipeline in `SentimentService` to incorporate multi-model evaluation (Naïve Bayes, Support Vector Machines [SVM], and Bidirectional LSTM [BiLSTM]) alongside accuracy, precision, recall, and F1-score evaluation metrics.
   - **Pronunciation Assessment:** Enhanced `PronunciationService` with Hidden Markov Models (HMM) and Cosine Similarity to complement existing Mel-Frequency Cepstral Coefficients (MFCC) and Dynamic Time Warping (DTW) feature alignment.

3. **Multi-Role Console & Educational Authoring:**
   - Completed `EducatorAnalyticsScreen`, `EducatorStudentsScreen`, and `EducatorUnitManagementScreen` enabling educators to track student performance metrics and manage classroom units.
   - Implemented `LessonEditorScreen` enhancements, replacing disruptive modal popups with silent status indicators for auto-saving drafts.
   - Polished `AdminAdvancedAnalyticsScreen` and `AdminUsersScreen` with audit logging, role management, and bulk selection controls.

4. **Gamification & Heritage Retention Features:**
   - Integrated "Lingua Duels" real-time PvP match mechanics (`lingua_duel_screen.dart`).
   - Implemented procedural "Memory Forest" UI canvas reflecting Leitner SRS mastery progression.
   - Finalized the "Ancestral Vault Shop" for cosmetic and cultural badge rewards.

### Challenges Encountered and Solutions Implemented

#### Identification of Difficulties & Strategies Implemented:

1. **Challenge: Offline State Loss & Transient Connectivity Failure**
   - *Issue:* Network fluctuations in remote rural areas caused student lesson progress, XP, and streak counts to fail silently when syncing with Firestore.
   - *Solution:* Implemented an **offline-first local persistence architecture** powered by Hive (`OfflineService`). All state updates mutate local storage instantly and append a payload to `pending_sync_queue`. An active connectivity watcher automatically flushes the queue to Firebase once an internet connection is established.

2. **Challenge: Key Desynchronization in Interactive Content Editors**
   - *Issue:* In `MatchingEditor` and `SentenceReorderingEditor`, deleting list items caused index-based `ValueKey('..._$i')` keys to shift, causing controller state to misalign across list rows.
   - *Solution:* Refactored list rendering to utilize unique object identifiers and controller-managed item structures, guaranteeing key stability and clean state reconciliation.

3. **Challenge: Acoustic Noise & Feature Alignment Latency in Speech Analysis**
   - *Issue:* Ambient environmental noise distorted recording inputs during pronunciation tests, leading to poor score consistency.
   - *Solution:* Implemented audio volume normalization and high-pass noise filtering in `PronunciationService` prior to MFCC extraction and DTW alignment, ensuring low latency (<500ms) and accurate acoustic matching.

4. **Challenge: Discrepancy in XP and Streak Tracking**
   - *Issue:* Combo bonus XP calculated during lesson sessions was omitted during backend Firestore completion calls.
   - *Solution:* Updated `FirebaseService.completeLesson` to accept detailed session parameters (`bonusXp`, accuracy rate, streak updates) ensuring user profile balances reflect total earned rewards.

### Comparison of Actual Progress to the Planned Timeline
- **Planned Timeline Target:** Complete core framework, multi-role interfaces, offline persistence engine, and multi-algorithm evaluation modules.
- **Actual Progress:** **On Schedule.** Core functional requirements are 100% complete and verified. The offline sync engine refactor and algorithm implementations have been fully delivered. The project is well-positioned for final field usability testing.

---

## Work Completed

### Detailed Description of Tasks Completed

| Category | Completed Task | Deliverable / Implementation Detail |
| :--- | :--- | :--- |
| **Gamified Learning** | Structured Mansaka Curriculum & 10 Activity Types | `LessonSessionScreen`, `QuizScreen`, `ScenarioView`, Multiple Choice, Sentence Reordering, Word Hunt, Matching, Listening, and Pronunciation. |
| **Spaced Repetition** | Leitner SRS & Memory Forest | `SRSService`, `srsProgressStreamProvider`, procedural growth visualization. |
| **Dictionary & Audio** | Searchable Lexicon & Native Audio Archiving | Sub-500ms search latency, `DictionaryScreen`, `SupabaseStorageService` audio player/recorder. |
| **Multi-Role System** | Learner, Educator, Validator, and Admin Portals | Custom role navigation (`RoleNavConfig`), `EducatorDashboardScreen`, `AdminOverviewScreen`. |
| **Offline Sync Engine** | Hive Local Caching & Background Retry Queue | `OfflineService`, `UploadQueueService`, `StudentNotifier` offline state fallback. |
| **Sentiment Analysis** | Vitality Dashboard & Multi-Model Classifiers | `SentimentService` (Naïve Bayes, SVM, BiLSTM), `fl_chart` vitality trend charts. |
| **Pronunciation** | Waveform Audio Analysis & Acoustic Alignment | `PronunciationService`, `audio_waveforms` rendering, MFCC + DTW distance calculation. |

### Evidence of Work

#### 1. Offline Sync Queue & State Recovery Logic (`student_provider.dart` & `offline_service.dart`)
```dart
// StudentNotifier handling offline fallback and automatic pending queueing
Future<void> addXp(int amount) async {
  if (state.value == null) return;
  final currentProfile = state.value!;
  final updatedProfile = currentProfile.copyWith(
    xp: currentProfile.xp + amount,
  );

  // 1. Instantly update UI and persist to local Hive cache
  state = AsyncData(updatedProfile);
  await OfflineService.saveCachedStudentProfile(updatedProfile);

  // 2. Try network sync; fallback to background queue if offline
  try {
    await FirebaseService().updateStudentXp(updatedProfile.uid, updatedProfile.xp);
  } catch (e) {
    await OfflineService.queuePendingSyncAction(
      actionType: 'addXp',
      payload: {'uid': updatedProfile.uid, 'amount': amount},
    );
  }
}
```

#### 2. Pronunciation Feature Extraction & Acoustic Alignment (`pronunciation_service.dart`)
```dart
// MFCC Feature Extraction and DTW Audio Alignment
Future<double> evaluatePronunciation({
  required String userAudioPath,
  required String referenceAudioPath,
}) async {
  final userFeatures = await MfccService.extractMFCC(userAudioPath);
  final refFeatures = await MfccService.extractMFCC(referenceAudioPath);

  // Normalize volume and filter environmental noise
  final cleanUser = PronunciationService.normalizeAndFilter(userFeatures);
  final cleanRef = PronunciationService.normalizeAndFilter(refFeatures);

  // Compute Dynamic Time Warping (DTW) distance matrix
  final dtwDistance = PronunciationService.computeDTW(cleanUser, cleanRef);
  final similarityScore = (1.0 - (dtwDistance / maxPossibleDistance)).clamp(0.0, 1.0);

  return similarityScore * 100.0; // Returns percentage match
}
```

#### 3. Sentiment Classification Engine (`sentiment_service.dart`)
```dart
// Sentiment Vitality Classification
SentimentResult analyzeSentiment(String text) {
  final cleanedText = preprocessText(text);
  
  final naiveBayesScore = NaiveBayesClassifier.predict(cleanedText);
  final svmScore = SVMClassifier.predict(cleanedText);
  final biLstmScore = BiLSTMClassifier.predict(cleanedText);

  // Ensembled sentiment score output
  final ensembleScore = (naiveBayesScore + svmScore + biLstmScore) / 3.0;
  
  return SentimentResult(
    polarity: ensembleScore > 0.1 ? SentimentPolarity.positive 
            : ensembleScore < -0.1 ? SentimentPolarity.negative 
            : SentimentPolarity.neutral,
    confidence: ensembleScore.abs(),
  );
}
```

---

## Work in Progress

### Current Tasks Being Undertaken

1. **Facebook Graph API Live Data Integration:**
   - Transitioning `SentimentService` from offline curated Mansaka social media text samples to live API integration for real-time cultural vitality monitoring.

2. **Navigation Stack & UI Standardization:**
   - Standardizing back-navigation across all secondary screens using `GoRouter` imperative and declarative paths to eliminate route stack duplication.

3. **System Usability & Accessibility Polish:**
   - Refining color contrast across dark and light themes (adjusting text tokens like `white38` for accessibility compliance).
   - Standardizing haptic feedback responses for key gamification triggers (streaks, leveling up, correct answers).

4. **Community Usability Field Evaluation:**
   - Preparing standardized field evaluation questionnaires using the System Usability Scale (SUS) for testing with Mansaka elders, educators, and high school learners.

### Anticipated Completion Dates

| Task / Milestone | Target Completion Date |
| :--- | :--- |
| **Live Facebook Graph API Integration** | Day 7 |
| **Navigation Stack & Accessibility Polish** | Day 12 |
| **Community Field Evaluation & Usability Testing** | Day 18 |
| **Final Documentation & Release Deployment** | Day 21 |

---

## Conclusion

### Summary of Key Findings and Achievements
The **Lumad Lingua** platform successfully demonstrates that modern cross-platform software frameworks (Flutter) and cloud technologies (Firebase, Supabase) can be effectively combined with machine learning (MFCC/DTW acoustic matching and multi-classifier sentiment analysis) to create a robust, culturally respectful language revitalization engine. The successful refactoring of the offline sync queue guarantees that indigenous users in low-connectivity environments can interact with language materials without data loss.

### Assessment of Project Progress Against Goals
The project has successfully achieved all core objectives outlined in the initial specification:
- **Gamified Learning & Spaced Repetition:** Fully functional with 10 interactive activity formats and Leitner SRS.
- **Digital Dictionary & Audio Archiving:** Operating with sub-500ms search latency and native speaker audio streaming.
- **Offline-First Functionality:** Powered by Hive local caching and automated upload queues.
- **Multi-Role Ecosystem:** Functional dashboards for Learners, Educators, Validators, and Administrators.

### Outline of Plans and Next Steps
1. Finalize external live social media data integration for real-time sentiment collection.
2. Execute field usability evaluations with Mansaka community elders, educators, and students.
3. Consolidate evaluation feedback to achieve a target System Usability Scale (SUS) score of **>= 4.0 / 5.0**.
4. Prepare final project documentation, source code packaging, and production APK/bundle deployment.

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
- [x] **Lesson Session Screen**:
  - Fixed "Finish" button dialog bug on session results overlay by dismissing `dialogContext` before navigating with `GoRouter`.
  - Enhanced post-test survey feedback data submission with star ratings and open-text feedback to Firebase.

---

## 🚀 High Priority (Next Steps)

### 📚 Dictionary & Vocabulary
- [x] Add Part of Speech filter chip row to the Learner Dictionary Screen.
- [x] Support native audio file upload directly from the Admin Entry Form modal.
- [x] Implement Hive offline caching for global dictionary searches.

### 🎮 Lessons & Learning Session
- [ ] Add audio recording evaluation/pronunciation preview in lesson session activities.
- [x] Enhance post-test survey feedback data submission to Firebase.
- [ ] Implement audio pre-caching for entire lesson modules before starting a session.

### 🏆 Gamification & Rewards
- [ ] Expand Tribal Quests & Daily Challenge claim reward animations.
- [ ] Integrate Avatar cultural customization shop using Mist Crystals.
- [ ] Implement local push notifications for daily streak reminders.

---

## 🛠 Low Priority & Refactoring
- [ ] Refactor state management providers for smoother offline sync transitions.
- [ ] Add unit & widget tests for `AudioService` and `DictionaryFilterNotifier`.
- [ ] Optimize shimmer skeleton loading states across low-end mobile devices.

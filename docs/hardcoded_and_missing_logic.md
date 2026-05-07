# 🧩 Lumad Lingua - Technical Debt & Hardcoded Logic Audit

## 🚀 Implementation Checklist

- [x] **Impact Service Aggregation**: Connect `ImpactService` to real Firestore streams.
- [x] **Dynamic App Config**: Moved XP rewards and notification templates to Firestore `config/app`.
- [x] **Auth Session Tracking**: Updated `lastLogin` on every sign-in in `AuthService`.
- [x] **Lesson Collision Logic**: Fixed empty block in `FirebaseService.saveLesson` to shift units.
- [x] **SRS Algorithm Refinement**: Fixed inverse priority and implemented SM-2 logic in `FlashcardsScreen`.
- [x] **Word of the Day Pool**: Removed the `.limit(100)` constraint and implemented scalable randomization.
- [x] **Dynamic Profile Metrics**: Replaced profile rank/accuracy guesswork with real calculations.
- [x] **Artifact Unlock Customization**: Moved SFX and particle config in `ArtifactUnlockOverlay` to `AppConfig`.
- [ ] **Global XP Config**: Move hardcoded XP values (100, 500) to a remote config document.
- [ ] **Hardcoded UI Strings**: Centralize notification templates and status labels.
- [x] **Streak UI Modulo Fix**: Fixed the 7-day visual reset in `DailyCheckInBoard`.
- [x] **Theme Transitions**: Implemented smooth cross-fade animation in `main.dart`.
- [ ] **Phase 6: Advanced Gamification & Logic Centralization**
    - [ ] **Config-Driven Spirit Titles**: Move thresholds and titles from `MemberProfileScreen` to `AppConfig`.
    - [ ] **Flexible Streak System**: Move cycle duration (7 days) and reward icons to `AppConfig`.
    - [ ] **Dynamic Language Categories**: Fetch supported languages for `DictionaryScreen` from `AppConfig`.
    - [ ] **SRS Parameter Tuning**: Move SM-2 constants, deck limits, and reward XP to `AppConfig`.
- [ ] **Phase 7: Real-time Validator Health**
    - [ ] **Contributor Accuracy**: Replace hardcoded "98% APPROVAL" in `ValidatorEntriesScreen` with live calculation.
    - [ ] **Validator Workload Balance**: Implement a "Pending Count" display for validators based on active word streams.

---

## 🏗️ Services & Core Logic

### 1. `AppConfig` (`models/app_config.dart`)
- **Missing Fields**: `streakRewardCycle`, `spiritThresholds`, `supportedLanguages`, `srsSessionSize`, `srsCardXp`.

---

## 📱 Screens & UI Components

### 3. `MemberProfileScreen` (`member_profile_screen.dart`)
- **Spirit Thresholds**: Hardcoded logic for "Legend", "Elder", etc.

### 4. `LeaderboardScreen` (`leaderboard_screen.dart`)
- **Fixed Title Thresholds**: Tribal titles (e.g., "ELDER SAGE") are mapped to hardcoded rank numbers.

### 5. `FlashcardsScreen` (`flashcards_screen.dart`)
- **Deck Limitations**: Session size is hardcoded to 15 cards.
- **Reward Logic**: XP per card is hardcoded.

### 6. `DailyCheckInBoard` (`daily_check_in_board.dart`)
- **Cycle Duration**: Assumes a 7-day streak cycle.
- **Reward Visuals**: Hardcoded star icon on Day 7.

### 7. `DictionaryScreen` (`dictionary_screen.dart`)
- **Hardcoded Languages**: The category list is a static array.

### 8. `ValidatorEntriesScreen` (`validator_entries_screen.dart`)
- **Mocked Stats**: The "98% APPROVAL" label is a static UI element.

---

## 🏺 Artifacts & Gamification


### 8. `LevelUpModal` (`level_up_modal.dart`)
- **Fixed SFX**: Uses a fixed sound key `'level_up'`.

---

## 🛠️ Infrastructure & Utilities


## 🧪 Incorrect or Suboptimal Algorithms/Logics







---

## 📝 Missing Functions / Planned Features (Roadmap Phase 17+)
- [ ] **Search History**: No persistence for dictionary search terms.
- [ ] **Audio Autoplay Toggle**: Missing setting in user preferences.
- [ ] **Account Deletion**: No UI/Logic for GDPR-compliant account removal.
- [ ] **Offline Banner**: No active connectivity monitoring UI.
- [ ] **Reporting System**: No function to "Flag" incorrect dictionary entries from the learner view.

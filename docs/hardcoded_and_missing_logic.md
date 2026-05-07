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

---

---

This document tracks areas in the codebase where values are currently hardcoded, logic is mocked/simulated, or critical functions are missing. This serves as a checklist for transitioning from a prototype/MVP to a production-ready system.

---

## 🏗️ Services & Core Logic

---

## 📱 Screens & UI Components

### 3. `MemberProfileScreen` (`member_profile_screen.dart`)
- **Hardcoded Fallbacks**: Location defaults to "PHILIPPINES" if the profile field is null.
- **Simulated Metrics**: `_buildContributionImpact` uses a simple activity count to "guess" accuracy and rank labels (e.g., `count > 10 ? '98%' : '95%'`).
- **Preview Limits**: The "Earned Artifacts" section is hardcoded to show a maximum of 3 items.

### 4. `LeaderboardScreen` (`leaderboard_screen.dart`)
- **Fixed Title Thresholds**: Tribal titles (e.g., "ELDER SAGE") are mapped to hardcoded rank numbers (1, 3, 10, 50).

### 5. `FlashcardsScreen` (`flashcards_screen.dart`)
- **SRS Intervals**: Leitner intervals are hardcoded as `[1, 2, 4, 7, 14, 30]` days.
- **Deck Limitations**: Session size is hardcoded to 15 cards.
- **Reward Logic**: XP per card is hardcoded to 10.

### 6. `DailyCheckInBoard` (`daily_check_in_board.dart`)
- **Cycle Duration**: Assumes a 7-day streak cycle for UI rendering.
- **Reward Visuals**: Hardcoded star icon on Day 7 without a backend-driven reward configuration.

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

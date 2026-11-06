# Vitality Quest Gamification Plan - Social Post Sentiment Identification

**Goal**: Redesign the Vitality Quest experience (`LearnerSentimentScreen`) into an engaging, gamified social media sentiment classification card game where learners review Facebook-style community posts and identify their emotional tone (Positive, Negative, or Neutral).

---

## 🎯 Core UX / UI Concept

1. **Social Media Post Card ("Feed Style")**:
   - Realistic social card layout featuring contributor avatar, display name, verified tribal badge, and relative timestamp.
   - Post body text in native Mansaka / indigenous language.
   - Toggleable or expandable translations (Filipino / English) for scaffolded learning.

2. **Gamified Sentiment Identification Mechanic**:
   - Clear prompt: *"Analyze this community expression. What is its emotional tone?"*
   - Three primary interactive sentiment action buttons with distinct cultural color coding and icons:
     - 🟢 **Positive / Encouraging** (*Madyaw / Malipayon*)
     - 🟡 **Neutral / Reflective** (*Naghunahuna / Malinawon*)
     - 🔴 **Negative / Somber** (*Subo / Mabug-at*)
   - Instant feedback with haptic feedback (`HapticService.celebration()` / `error()`), spirit particle animations, and XP / Mist Crystal rewards.

3. **Session Progress & Streak Engine**:
   - Swipeable or sequential card deck (e.g., 5 posts per daily training session).
   - Session completion summary card showing correct answers, accuracy percentage, and total rewards earned.

---

## 📋 Implementation Tasks

### Phase 1: Data Model & Session State (`LearnerSentimentScreen`)
- [ ] Update state management to track a session queue of community sentiment posts (e.g., 5 posts per active quest session).
- [ ] Track current card index, correct answers count, and total earned XP/crystals for the session.

### Phase 2: Facebook-Style Post Card Widget UI
- [ ] Design `_buildSocialPostCard(...)` mimicking a community social media post container (author header, post body, engagement metrics, reaction summary).
- [ ] Add collapsible translation drawer so learners can check translations only after making a guess (or upon viewing hints).

### Phase 3: Gamified Voting & Feedback Flow
- [ ] Implement sentiment selection buttons (Positive, Neutral, Negative).
- [ ] Add instant validation logic comparing learner's guess against post's ground-truth sentiment category.
- [ ] Integrate reward distribution (`studentProvider.addXp`, `studentProvider.addMistCrystals`) and haptic/particle feedback.

### Phase 4: Session Completion & Summary View
- [ ] Create a rewarding session completion dialog / card summarizing accuracy and celebrating progress.
- [ ] Update daily quest completion state in `SharedPreferences`.

---

## 🚀 Verification Plan
- **Manual Verification**: Launch Vitality Quest from the Learning Hub, evaluate simulated Facebook-style posts, select sentiment tones, verify instant feedback, haptics, and reward accumulation.

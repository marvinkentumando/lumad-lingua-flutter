# Gamified Social Sentiment Feed & Guessing Game Implementation Plan

Transform the Learner Sentiment Dashboard (`LearnerSentimentScreen`) into an immersive, gamified social media feed ("Lumad Feed") where community reflections appear like social media posts (Facebook-style cards), and learners actively guess and classify their emotional tone (Positive, Neutral, Negative, Gratitude) to earn XP, Mist Crystals, and streak bonuses.

## User Review Required

> [!IMPORTANT]
> **UX Shift**: Instead of just reading a static list of community reflections, every post in the feed becomes an interactive sentiment challenge card where learners classify the tone before unlocking full translations, linguistic breakdowns, and rewards.

## Open Questions

- Should unclassified posts hide translations until the learner makes a correct sentiment guess, or should guessing be optional with bonus rewards? (Proposed: Optional/Interactive challenge per post with bonus XP/Gems on first correct guess).

## Proposed Changes

### Sentiment & Gamification Components

#### [MODIFY] [learner_sentiment_screen.dart](file:///C:/Users/Aspire-3/Desktop/Lumad%20Lingua%20Flutter/lib/screens/learner_sentiment_screen.dart)
- Redesign reflection cards into Facebook/Social-style post cards (Avatar/Author header, timestamp, community badge, post content).
- Implement interactive sentiment classification buttons on each post card (*Positive 🌿*, *Neutral 🌾*, *Negative 🍂*, *Gratitude ✨*).
- Add persistent state for learner guesses per post (`classified_sentiment_posts_$userId`) in `SharedPreferences`.
- Add feedback animations (confetti/spirit particles, XP popups, correct/incorrect indicators) upon guessing a post's tone.
- Add daily sentiment streaks and "Feed Mastery" progress bar (e.g., "Classify 5 posts today for bonus XP").

#### [MODIFY] [sentiment_post.dart](file:///C:/Users/Aspire-3/Desktop/Lumad%20Lingua%20Flutter/lib/models/sentiment_post.dart)
- Ensure robust handling of sentiment categories and user classification metadata if needed.

## Verification Plan

### Automated Tests
- Run existing widget and unit tests (`flutter test`).
- Add tests for sentiment post classification logic and state persistence.

### Manual Verification
- Deploy to emulator / device.
- Navigate to Learner Sentiment Dashboard.
- Verify Facebook-style post cards render correctly.
- Test guessing sentiment on posts, verifying XP/Gem rewards and correct/incorrect visual feedback.

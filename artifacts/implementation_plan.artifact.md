# Fix Facebook Post Card Scrolling on Learner Sentiment Screen

Enable vertical scrolling inside the Facebook post card on [learner_sentiment_screen.dart](file:///C:/Users/Aspire-3/Desktop/Lumad%20Lingua%20Flutter/lib/screens/learner_sentiment_screen.dart) when posts are lengthy, expanded via "See more", or when the English translation is toggled.

## User Review Required

> [!NOTE]
> No breaking changes or architecture shifts. This ensures better usability on smaller screens and with long community posts.

## Proposed Changes

### Learner Sentiment Screen

#### [MODIFY] [learner_sentiment_screen.dart](file:///C:/Users/Aspire-3/Desktop/Lumad%20Lingua%20Flutter/lib/screens/learner_sentiment_screen.dart)
- Wrap the main content column inside `_buildCardFront` with a `SingleChildScrollView` (or wrap the scrollable body of the card) so users can scroll down to read full text and translations when expanded.

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure existing tests pass.

### Manual Verification
- Open Learner Sentiment Screen / Flashcard Sentiment Quest.
- Select a card with lengthy text.
- Click "See more" and "Translate to English".
- Verify that the card content is scrollable and all text/translations are fully accessible.

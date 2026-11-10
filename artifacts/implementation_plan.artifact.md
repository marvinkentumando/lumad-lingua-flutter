# Implementation Plan - Educator Pronunciation & Learning Effectiveness Analytics

This plan outlines the steps to transform the educator audio metrics section into a robust descriptive analytics dashboard for user pronunciation accuracy, storing passing learner attempts ($\ge$ 60%) and utilizing the exact same Supabase reference audio dataset as learners.

## User Review Required

> [!IMPORTANT]
> - **Data Persistence**: We will introduce tracking for learner pronunciation attempts in Firestore/Supabase, saving attempts where the score is $\ge$ 60% (passing threshold).
> - **UI Modernization**: The educator audio metrics view will be restructured from an individual approval queue into aggregate class/village analytics, removing expert attribution tags.

## Proposed Changes

### Data & Backend Layer

#### [MODIFY] [firebase_service.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/services/firebase_service.dart)
- Add methods to save learner pronunciation attempts (`saveLearnerPronunciationAttempt`) and fetch learner attempts by educator/student (`fetchLearnerAttempts`).

#### [NEW] [learner_attempt.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/models/learner_attempt.dart)
- Define data model for stored pronunciation attempts (`learnerId`, `phraseId`, `phraseTitle`, `scorePercentage`, `timestamp`).

---

### UI & Educator Dashboard Layer

#### [MODIFY] [educator_audio_comparison_screen.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/screens/educator_audio_comparison_screen.dart)
- Remove expert tag (`• Expert (Unknown)`).
- Integrate `supabaseDatasetEntriesProvider` to load the exact same reference audio dataset used by learners.
- Replace manual review controls with descriptive analytics:
  - Class Average Pronunciation Accuracy.
  - Most Mastered Words & Struggle Points (<60%).
  - Student Progress List and Individual Drill-Down.

#### [MODIFY] [audio_comparison_screen.dart](file:///C:/Users/Admin/StudioProjects/lumad-lingua-flutter/lib/screens/audio_comparison_screen.dart)
- Automatically invoke `saveLearnerPronunciationAttempt` when a learner achieves $\ge$ 60% score during audio comparison practice.

## Verification Plan

### Automated Tests
- Run `flutter test` and `flutter analyze` to ensure zero compilation errors.

### Manual Verification
- Log in as an educator and verify the Pronunciation Analytics tab displays accurate cohort averages, student progress lists, and correct reference audio without expert labels.

# Lumad Lingua - Application Plan

## 🌟 App Vision
Lumad Lingua is a premium, cultural language-learning platform. It aims to elevate indigenous language education from a basic utility to an immersive, gamified, and culturally rich experience. The app blends modern, fluid design principles with deep cultural lore, ensuring that users not only learn the language but also connect with the heritage behind it.

## 🎯 Core Objectives
1. **Interactive Learning**: Provide spaced-repetition (SRS) driven learning with adaptive difficulty, and a diverse range of lesson types.
2. **Cultural Immersion**: Integrate "Ancestral Vaults", "Elders' Wisdom", and narrative-driven scenarios to teach context, not just vocabulary.
3. **Visual Excellence**: Maintain a stunning, modern UI featuring glassmorphism, dynamic backgrounds, and haptic feedback to create a tactile and premium feel.
4. **Community & Contribution**: Allow validators and community members to submit, review, and refine audio and textual content.

## 🛠️ Architecture & Tech Stack
- **Framework**: Flutter (Dart)
- **Backend/Database**: Firebase (Firestore, Authentication, Storage) Supabase
- **State Management**: Riverpod (`Notifier` patterns)
- **Local Storage**: Hive (for offline resilience and caching)

## 🗺️ Roadmap & Upcoming Phases

### Phase 1: Research Integrity & Geospatial Visualization
- [x] Density-based Heatmap Interface for linguistic documentation (beyond markers).
- [x] Contribution Version History & Audit Trail for data integrity and archival.
- [x] Formalized Pre-test and Post-test Assessment modules for research evaluation.

### Phase 2: Advanced Audio & Linguistic Validation
- [ ] MFCC-based Pronunciation Analysis (upgrading from basic DTW waveform comparison).
- [ ] Similarity Score Categorization: Excellent (≥80%), Good (60–79%), Needs Improvement (<60%).
- [ ] Audio Submission Constraints: Enforcement of 10MB max size and 1.0s minimum duration.
- [ ] Strict Firestore Security: Update rules to prevent Learners from reading unvalidated vocabulary entries.

## ✅ Recently Completed Milestones
- **Interaction Hubs**: Scenario Hub, Lingua Duel, Impact Tracking.
- **Stability**: Zero-lint state, global error boundaries, and robust offline caching.
- **Learning Mechanics**: Leitner-based SRS, Word of the Day, and Lesson Weaver.
- **Media**: Real-time audio recording, validation flows, and waveform visualizers.

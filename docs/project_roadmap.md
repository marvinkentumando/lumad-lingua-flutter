# Project Roadmap: Lumad Lingua Flutter

This document outlines the remaining tasks and future enhancements required to fulfill the project objectives and requirements defined in `objectives_and_requirements.md`.

## 🔴 Phase 1: Advanced Linguistic Algorithms (High Priority)
### Sentiment Analysis System
- [x] **Multi-Model Implementation**: Develop Naïve Bayes, SVM, and BiLSTM classifiers in `SentimentService`.
- [x] **Performance Evaluation**: Implement logic to calculate Accuracy, Precision, Recall, and F1-score for model comparison.
- [ ] **External Data Integration**: Implement Facebook Graph API retrieval for actual community posts (transition from mock data).

### Pronunciation Refinement
- [x] **Algorithm Expansion**: Implement HMM (Hidden Markov Models) and Cosine Similarity models in `PronunciationService` to complete the 3-algorithm evaluation requirement.
- [x] **Preprocessing Pipeline**: Add Noise Reduction and advanced Volume Normalization logic to handle real-world recording environments.
- [x] **Comparative Evaluation**: Build the algorithm selection module to identify and lock the optimal model for mobile deployment.

---

## 🟡 Phase 2: Security & Infrastructure
- [x] **Firebase Custom Claims**: Migrate Role-Based Access Control from Firestore fields to Auth Custom Claims for enhanced security.
- [x] **Production Security Rules**: Harden Firestore security rules to prevent unauthorized content modification.
- [x] **Offline Conflict Resolution**: Implement a UI/logic for resolving data conflicts when syncing offline lesson progress.

---

## 🟢 Phase 3: Analytics & Community Custodianship
- [x] **Enhanced Sentiment Dashboard**: Integrate `fl_chart` for time-series visualization of community vitality trends based on the new algorithms.
- [x] **Formal Test Assessments**: Build the module for administrators to conduct and review learning effectiveness tests (Pre-test and Post-test data aggregation).
- [x] **Data Portability**: Complete the JSON export functionality for user contributions (Learners/Educators) as per privacy requirements.

---

## 🔵 Phase 4: Polish & Deployment
- [x] **Performance Optimization**: Ensure dictionary searches remain under 500ms even with expanded datasets (implemented via debouncing and memoization).
- [x] **File Size Validation**: Implement strict 10MB limits for native audio uploads and 1-second minimum duration validation.
- [ ] **UI/UX Refinement**:
    - [x] **Silent Auto-save**: Replace disruptive SnackBar auto-save notifications in `LessonEditorScreen` with a discreet status indicator.
    - [x] **Dirty State Checking**: Only trigger "Unsaved Changes" warnings when actual modifications have been made.
    - [x] **Empty State Handling**: Fix the "50% Vitality" false neutral state in the Sentiment Dashboard when data is unavailable.
    - [x] **Accessible Terminology**: Replace technical jargon like "MFCC" with learner-friendly terms like "Acoustic Match."
    - [ ] **Navigation Consistency**: Standardize back-navigation across all modules (GoRouter vs Navigator).
    - [x] **Chart Polish**: Fix tooltip occlusion in `fl_chart` and implement skeleton loaders to prevent layout shifts.
    - [ ] **Haptic Consistency**: Ensure all critical success/error actions trigger appropriate haptic patterns.
- [x] **Accessibility Audit**: Audit color contrast for labels (e.g., `white38`) and ensure text scales properly on small devices.
- [ ] **Final Usability Testing**: Conduct standardized evaluations with community elders and youth to target a mean score of 4.0/5.0.

---

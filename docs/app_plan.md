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
- **Backend/Database**: Firebase (Firestore, Authentication, Storage)
- **State Management**: Riverpod (`Notifier` patterns)
- **Local Storage**: Hive (for offline resilience and caching)

## 🎨 UI/UX Strategy
- **The "Butter" Update**: Focus on extreme fluidity with Hero transitions, dynamic backgrounds, and particle celebrations.
- **Glassmorphism & Depth**: Utilize `BackdropFilter` for search bars, modals, and navigation components to create layered depth without harsh borders.
- **Tactile Feedback**: Heavy reliance on micro-animations, physics-based interactions (spring scaling), and integrated `HapticFeedback` for correct/incorrect answers.
- **Thematic Consistency**: Implementation of distinct, beautifully crafted themes (e.g., "Cream" and "Forest" modes) with strict contrast and accessibility standards.

## 🗺️ Roadmap & Upcoming Phases

### Phase 13: Technical Polish & Adaptive Design
- Global theme transitions (cross-fade animations).
- Screen Reader/Accessibility support audit.
- Dynamic layout optimizations for foldable and tablet devices.

### Phase 14: Micro-Interactions & Tactile Feedback
- Custom splash/ripple effects aligned with brand colors.
- Interactive physics (scale-down on tap) for primary buttons.
- Animated, looping empty states (Lottie/Rive).

### Phase 15: Spatial Depth & Glassmorphism
- Frosted overlays for bottom sheets and modals.
- Nuanced, multi-layered elevation for cards.
- Sticky blurred headers for long scrolling lists.

### Phase 16: Fluid Navigation & Gestures
- Custom, branded pull-to-refresh indicators.
- Edge-swipe parallax for nested screen navigation.
- Multi-stage snapping modals for ergonomic one-handed use.

### Phase 17: Quality of Life (QoL) Enhancements
- Recent searches, bookmarks, and clipboard copy in the dictionary.
- Offline indicators and explicit data sync management.
- User reporting/flagging for content issues.
- Account management (data export, account deletion).

## ✅ Recently Completed Milestones
- **Interaction Hubs**: Scenario Hub, Lingua Duel, Impact Tracking.
- **Stability**: Zero-lint state, global error boundaries, and robust offline caching.
- **Learning Mechanics**: Leitner-based SRS, Word of the Day, and Lesson Weaver.
- **Media**: Real-time audio recording, validation flows, and waveform visualizers.

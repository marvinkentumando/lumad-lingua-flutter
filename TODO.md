# 🌿 Lumad Lingua - Vision 2026 Roadmap

This roadmap focuses on elevating the **User Experience (UI/UX)** and core **Functional Features** to create a polished, engaging, and premium language learning platform.

---

## 🦋 Phase 7: The "Butter" Update (Fluidity & Motion)
*Making every interaction feel incredibly smooth and responsive.*
- [x] **Advanced Hero Transitions**: Implement seamless Hero animations between Learning Path nodes and Lesson Introduction screens.
- [x] **Dynamic Backgrounds**: Introduce subtle, ambient animated backgrounds (e.g., slow-moving mist or sun rays) reacting to the theme.

## 🎨 Phase 8: Typographic & Thematic Refinement
*Elevating the visual hierarchy and ensuring absolute consistency.*
- [x] **Contrast & Accessibility Review**: Conduct a final pass to ensure "Cream" mode text contrast meets WCAG AAA standards.
- [x] **Iconography Standardization**: Replace any remaining default Material icons with custom, rounded icons matching the brand language.
- [x] **Fluid Typography**: Ensure all `AppTypography` styles scale gracefully when users adjust system font sizes without breaking layouts.

## 📱 Phase 9: Ergonomics & Edge-to-Edge Design
*Optimizing for modern bezel-less displays and one-handed use.*
- [x] **True Edge-to-Edge UI**: Configure system overlays to draw seamlessly behind transparent navigation and status bars on mobile.
- [ ] **Ergonomic Modals**: Convert standard dialogs into draggable, snap-to-fit bottom sheets for easier reachability on tall screens.
- [x] **Glassmorphic Navigation**: Refine the bottom navigation bar with a floating, frosted-glass design and animated active indicators.

## 🚀 Phase 10: State & Skeleton Polish
*Eliminating jarring layout jumps and uninspired loading screens.*
- [x] **Shimmering Skeletons**: Replace all basic spinners with beautifully designed, layout-matching shimmer placeholders.
- [x] **Whimsical Empty States**: Add custom, branded illustrations for all empty states (e.g., "No words found", "Inbox empty").
- [x] **Graceful Image Loading**: Implement smooth cross-fade transitions with blurred low-res placeholders for all network image assets.

## 🏺 Phase 11: Sensory Feedback & Haptics
*Engaging the senses beyond sight to create a tactile learning experience.*
- [x] **Haptic Feedback Integration**: Implement distinct vibration patterns for correct/incorrect answers, level-ups, and button interactions using `HapticFeedback`.
- [x] **Dynamic Soundscapes**: Add subtle ambient background tracks for the Forest/Mountain themes and high-quality UI sound effects (SFX) for task completion.
- [x] **Particle Celebrations**: Replace basic confetti with custom "Soul/Spirit" particle systems when unlocking sacred artifacts or reaching milestones.

## 📜 Phase 12: Narrative & Onboarding Flow
*Creating a cohesive journey from the first launch to mastery.*
- [x] **Interactive Onboarding**: Build a "first-look" experience that introduces the Lumad lore and explains core mechanics like the Ancestral Vault.
- [x] **Lore Integration**: Add "Elders' Wisdom" tooltips or pop-ups that provide cultural context for specific words or map locations.
- [x] **Achievement Lore**: Give each badge/artifact a short, engaging story or legend in its detail view to deepen immersion.

## 🛠️ Phase 13: Technical Polish & Adaptive Design
*Ensuring the system is robust, performant, and accessible for everyone.*
- [ ] **Global Theme Transition**: Implement a smooth, cross-fade animation when switching between "Cream" and "Forest" modes.
- [ ] **Screen Reader Support**: Conduct a full audit of all custom UI widgets to ensure proper semantics for TalkBack/VoiceOver accessibility.
- [ ] **Dynamic Layout Optimization**: Refine layouts for tablets and foldables, ensuring the Learning Path and Map adapt to larger aspect ratios.

---

## ✅ Completed & Milestone Archive

### 🎭 New Interaction Hubs (Recent)
- [x] **Scenario Hub**: Choice-driven interactive stories with branching narratives.
- [x] **Lingua Duel Hub**: UI and flow for P2P competitive quiz battles.
- [x] **Impact Tracking**: Real-time contribution metrics showing students helped and reach.
- [x] **Mastery Dashboard**: Advanced SRS analytics with mastery trends and progress charts.
- [x] **AI Pronunciation Prototype**: Visual voice fingerprinting and heuristic scoring.

### 🏛️ Foundations (Stability & Core)
- [x] **Zero-Lint State**: Fully compliant with latest Flutter linter rules.
- [x] **Global Error Handling**: Implemented `GlobalErrorBoundary` and `init()` in `main.dart`.
- [x] **Offline Resilience**: Local caching via Hive and upload queuing for connectivity gaps.
- [x] **State Management**: Refactored `uploadQueueProvider` to robust `Notifier` pattern.

### 🎓 Learning Features
- [x] **SRS Implementation**: Leitner-based Daily Review system and "Mastery Level" tracking.
- [x] **Word of the Day**: Automated daily selection of approved terms.
- [x] **Lesson Weaver**: Completed modular editor with 8+ activity types and real-time validation.
- [x] **Ancestral Vault**: Tiered rarity system for cultural artifacts and gallery UI.
- [x] **Smart Shuffling**: Implemented SRS prioritization based on forgetfulness curves.
- [x] **Adaptive Learning**: Implemented real-time session difficulty scaling based on correct answer streaks.

### 🎙️ Audio & Media
- [x] **Real-time Recording**: Direct audio capture in-app for contributors.
- [x] **Audio Validation**: Native/Translation playback for lesson quality control.
- [x] **Waveform Visualizer**: Integrated waveform visualizer for real-time speech feedback.

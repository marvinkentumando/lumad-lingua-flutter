# 🌿 Lumad Lingua - Production Roadmap 2.0

This roadmap marks the transition from our established foundations to a **Premium, Production-Ready** experience. We are resetting our focus to prioritize high-end UI/UX, robust utility functions, and architectural integrity.

---

## 💎 Phase 1: Ethereal Depth & Glassmorphism
*Establishing a sense of hierarchy and premium feel through spatial design.*
- [ ] **Glassmorphic Overlays**: Implement `BackdropFilter` with `Blur` effects for all bottom sheets and full-screen modals to maintain spatial context.
- [ ] **Dynamic Elevation System**: Replace flat shadows with nuanced, multi-layered "soft" shadows for cards and floating buttons.
- [ ] **Frosted Sticky Headers**: Implement sticky headers in Dictionary and Leaderboard that softly blur content scrolling beneath them.
- [ ] **High-Contrast Micro-Styling**: Refine the visual balance of "Cream" and "Midnight" modes for maximum legibility and aesthetic pop.

## 🌊 Phase 2: Kinetic Soul & Fluid Motion
*Infusing the application with life through custom gestures and organic movement.*
- [ ] **Ancestral Refresh**: Create a custom pull-to-refresh indicator featuring a rotating tribal motif or ancestral sun icon.
- [ ] **Parallax Transitions**: Implement subtle background parallax shifts when navigating between the main map and detail screens.
- [ ] **Organic Snapping Modals**: Enhance bottom sheets with physics-based snapping for "Peek", "Standard", and "Full" heights.
- [ ] **Haptic Rhythm**: Map distinct haptic "thumps" and "ticks" to specific UI interactions (e.g., slider snaps, list reaches).

## 🛠️ Phase 3: Knowledge Utility & QoL
*Empowering users with practical tools for efficient learning and daily management.*
- [ ] **Smart History & Bookmarks**: Implement persistent search history and a "Save to Vault" feature for dictionary entries.
- [ ] **Universal Clipboard Utility**: Add one-tap "Copy" buttons for definitions, example sentences, and cultural wisdom.
- [ ] **Sensory Preferences**: Build the "Audio Autoplay" toggle and "Haptic Intensity" slider in the user settings menu.
- [ ] **Account Sovereignty**: Implement full GDPR-compliant "Export Data" and "Delete Account" flows with secure verification.

## 🛡️ Phase 4: Resilience & Integrity
*Ensuring a robust experience regardless of connectivity or data state.*
- [ ] **Ethereal Offline Banner**: Create a non-intrusive, floating indicator for offline mode that doesn't obstruct the main UI.
- [ ] **The "Elders' Signal" Reporting**: Implement a community-driven flagging system for correcting dictionary typos or audio issues.
- [ ] **Remote Reward Matrix**: Migrate all hardcoded XP rewards (Level ups, card reviews) to a dynamic Firestore configuration.
- [ ] **Fallback Perfection**: Finalize robust UI fallbacks for missing profile images, location data, or network timeouts.

## 🌍 Phase 5: Universal Accessibility & Scale
*Reaching every user on every device with uncompromising quality.*
- [ ] **Voice-Over & TalkBack Audit**: Complete a full semantic sweep of the application to ensure it is fully navigable for visually impaired learners.
- [ ] **Spatial Adaptation**: Optimize the "Learning Path" and "Ancestral Map" for tablet and foldable aspect ratios using adaptive layouts.
- [ ] **Global String Centralization**: Finalize the move of all hardcoded notification templates and status labels into the localization/config system.

---

## ✅ Legacy Milestones (Foundations Completed)
*Archived progress from the initial development phases.*

### 🎭 Interaction & Motion
- [x] **Advanced Hero Transitions**: Seamless animations between Learning Path and Lessons.
- [x] **Tactile Physics**: Spring-based scale animations and brand-aligned ripples.
- [x] **Animated Empty States**: Branded Lottie/Animate loops for empty lists.

### 🧠 Core Learning Engine
- [x] **SM-2 SRS Algorithm**: Dynamic spaced repetition for long-term retention.
- [x] **Lesson Weaver**: Modular editor with 8+ activity types and real-time validation.
- [x] **Real-time Analytics**: Firestore-driven impact tracking and profile metrics.
- [x] **Advanced Pedagogical Analytics**: Heatmaps, dialect distribution, and SRS health monitoring.

### 🏛️ Stability & Infrastructure
- [x] **Offline Resilience**: Local caching via Hive and upload queuing.
- [x] **Global Error Handling**: Centralized error boundaries and initialization logic.
- [x] **Zero-Lint State**: Compliance with modern Flutter best practices.

### 👑 Admin & Governance (New)
- [x] **Ancestral Map Architect**: Visual editor for cultural sites and municipality hotspots.
- [x] **Warrior Circle Ops**: Season management, shop pricing, and duel moderation.
- [ ] **Remote Reward Matrix**: Dynamic XP configuration via Firestore.
- [ ] **Role Request Dashboard**: Full processing flow for Contributor/Educator roles.
- [ ] **Elders' Signal Moderator**: Community-driven reporting and flag resolution.

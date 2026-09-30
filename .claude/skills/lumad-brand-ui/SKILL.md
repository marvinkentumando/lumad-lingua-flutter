---
name: lumad-brand-ui
description: Design guardrails for building or changing any Lumad Lingua UI (screens, widgets, dialogs, animations). Use whenever touching lib/screens or lib/widgets so new UI stays on-brand, theme-aware, and culturally consistent.
---

# Lumad Brand UI

Read `docs/brand_system.md` before designing new UI. It is the source of truth.

## Colors: `lib/theme/app_colors.dart`
- Always use `AppColors.*` or `Theme.of(context).colorScheme`. **Never** hardcode `Color(0x...)` or use `Colors.blue` and similar in screens or widgets.
- **Forest scale** (`forest900`–`forest50`): primary brand. `forest500` is the main brand color.
- **Gold scale** (`gold900`–`gold50`): accents and CTAs. `gold500` is the primary CTA.
- **Cream** (`creamBg`, `creamText`, `creamText2`, `creamBorder`): light-mode surfaces and text.
- **Semantic:** `semanticGreen` = correct, `semanticRed` = error, `semanticBlue` = info, `semanticWarning`. `terracotta` is the secondary accent.

## Typography: `lib/theme/app_typography.dart`
- Headings use `AppTypography.display`, `h1`, `h2` and `h3` (Fredoka).
- Body text uses `AppTypography.bodyLarge`, `body`, `label`, `labelBold` and `caption` (Nunito).
- Codes and phonetics use `AppTypography.mono` (DM Mono).
- Don't call `GoogleFonts.*` directly in screens. Use `.copyWith()` on an `AppTypography` style.

## Themes: `lib/theme/app_theme.dart`
- Every UI must work in both **Cream Mode** (light: `creamBg` background, `forest500` primary) and **Forest Mode** (dark: `forest900` background, `gold500` primary).
- Pick colors from the brightness (`Theme.of(context).brightness`) or the color scheme, not a single fixed value.

## Reuse existing widgets (`lib/widgets/`) before creating new ones
- Buttons, cards and inputs: `brand_button.dart`, `brand_card.dart`, `brand_text_field.dart`, `brand_search_bar.dart`
- Backgrounds: `brand_background.dart`, `generative_dagmay_background.dart`, `ambient_topo_background.dart`, `parallax_background.dart`
- Surfaces: `glass_box.dart`, `dynamic_glass_box.dart`
- States: `branded_empty_state.dart`, `app_shimmer_skeleton.dart`, `error_boundary.dart`
- Rewards and feedback: `claim_reward_modal.dart`, `crystal_burst_animation.dart`, `level_up_modal.dart`, `lottie_feedback.dart`
- Cultural motifs: `CulturalPatternPainter` in `lib/theme/cultural_patterns.dart` (`'dagmay'`, `'inabal'`, generic)

## Motion
- Use `flutter_animate` for entrance and micro animations and Lottie for celebration moments. Keep them short and subtle.
- Pair reward moments with the existing haptic and audio feedback (`lib/services/haptic_service.dart`, `audio_service.dart`).

## Voice and cultural naming
- Keep the established vocabulary: **Mist Crystals** (currency), **Village / Village Sanctuary**, **Tribal Quests**, **Ancestral Vault**, **Elders' Wisdom**.
- Treat Lumad and Mansaka culture respectfully. Don't invent tribal symbols or meanings. Reuse the existing patterns or ask.

## Checklist before finishing
- [ ] No hardcoded colors or fonts in changed files
- [ ] Looks correct in both light and dark themes
- [ ] Existing brand widgets reused where they fit
- [ ] Works at phone width with no overflow (also check web and admin layouts if the screen is educator- or admin-facing)

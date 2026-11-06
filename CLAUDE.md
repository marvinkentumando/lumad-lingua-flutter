# 🌿 CLAUDE.md — Claude & Agent Instructions

## Commands
- **Install dependencies**: `flutter pub get`
- **Build runner**: `flutter pub run build_runner build --delete-conflicting-outputs`
- **Analyze**: `flutter analyze`
- **Test**: `flutter test`
- **Run**: `flutter run`

## Code Style & Guidelines
- **Framework & State**: Flutter SDK ^3.5.0 with Riverpod (`flutter_riverpod`).
- **Brand Widgets**: Use `BrandCard`, `BrandButton`, `BrandTextField`, `BrandBackground`, `ParallaxBackground`.
- **Theme Colors**: `AppColors.gold500` (Gold), `AppColors.forest900` (Forest Green), `AppColors.creamBg` (Warm Cream).
- **Localization**: Use `ref.watch(localizationProvider).translate('key')`. Add entries for `en`, `tl`, and `bis` in `lib/utils/app_localization.dart`.
- **Error Handling**: Use `l10n.getAuthErrorMessage(e)` for friendly user-facing messages.
- **Inputs**: Form inputs must support `AutofillGroup`, `autofillHints`, `textInputAction`, and focus-based error validation.
- **Navigation**: Multi-step screens must use `PopScope` for handling physical back buttons smoothly.

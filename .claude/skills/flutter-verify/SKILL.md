---
name: flutter-verify
description: Run Lumad Lingua's local quality checks (pub get, Hive code generation, format, analyze, tests) and summarize failures. Use before committing, after editing models or providers, or when asked to "verify", "check", or "make sure it builds".
---

# Flutter Verify

Run these checks from the repo root, in order. Stop and report if a step fails in a way that blocks the next one.

1. **Dependencies**
   ```bash
   flutter pub get
   ```

2. **Code generation** (Hive adapters: `lib/models/*.g.dart`)
   Run this whenever a file under `lib/models/` that has a `part '*.g.dart'` directive changed.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   Never edit `*.g.dart` files by hand.

3. **Format** (only the files you changed)
   ```bash
   dart format <changed .dart files>
   ```

4. **Static analysis** (rules from `analysis_options.yaml` / `flutter_lints`)
   ```bash
   flutter analyze
   ```
   Fix new errors and warnings in files you touched. Don't mass-fix unrelated pre-existing issues unless asked; mention them instead.

5. **Tests** (`test/`)
   ```bash
   flutter test
   ```

## Report

End with a short summary:

| Step | Result |
|------|--------|
| pub get | ✅ / ❌ |
| build_runner | ✅ / ❌ / skipped |
| format | ✅ / files changed |
| analyze | ✅ / N issues (list the ones in touched files) |
| test | ✅ / N failed (name them) |

If `flutter` is not installed in the environment, say so plainly rather than claiming the checks passed.

Don't write analyzer output into repo files like `analysis_output.txt`, `issues.txt` or `current_issues.txt` unless the user asks.

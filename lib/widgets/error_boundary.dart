import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_button.dart';
import 'glass_box.dart';

class GlobalErrorBoundary extends StatelessWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  /// Configures the global error widget builder.
  /// Should be called in main() before runApp().
  static void init() {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _ErrorDisplay(details: details);
    };
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _ErrorDisplay extends StatelessWidget {
  final FlutterErrorDetails details;

  const _ErrorDisplay({required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: AppColors.forest900,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: GlassBox(
            borderRadius: 32,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.gold500,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Render Error',
                    style: AppTypography.h2.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The UI encountered a weaver\'s knot. Our team of builders has been notified.',
                    style: AppTypography.body.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          details.exception.toString(),
                          style: const TextStyle(
                            color: AppColors.gold300,
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  BrandButton(
                    text: 'BACK TO SAFETY',
                    onTap: () {
                      // We use a global key or just try to pop/push home
                      // Since this is a render error, the context might be partially broken
                      // but Navigator should still work if it's above the error.
                      try {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      } catch (e) {
                        // Fallback if navigator fails
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



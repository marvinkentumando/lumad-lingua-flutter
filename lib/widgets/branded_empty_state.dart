import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_button.dart';

class BrandedEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? emoji;
  final Widget? action;
  final String? imagePath;
  final String? advice;
  final bool isError;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const BrandedEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.emoji,
    this.action,
    this.imagePath,
    this.advice,
    this.isError = false,
    this.onRetry,
    this.retryLabel,
  });

  /// Specialized factory for Empty States featuring Lumad character illustrations
  factory BrandedEmptyState.empty({
    Key? key,
    required String title,
    required String message,
    String? advice,
    String? imagePath = 'assets/images/lumad_character (1).png',
    IconData? icon,
    Widget? action,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return BrandedEmptyState(
      key: key,
      title: title,
      message: message,
      advice: advice,
      imagePath: imagePath,
      icon: icon,
      isError: false,
      onRetry: onAction,
      retryLabel: actionLabel,
      action: action,
    );
  }

  /// Specialized factory for Error States with context-aware advice & retry capabilities
  factory BrandedEmptyState.error({
    Key? key,
    String? title,
    required String error,
    String? advice,
    String? imagePath = 'assets/images/lumad_character (2).png',
    VoidCallback? onRetry,
    String? retryLabel,
    Widget? action,
  }) {
    // Sanitize raw error strings into user-friendly message
    final cleanError = error.replaceAll(RegExp(r'^(Exception:|Error:)\s*'), '').trim();
    return BrandedEmptyState(
      key: key,
      title: title ?? 'Connection Disrupted',
      message: cleanError.isEmpty ? 'Something went wrong while synchronizing data.' : cleanError,
      advice: advice ?? 'Please check your internet connection and try reconnecting.',
      imagePath: imagePath,
      isError: true,
      onRetry: onRetry,
      retryLabel: retryLabel ?? 'Try Reconnecting',
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = isError ? AppColors.semanticRed : AppColors.gold500;
    final secondaryBg = isError
        ? AppColors.semanticRed.withValues(alpha: 0.1)
        : AppColors.gold500.withValues(alpha: 0.08);

    final String effectiveImagePath = imagePath ??
        (isError
            ? 'assets/images/lumad_character (2).png'
            : 'assets/images/lumad_character.png');

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: primaryAccent.withValues(alpha: isDark ? 0.3 : 0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.red : AppColors.gold500).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Animated Lumad Character Illustration / Badge
              _buildIllustrationHeader(context, secondaryBg, primaryAccent, effectiveImagePath),

              const SizedBox(height: 20),

              // 2. Cultural / System Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isError ? Icons.wifi_off_rounded : Icons.auto_awesome_rounded,
                      size: 14,
                      color: primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isError ? 'SYSTEM NOTICE' : 'MANSAKA CULTURAL ARCHIVE',
                      style: AppTypography.caption.copyWith(
                        color: primaryAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).scale(),

              const SizedBox(height: 16),

              // 3. Title
              Text(
                title,
                style: AppTypography.h2.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 8),

              // 4. Detailed Message
              Text(
                message,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              // 5. Context-Aware Advice / Tip Container
              if (advice != null && advice!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black26
                        : AppColors.gold500.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : AppColors.gold500.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: AppColors.gold500,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          advice!,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              ],

              // 6. Action or Retry Button
              if (action != null || onRetry != null) ...[
                const SizedBox(height: 24),
                if (action != null)
                  action!.animate().fadeIn(delay: 500.ms).scale()
                else if (onRetry != null)
                  BrandButton(
                    text: retryLabel ?? (isError ? 'Try Reconnecting' : 'Start a Lesson'),
                    onTap: onRetry,
                    type: isError ? BrandButtonType.primary : BrandButtonType.primary,
                    icon: isError ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                  ).animate().fadeIn(delay: 500.ms).scale(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustrationHeader(
    BuildContext context,
    Color secondaryBg,
    Color primaryAccent,
    String effectiveImagePath,
  ) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: secondaryBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryAccent.withValues(alpha: 0.25),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lumad character illustration asset
          ClipOval(
            child: Image.asset(
              effectiveImagePath,
              width: 105,
              height: 105,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) {
                if (emoji != null) {
                  return Center(
                    child: Text(
                      emoji!,
                      style: const TextStyle(fontSize: 50),
                    ),
                  );
                }
                return Center(
                  child: Icon(
                    icon ?? (isError ? Icons.warning_amber_rounded : Icons.auto_awesome),
                    size: 50,
                    color: primaryAccent,
                  ),
                );
              },
            ),
          ),
          if (isError)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.semanticRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.signal_cellular_connected_no_internet_4_bar_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1.03, 1.03),
          duration: 2500.ms,
          curve: Curves.easeInOut,
        );
  }
}

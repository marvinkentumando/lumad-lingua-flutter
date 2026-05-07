import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_button.dart';
import 'lottie_feedback.dart';

class FeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String title;
  final String subtitle;
  final VoidCallback onContinue;
  final int? xpEarned;

  const FeedbackPanel({
    super.key,
    required this.isCorrect,
    required this.title,
    required this.subtitle,
    required this.onContinue,
    this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF0A3319) : const Color(0xFF3A0808),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isCorrect ? AppColors.semanticGreen : AppColors.semanticRed,
            width: 4,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, -8),
            blurRadius: 24,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isCorrect ? "🎉 $title" : "💡 $title",
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          if (isCorrect && xpEarned != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold500.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.gold500,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "+$xpEarned XP",
                                style: AppTypography.label.copyWith(
                                  color: AppColors.gold500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                isCorrect
                    ? const SuccessLottie(size: 80)
                    : const FailureLottie(size: 80),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: BrandButton(
                text: "Continue →",
                type: isCorrect
                    ? BrandButtonType.success
                    : BrandButtonType.danger,
                onTap: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



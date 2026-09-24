import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/app_localization.dart';
import '../utils/password_validator.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final AppLocalization l10n;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final result = PasswordValidator.validate(password);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color strengthColor;
    String strengthText;
    double progress;

    switch (result.strength) {
      case PasswordStrength.strong:
        strengthColor = AppColors.semanticGreen;
        strengthText = l10n.translate('password_strength_strong');
        progress = 1.0;
        break;
      case PasswordStrength.fair:
        strengthColor = AppColors.gold500;
        strengthText = l10n.translate('password_strength_fair');
        progress = 0.66;
        break;
      case PasswordStrength.weak:
        strengthColor = AppColors.semanticRed;
        strengthText = l10n.translate('password_strength_weak');
        progress = 0.33;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forest900.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: strengthColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('password_strength'),
                style: AppTypography.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.8),
                ),
              ),
              Text(
                strengthText,
                style: AppTypography.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          _buildRequirementRow(
            isMet: result.hasMinLength,
            label: l10n.translate('req_min_8_chars'),
            isDark: isDark,
          ),
          _buildRequirementRow(
            isMet: result.hasUppercase,
            label: l10n.translate('req_uppercase'),
            isDark: isDark,
          ),
          _buildRequirementRow(
            isMet: result.hasLowercase,
            label: l10n.translate('req_lowercase'),
            isDark: isDark,
          ),
          _buildRequirementRow(
            isMet: result.hasDigit,
            label: l10n.translate('req_number'),
            isDark: isDark,
          ),
          _buildRequirementRow(
            isMet: result.hasSpecialChar,
            label: l10n.translate('req_special_char'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow({
    required bool isMet,
    required String label,
    required bool isDark,
  }) {
    final color = isMet
        ? AppColors.semanticGreen
        : (isDark ? Colors.white38 : Colors.black38);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                fontSize: 11,
                color: isMet
                    ? (isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.forest900)
                    : (isDark ? Colors.white38 : Colors.black45),
                fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

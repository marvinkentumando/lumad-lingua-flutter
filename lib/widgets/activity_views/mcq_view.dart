import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class MCQView extends StatelessWidget {
  final String question;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int>? onOptionSelected;
  final bool isReadOnly;

  const MCQView({
    super.key,
    required this.question,
    required this.options,
    this.selectedIndex,
    this.onOptionSelected,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.isEmpty ? 'Question?' : question,
          style: AppTypography.h2.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 32),
        ...List.generate(options.length, (index) {
          final optionText = options[index];
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: isReadOnly ? null : () => onOptionSelected?.call(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.semanticBlue.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.semanticBlue
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: Text(
                optionText.isEmpty ? 'Option ${index + 1}' : optionText,
                style: AppTypography.bodyLarge.copyWith(
                  color: isSelected ? AppColors.semanticBlue : Colors.white,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

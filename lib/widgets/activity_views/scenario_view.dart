import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ScenarioView extends StatelessWidget {
  final String question;
  final String scenarioText;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int>? onOptionSelected;
  final bool isReadOnly;

  const ScenarioView({
    super.key,
    required this.question,
    required this.scenarioText,
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
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.forestDarkCard,
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/images/village_bg.png'),
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.forum_rounded,
              color: AppColors.gold500,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.gold500.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
          ),
          child: Text(
            scenarioText.isEmpty ? 'Scenario details...' : scenarioText,
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          question.isEmpty ? 'What would you say?' : question,
          style: AppTypography.h3.copyWith(color: AppColors.gold500),
        ),
        const SizedBox(height: 20),
        ...List.generate(options.length, (index) {
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
                options[index].isEmpty ? 'Option ${index + 1}' : options[index],
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



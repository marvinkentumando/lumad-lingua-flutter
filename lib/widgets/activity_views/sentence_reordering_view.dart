import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SentenceReorderingView extends StatelessWidget {
  final String question;
  final List<String> scrambledParts;
  final List<String> availableParts;
  final Function(String) onWordTap;
  final Function(String) onScrambledWordTap;
  final bool isReadOnly;

  const SentenceReorderingView({
    super.key,
    required this.question,
    required this.scrambledParts,
    required this.availableParts,
    required this.onWordTap,
    required this.onScrambledWordTap,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.isEmpty ? 'Reorder the words' : question,
          style: AppTypography.h2.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 32),
        // Drop zone
        Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white24,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scrambledParts
                .map(
                  (word) => GestureDetector(
                    onTap: isReadOnly ? null : () => onScrambledWordTap(word),
                    child: Chip(
                      label: Text(
                        word,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.semanticBlue,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 32),
        // Available parts
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableParts
              .map(
                (word) => GestureDetector(
                  onTap: isReadOnly ? null : () => onWordTap(word),
                  child: Chip(
                    label: Text(
                      word,
                      style: const TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              )
              .toList(),
        ),
        if (isReadOnly && availableParts.isEmpty && scrambledParts.isEmpty)
          Center(
            child: Text(
              "No words added yet.",
              style: AppTypography.label.copyWith(color: Colors.white54),
            ),
          ),
      ],
    );
  }
}




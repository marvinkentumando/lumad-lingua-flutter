import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../../theme/app_colors.dart';
import 'configuration_preview.dart';
import 'vocabulary_preview.dart';
import 'mcq_preview.dart';
import 'pronunciation_preview.dart';
import 'matching_preview.dart';
import 'sentence_reordering_preview.dart';
import 'listening_preview.dart';
import 'scenario_preview.dart';

class LessonPreviewPanel extends StatelessWidget {
  final LessonStep? selectedStep;
  final String title;
  final String description;
  final String difficulty;
  final String dialect;

  const LessonPreviewPanel({
    super.key,
    required this.selectedStep,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.dialect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.forest800,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 300,
          height: 600,
          decoration: BoxDecoration(
            color: AppColors.forest900, // Phone background
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.black, width: 8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: _buildLivePreviewContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewContent() {
    if (selectedStep == null) {
      return const Center(
        child: Text(
          'Select a step to preview',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    switch (selectedStep!.type) {
      case ActivityType.configuration:
        return ConfigurationPreview(
          title: title,
          description: description,
          difficulty: difficulty,
          dialect: dialect,
        );
      case ActivityType.vocabulary:
        return VocabularyPreview(step: selectedStep!);
      case ActivityType.mcq:
        return MCQPreview(step: selectedStep!);
      case ActivityType.pronunciation:
        return PronunciationPreview(step: selectedStep!);
      case ActivityType.matching:
        return MatchingPreview(step: selectedStep!);
      case ActivityType.sentenceReordering:
        return SentenceReorderingPreview(step: selectedStep!);
      case ActivityType.listening:
        return ListeningPreview(step: selectedStep!);
      case ActivityType.scenario:
        return ScenarioPreview(step: selectedStep!);
    }
  }
}



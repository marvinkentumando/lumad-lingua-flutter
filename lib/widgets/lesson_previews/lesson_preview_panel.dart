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
  final VoidCallback onStart;
  final VoidCallback onExitPreview;
  final VoidCallback? onPreviousActivity;
  final VoidCallback? onNextActivity;
  final bool isPreviewSessionActive;
  final int currentActivityNumber;
  final int totalActivities;

  const LessonPreviewPanel({
    super.key,
    required this.selectedStep,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.dialect,
    required this.onStart,
    required this.onExitPreview,
    this.onPreviousActivity,
    this.onNextActivity,
    this.isPreviewSessionActive = false,
    this.currentActivityNumber = 0,
    this.totalActivities = 0,
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
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Positioned.fill(child: _buildLivePreviewContent()),
                if (isPreviewSessionActive) _buildSessionControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreviewContent() {
    final step = selectedStep;
    if (step == null) {
      return const Center(
        child: Text(
          'Select a step to preview',
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    switch (step.type) {
      case ActivityType.configuration:
        return ConfigurationPreview(
          title: title,
          description: description,
          difficulty: difficulty,
          dialect: dialect,
          onStart: onStart,
        );
      case ActivityType.vocabulary:
        return VocabularyPreview(step: step);
      case ActivityType.mcq:
        return MCQPreview(step: step);
      case ActivityType.pronunciation:
        return PronunciationPreview(step: step);
      case ActivityType.matching:
        return MatchingPreview(step: step);
      case ActivityType.sentenceReordering:
        return SentenceReorderingPreview(step: step);
      case ActivityType.listening:
        return ListeningPreview(step: step);
      case ActivityType.scenario:
        return ScenarioPreview(step: step);
      case ActivityType.wordHunt:
        return _buildPlaceholderPreview('Word Hunt');
      case ActivityType.trueOrFalse:
        return _buildPlaceholderPreview('True or False');
      case ActivityType.fillInTheBlanks:
        return _buildPlaceholderPreview('Fill in the Blanks');
    }
  }

  Widget _buildPlaceholderPreview(String type) {
    return Center(
      child: Text(
        'Preview for $type coming soon',
        style: const TextStyle(color: Colors.white24),
      ),
    );
  }

  Widget _buildSessionControls() {
    final isLastActivity = currentActivityNumber >= totalActivities;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: onExitPreview,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Exit lesson preview',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PREVIEW $currentActivityNumber/$totalActivities',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPreviousActivity,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    child: const Text('BACK'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLastActivity ? onExitPreview : onNextActivity,
                    child: Text(isLastActivity ? 'FINISH' : 'NEXT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

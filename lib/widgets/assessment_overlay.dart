import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/assessment.dart';
import 'brand_button.dart';

class AssessmentOverlay extends StatefulWidget {
  final AssessmentType type;
  final List<AssessmentQuestion> questions;
  final Function(Map<String, dynamic> answers) onComplete;

  const AssessmentOverlay({
    super.key,
    required this.type,
    required this.questions,
    required this.onComplete,
  });

  @override
  State<AssessmentOverlay> createState() => _AssessmentOverlayState();
}

class _AssessmentOverlayState extends State<AssessmentOverlay> {
  final Map<String, dynamic> _answers = {};
  int _currentQuestionIndex = 0;
  final bool _isSubmitting = false;
  bool _isFinished = false;

  void _handleOptionSelected(String questionId, dynamic value) {
    setState(() {
      _answers[questionId] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.forest800,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.gold500),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.gold500, size: 64)
                .animate()
                .scale(curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'RITUAL COMPLETE',
              style: AppTypography.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              widget.type == AssessmentType.preTest
                  ? 'Your journey has been blessed. +50 XP'
                  : 'You have earned the elders\' favor. +100 XP, +25 Crystals',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            BrandButton(
              text: 'CONTINUE',
              onTap: () => widget.onComplete(_answers),
            ),
          ],
        ),
      );
    }

    final question = widget.questions[_currentQuestionIndex];
    final isLast = _currentQuestionIndex == widget.questions.length - 1;
    final canAdvance = _answers.containsKey(question.id) ||
        question.questionType == QuestionType.textInput;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.forest800,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.type == AssessmentType.preTest ? 'SURVEY' : 'POST-TEST',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${_currentQuestionIndex + 1} / ${widget.questions.length}',
                style: AppTypography.mono.copyWith(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: Colors.white),
          ).animate(key: ValueKey(_currentQuestionIndex)).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 24),
          _buildQuestionContent(question),
          const SizedBox(height: 24),
          if (_isSubmitting)
            const CircularProgressIndicator(color: AppColors.gold500)
          else
            BrandButton(
              text: isLast ? 'SUBMIT' : 'NEXT',
              onTap: canAdvance
                  ? () {
                      if (isLast) {
                        setState(() => _isFinished = true);
                      } else {
                        setState(() {
                          _currentQuestionIndex++;
                        });
                      }
                    }
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(AssessmentQuestion question) {
    switch (question.questionType) {
      case QuestionType.starRating:
        final currentRating = (_answers[question.id] as int?) ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starValue = i + 1;
              final isSelected = starValue <= currentRating;
              return IconButton(
                iconSize: 36,
                icon: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected ? AppColors.gold500 : Colors.white24,
                ),
                onPressed: () => _handleOptionSelected(question.id, starValue),
              );
            }),
          ),
        );

      case QuestionType.textInput:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type your feedback here (optional)...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => _handleOptionSelected(question.id, val),
          ),
        );

      case QuestionType.multipleChoice:
      default:
        return Column(
          children: question.options.map((option) {
            final isSelected = _answers[question.id] == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _handleOptionSelected(question.id, option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold500 : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.gold500 : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: AppTypography.body.copyWith(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.black, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
    }
  }
}

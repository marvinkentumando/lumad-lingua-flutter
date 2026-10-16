import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/student_provider.dart';
import '../services/haptic_service.dart';
import 'brand_card.dart';
import 'brand_button.dart';

void showStreakRecoveryDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const StreakRecoveryDialog(),
  );
}

class StreakRecoveryDialog extends ConsumerStatefulWidget {
  const StreakRecoveryDialog({super.key});

  @override
  ConsumerState<StreakRecoveryDialog> createState() => _StreakRecoveryDialogState();
}

class _StreakRecoveryDialogState extends ConsumerState<StreakRecoveryDialog> {
  int _currentStep = 0;
  int _selectedOption = -1;
  bool _answered = false;
  bool _isCorrect = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What does "Madayaw" mean in Mandaya/Mansaka?',
      'options': ['Goodbye', 'Good/Beautiful/Valuable', 'Thank you', 'Water'],
      'correctIndex': 1,
    },
    {
      'question': 'Which word expresses gratitude or "Thank You"?',
      'options': ['Salamat', 'Bago', 'Balay', 'Kagatan'],
      'correctIndex': 0,
    },
    {
      'question': 'What is the sacred spirit or land in local Lumad lore?',
      'options': ['Guinto', 'Yutang Kabilin', 'Mati', 'Kultura'],
      'correctIndex': 1,
    },
  ];

  void _handleOptionSelect(int index) {
    if (_answered) return;
    final q = _questions[_currentStep];
    final correct = index == q['correctIndex'];

    setState(() {
      _selectedOption = index;
      _answered = true;
      _isCorrect = correct;
    });

    if (correct) {
      HapticService.selection();
    } else {
      HapticService.error();
    }
  }

  void _nextStep() {
    if (_currentStep < _questions.length - 1) {
      setState(() {
        _currentStep++;
        _selectedOption = -1;
        _answered = false;
        _isCorrect = false;
      });
    } else {
      // Completed Recovery Quest!
      HapticService.celebration();
      ref.read(studentProvider.notifier).completeStreakRecoveryQuest();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔥 Streak Successfully Repaired! +50 XP & +30 Crystals earned!'),
          backgroundColor: AppColors.semanticGreen,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(studentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _questions[_currentStep];

    return Dialog(
      backgroundColor: isDark ? AppColors.forest900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build_circle_rounded, color: AppColors.gold500, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak Recovery Quest',
                        style: GoogleFonts.outfit(
                          color: AppColors.gold500,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Save your ${student.previousStreak > 0 ? student.previousStreak : 'broken'} day streak!',
                        style: AppTypography.body.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress indicators
            Row(
              children: List.generate(_questions.length, (idx) {
                final active = idx <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active ? AppColors.gold500 : (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            Text(
              'Question ${_currentStep + 1} of ${_questions.length}',
              style: AppTypography.label.copyWith(
                color: isDark ? AppColors.gold500 : AppColors.gold700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              q['question'] as String,
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Options
            ...List.generate((q['options'] as List<String>).length, (i) {
              final optionText = (q['options'] as List<String>)[i];
              final isSelected = _selectedOption == i;
              final isCorrectOpt = i == q['correctIndex'];

              Color bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
              Color borderColor = Colors.transparent;

              if (_answered) {
                if (isCorrectOpt) {
                  bgColor = AppColors.semanticGreen.withValues(alpha: 0.15);
                  borderColor = AppColors.semanticGreen;
                } else if (isSelected && !isCorrectOpt) {
                  bgColor = AppColors.terracotta.withValues(alpha: 0.15);
                  borderColor = AppColors.terracotta;
                }
              } else if (isSelected) {
                borderColor = AppColors.gold500;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _handleOptionSelect(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${String.fromCharCode(65 + i)}.',
                          style: AppTypography.mono.copyWith(
                            color: AppColors.gold500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            optionText,
                            style: AppTypography.body.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            if (_answered) ...[
              if (!_isCorrect)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Almost! Try another step to prove your wisdom.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.terracotta,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: BrandButton(
                  text: _currentStep < _questions.length - 1 ? 'Next Question' : 'Claim Streak Repair 🔥',
                  onTap: _nextStep,
                ).animate().fade().scale(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/lesson.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../utils/app_localization.dart';

class MasteryDashboardScreen extends ConsumerWidget {
  const MasteryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final user = ref.watch(authServiceProvider).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lessonsAsync = ref.watch(allLessonsStreamProvider);
    final progressAsync = user != null
        ? ref.watch(userProgressStreamProvider(user.uid))
        : const AsyncValue<Map<String, dynamic>>.data({});

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark, l10n),
              Expanded(
                child: lessonsAsync.when(
                  data: (lessons) {
                    return progressAsync.when(
                      data: (progressMap) => _buildContent(
                        context,
                        ref,
                        lessons,
                        progressMap,
                        isDark,
                        l10n,
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.gold500),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Error loading progress: $e',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold500),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error loading lessons: $e',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppLocalization l10n) {
    final textColor = isDark ? Colors.white : AppColors.forest900;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/learning');
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: textColor.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson Mastery & Unit Progress',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.gold500,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Track your performance across lesson sessions',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.creamText3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Lesson> lessons,
    Map<String, dynamic> progressMap,
    bool isDark,
    AppLocalization l10n,
  ) {
    if (lessons.isEmpty) {
      return Center(
        child: Text(
          'No lessons available.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    int totalLessons = lessons.length;
    int completedLessons = 0;
    double totalScoreSum = 0;

    for (var lesson in lessons) {
      final pData = progressMap[lesson.id] as Map<String, dynamic>?;
      if (pData != null) {
        if (pData['completed'] == true) {
          completedLessons++;
        }
        final score = (pData['bestScore'] as num?)?.toDouble() ?? 0.0;
        totalScoreSum += score;
      }
    }

    final double completionFactor = totalLessons > 0 ? completedLessons / totalLessons : 0.0;
    final double avgAccuracy = totalLessons > 0 ? (totalScoreSum / totalLessons) : 0.0;

    // Group lessons by unitNumber
    final Map<int, List<Lesson>> unitMap = {};
    for (var lesson in lessons) {
      unitMap.putIfAbsent(lesson.unitNumber, () => []).add(lesson);
    }
    final sortedUnitNumbers = unitMap.keys.toList()..sort();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallCurriculumCard(
            completedLessons,
            totalLessons,
            completionFactor,
            avgAccuracy,
            isDark,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('UNIT MASTERY BREAKDOWN'),
          const SizedBox(height: 12),
          ...sortedUnitNumbers.map((unitNum) {
            final unitLessons = unitMap[unitNum]!;
            return _buildUnitCard(context, unitNum, unitLessons, progressMap, isDark);
          }),
          const SizedBox(height: 24),
          _buildSectionTitle('LESSON SESSION ROSTER'),
          const SizedBox(height: 12),
          ...lessons.map((lesson) {
            final pData = progressMap[lesson.id] as Map<String, dynamic>?;
            return _buildLessonRow(context, lesson, pData, isDark);
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOverallCurriculumCard(
    int completedCount,
    int totalCount,
    double completionFactor,
    double avgAccuracy,
    bool isDark,
  ) {
    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRICULUM MASTERY',
                    style: AppTypography.label.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(completionFactor * 100).toInt()}%',
                    style: AppTypography.displayBold.copyWith(
                      color: Colors.black,
                      fontSize: 44,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionFactor.clamp(0.0, 1.0),
              backgroundColor: Colors.black.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Completed', '$completedCount / $totalCount Lessons'),
              _buildMiniMetric('Avg. Session Score', '${avgAccuracy.toInt()}% Accuracy'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 150.ms);
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    int unitNumber,
    List<Lesson> unitLessons,
    Map<String, dynamic> progressMap,
    bool isDark,
  ) {
    int completedInUnit = 0;
    double unitScoreSum = 0;

    for (var l in unitLessons) {
      final pData = progressMap[l.id] as Map<String, dynamic>?;
      if (pData != null) {
        if (pData['completed'] == true) completedInUnit++;
        unitScoreSum += (pData['bestScore'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final double unitCompletion = unitLessons.isNotEmpty ? completedInUnit / unitLessons.length : 0.0;
    final double avgUnitScore = unitLessons.isNotEmpty ? unitScoreSum / unitLessons.length : 0.0;

    int stars = 0;
    if (avgUnitScore >= 90) {
      stars = 3;
    } else if (avgUnitScore >= 70) {
      stars = 2;
    } else if (avgUnitScore >= 40) {
      stars = 1;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'UNIT $unitNumber',
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(unitCompletion * 100).toInt()}% Done',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.forest900,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(3, (i) {
                    return Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: i < stars ? AppColors.gold500 : (isDark ? Colors.white12 : Colors.black12),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: unitCompletion.clamp(0.0, 1.0),
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  unitCompletion == 1.0 ? AppColors.semanticGreen : AppColors.gold500,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completedInUnit of ${unitLessons.length} lessons completed • ${avgUnitScore.toInt()}% average score',
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white54 : AppColors.creamText3,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonRow(
    BuildContext context,
    Lesson lesson,
    Map<String, dynamic>? pData,
    bool isDark,
  ) {
    final bool isCompleted = pData?['completed'] == true;
    final double bestScore = (pData?['bestScore'] as num?)?.toDouble() ?? 0.0;
    final bool isStarted = bestScore > 0 || isCompleted;

    Color statusColor = Colors.grey;
    String statusText = 'Not Started';

    if (isCompleted) {
      statusColor = AppColors.semanticGreen;
      statusText = 'Completed';
    } else if (isStarted) {
      statusColor = AppColors.gold500;
      statusText = 'In Progress';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.creamBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : (isStarted ? Icons.play_circle_fill_rounded : Icons.menu_book_rounded),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Unit ${lesson.unitNumber} • ${lesson.category} • ${lesson.tasks.length} Tasks',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.creamText3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${bestScore.toInt()}%',
                style: TextStyle(
                  color: isCompleted ? AppColors.semanticGreen : AppColors.gold500,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.label.copyWith(
        color: AppColors.gold500,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w900,
        fontSize: 10,
      ),
    );
  }
}

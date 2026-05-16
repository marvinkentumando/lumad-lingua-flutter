import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/student_provider.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/lesson.dart';
import '../widgets/skeleton.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/mist_crystal_store.dart';
import '../widgets/vine_progress_bar.dart';
import '../services/haptic_service.dart';
import '../widgets/dynamic_glass_box.dart';

class LearningHubScreen extends ConsumerWidget {
  const LearningHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentState = ref.watch(studentProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientTopoBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Header
                      Text(
                        'Your Learning\nPaths',
                        style: AppTypography.h1ExtraBold.copyWith(
                          color: isDark ? AppColors.gold500 : AppColors.forest500,
                          fontSize: 36,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      // Stats Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildStatCard(
                              context,
                              'Daily Streak',
                              '${studentState.displayedStreak}',
                              'SUN TRAILS',
                              '☀️',
                              () => context.push('/streak'),
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              context,
                              'Mist Crystals',
                              '${studentState.mistCrystals}',
                              'EARNED',
                              '✨',
                              () => showMistCrystalStore(context, ref),
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              context,
                              'Ancestral XP',
                              '${studentState.xp}',
                              'LEVEL UP',
                              '🔥',
                              () => _showXpDetailDialog(context, studentState),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),

                      // Mastery Trends Entry Card
                      GestureDetector(
                        onTap: () => context.push('/mastery-dashboard'),
                        child: ref.watch(userProfileProvider).when(
                          data: (profile) {
                            final userId = ref.watch(authServiceProvider).currentUser?.uid;
                            final dueCount = userId != null
                                ? ref.watch(dueSRSCountProvider(userId)).value ?? 0
                                : 0;

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                BrandCard(
                                  theme: dueCount > 0 ? BrandCardTheme.vibrant : BrandCardTheme.gold,
                                  padding: const EdgeInsets.all(24),
                                  borderRadius: 32,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: dueCount > 0 ? Colors.white10 : Colors.black12,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          dueCount > 0 ? Icons.alarm_on_rounded : Icons.auto_graph_rounded,
                                          color: dueCount > 0 ? Colors.white : Colors.black,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dueCount > 0 ? 'Review Ready' : 'Learning Progress',
                                              style: AppTypography.h3.copyWith(
                                                color: dueCount > 0 ? Colors.white : Colors.black,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            Text(
                                              dueCount > 0
                                                  ? '$dueCount terms need your attention'
                                                  : 'View your mastery trends and SRS analytics',
                                              style: AppTypography.body.copyWith(
                                                color: dueCount > 0 ? Colors.white60 : Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: dueCount > 0 ? Colors.white : Colors.black54,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                                if (dueCount > 0)
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.semanticRed,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.semanticRed.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'DUE',
                                        style: AppTypography.label.copyWith(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                                  ),
                              ],
                            );
                          },
                          loading: () => Skeleton(height: 100, borderRadius: 32),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1),

                      const SizedBox(height: 24),


                      // Progress Cards
                      ref
                          .watch(lessonsStreamProvider)
                          .when(
                            data: (lessons) {
                              if (lessons.isEmpty) return const SizedBox();

                              // Group lessons by language
                              final groupedByLanguage = <String, List<Lesson>>{};
                              for (var lesson in lessons) {
                                groupedByLanguage
                                    .putIfAbsent(lesson.language, () => [])
                                    .add(lesson);
                              }

                              return Column(
                                children: groupedByLanguage.entries.map((entry) {
                                  final language = entry.key;
                                  final languageLessons = entry.value;

                                  // Sort lessons to find the current active one
                                  languageLessons.sort(
                                    (a, b) =>
                                        a.unitNumber.compareTo(b.unitNumber),
                                  );

                                  Lesson? currentLesson;
                                  double totalProgress = 0;

                                  for (var lesson in languageLessons) {
                                    final progressData =
                                        studentState.lessonProgress[lesson.id];
                                    final score =
                                        (progressData?['bestScore'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                    totalProgress += score / 100.0;

                                    if (score < 100 && currentLesson == null) {
                                      currentLesson = lesson;
                                    }
                                  }

                                  currentLesson ??= languageLessons.last;
                                  final overallProgress =
                                      totalProgress / languageLessons.length;
                                  final isLocked = _isLessonLocked(
                                    currentLesson,
                                    studentState.lessonProgress,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24.0,
                                      top: 16.0,
                                    ),
                                    child: _buildProgressCard(
                                      context,
                                      badge: currentLesson.category.toUpperCase(),
                                      badgeColor: _getCategoryColor(
                                        currentLesson.category,
                                      ),
                                      language: language,
                                      unit: currentLesson.title,
                                      progress: overallProgress.clamp(0.0, 1.0),
                                      icon: _getIconData(currentLesson.icon),
                                      accentColor: _getLanguageColor(language),
                                      hasButton: !isLocked,
                                      isLocked: isLocked,
                                      lessonId: currentLesson.id,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (err, _) =>
                                Text('Error loading lessons: $err'),
                          ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showXpDetailDialog(BuildContext context, StudentState student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextLevelXp = math.pow(student.level, 2).toInt() * 50;
    final currentLevelBaseXp = math.pow(student.level - 1, 2).toInt() * 50;
    final progressInLevel = student.xp - currentLevelBaseXp;
    final xpToNextLevel = nextLevelXp - student.xp;

    HapticService.medium();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DynamicGlassBox(
        borderRadius: 40,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.forest900.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              // Level Badge
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold500.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.gold500, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Text(
                  '${student.level}',
                  style: AppTypography.displayBold.copyWith(
                    color: AppColors.gold500,
                    fontSize: 48,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                student.levelTitle.toUpperCase(),
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 32),
              // XP Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROGRESS',
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white38 : AppColors.creamText3,
                    ),
                  ),
                  Text(
                    '$progressInLevel / ${nextLevelXp - currentLevelBaseXp} XP',
                    style: AppTypography.mono.copyWith(
                      color: isDark ? Colors.white70 : AppColors.forest700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              VineProgressBar(value: student.levelProgress, height: 16),
              const SizedBox(height: 16),
              Text(
                '${xpToNextLevel.clamp(0, 99999)} XP UNTIL NEXT LEVEL',
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white24 : AppColors.creamText3,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 40),
              // Breakdown Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'WISDOM BREAKDOWN',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // List of activities (Simulated history based on progress)
              _buildXpRow(
                context,
                'Lessons Mastered',
                '${student.lessonProgress.values.where((v) => v['completed'] == true).length}',
                Icons.menu_book_rounded,
              ),
              _buildXpRow(
                context,
                'Current Streak',
                '${student.displayedStreak} Days',
                Icons.local_fire_department_rounded,
              ),
              _buildXpRow(
                context,
                'Total Mist Crystals',
                '${student.mistCrystals}',
                Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: BrandButton(
                  text: 'CLOSE',
                  onTap: () => Navigator.pop(context),
                  type: BrandButtonType.secondary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpRow(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold500, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white70 : AppColors.forest700,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.mono.copyWith(
                color: AppColors.gold500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String sub,
    String emoji,
    VoidCallback? onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 160,
      child: GestureDetector(
        onTap: onTap,
        child: BrandCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.h1ExtraBold.copyWith(
                  color: isDark ? AppColors.gold500 : AppColors.forest500,
                  fontSize: 32,
                ),
              ),
              Text(
                sub,
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white54 : AppColors.creamText3,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context, {
    required String badge,
    required Color badgeColor,
    required String language,
    required String unit,
    required double progress,
    required IconData icon,
    required Color accentColor,
    required bool hasButton,
    required String lessonId,
    bool isLocked = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: BrandCard(
        padding: const EdgeInsets.all(32),
        borderRadius: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey : badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isLocked ? 'LOCKED' : badge,
                    style: AppTypography.label.copyWith(
                      color: isLocked
                          ? Colors.white
                          : (badgeColor.computeLuminance() > 0.5
                                ? Colors.black87
                                : Colors.white),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : icon,
                    color: isDark ? Colors.white70 : AppColors.forest500,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              language,
              style: AppTypography.h1ExtraBold.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  unit,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white54 : AppColors.forest700,
                    fontSize: 14,
                  ),
                ),
                if (!isLocked)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white70 : AppColors.forest900,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: isLocked ? 0.0 : progress,
                minHeight: 12,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation(
                  isLocked ? Colors.grey : accentColor,
                ),
              ),
            ),
            if (hasButton) ...[
              const SizedBox(height: 32),
              BrandButton(
                text: 'Continue Journey',
                onTap: () => context.push('/learning/path?lessonId=$lessonId'),
                type: BrandButtonType.primary,
                icon: Icons.arrow_forward_rounded,
              ),
            ],
            if (isLocked) ...[
              const SizedBox(height: 32),
              Text(
                'Unlock previous lessons to start this journey',
                style: AppTypography.label.copyWith(
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isLessonLocked(Lesson lesson, Map<String, dynamic> lessonProgress) {
    if (lesson.prerequisiteId == null || lesson.prerequisiteId!.isEmpty) {
      return false;
    }
    final prereqProgress = lessonProgress[lesson.prerequisiteId];
    return (prereqProgress?['bestScore'] ?? 0) < 100;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'basics':
        return const Color(0xFFC84E1A);
      case 'nature':
        return const Color(0xFF65A870);
      default:
        return AppColors.gold500;
    }
  }

  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'mansaka':
        return AppColors.gold500;
      case 'mandaya':
        return const Color(0xFF65A870);
      default:
        return AppColors.semanticBlue;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'psychology':
        return Icons.psychology;
      case 'local_florist':
        return Icons.local_florist;
      default:
        return Icons.school;
    }
  }
}




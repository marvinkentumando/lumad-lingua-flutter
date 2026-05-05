import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../providers/student_provider.dart';
import '../services/firebase_service.dart';
import '../models/lesson.dart';

class LearningHubScreen extends ConsumerWidget {
  const LearningHubScreen({super.key});

  void _showMistCrystalStore(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.forest900 : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final student = ref.watch(studentProvider);
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mist Crystal Store',
                            style: AppTypography.h1ExtraBold.copyWith(
                              color: AppColors.gold500,
                              fontSize: 28,
                            ),
                          ),
                          Text(
                            'Exchange your crystals for sacred items',
                            style: AppTypography.body.copyWith(
                              color: isDark ? Colors.white38 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '${student.mistCrystals}',
                              style: AppTypography.mono.copyWith(
                                color: AppColors.gold500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildStoreItem(
                          context,
                          ref,
                          title: 'Heart Refill',
                          description: 'Restore your hearts to full capacity.',
                          price: 50,
                          icon: Icons.favorite_rounded,
                          iconColor: AppColors.semanticRed,
                          onPurchase: () {
                            if (student.hearts < 5) {
                              ref
                                  .read(studentProvider.notifier)
                                  .spendMistCrystals(50);
                              ref.read(studentProvider.notifier).refillHearts();
                              return true;
                            }
                            return false;
                          },
                        ),
                        _buildStoreItem(
                          context,
                          ref,
                          title: 'Mountain Guide Map',
                          description: 'Unlock a hidden locale on the map.',
                          price: 200,
                          icon: Icons.map_rounded,
                          iconColor: AppColors.gold500,
                          onPurchase: () {
                            ref
                                .read(studentProvider.notifier)
                                .spendMistCrystals(200);
                            return true;
                          },
                        ),
                        _buildStoreItem(
                          context,
                          ref,
                          title: 'Streak Shield',
                          description:
                              'Protects your streak if you miss a day.',
                          price: 100,
                          icon: Icons.shield_rounded,
                          iconColor: AppColors.semanticBlue,
                          onPurchase: () {
                            try {
                              final user = ref
                                  .read(authServiceProvider)
                                  .currentUser;
                              if (user != null) {
                                ref
                                    .read(firebaseServiceProvider)
                                    .buyStreakShield(user.uid);
                                return true;
                              }
                            } catch (e) {
                              debugPrint("Purchase failed: $e");
                            }
                            return false;
                          },
                        ),
                        _buildStoreItem(
                          context,
                          ref,
                          title: 'Sacred Chant',
                          description:
                              'Unlock a special oral history in the gallery.',
                          price: 500,
                          icon: Icons.music_note_rounded,
                          iconColor: AppColors.gold500,
                          onPurchase: () {
                            ref
                                .read(studentProvider.notifier)
                                .spendMistCrystals(500);
                            return true;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStoreItem(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String description,
    required int price,
    required IconData icon,
    required Color iconColor,
    required bool Function() onPurchase,
  }) {
    final student = ref.watch(studentProvider);
    final canAfford = student.mistCrystals >= price;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BrandCard(
        theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.cream,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white38 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: canAfford
                  ? () {
                      if (onPurchase()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Purchased $title!'),
                            backgroundColor: AppColors.semanticGreen,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'You already have this or cannot use it now.',
                            ),
                            backgroundColor: AppColors.terracotta,
                          ),
                        );
                      }
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: canAfford
                      ? AppColors.gold500
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '$price',
                      style: AppTypography.label.copyWith(
                        color: canAfford
                            ? Colors.black
                            : (isDark ? Colors.white24 : Colors.black26),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '✨',
                      style: TextStyle(
                        fontSize: 12,
                        color: canAfford
                            ? Colors.black
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentState = ref.watch(studentProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
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
                            '${studentState.dailyStreak}',
                            'SUN TRAILS',
                            '🎉',
                            null,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            context,
                            'Mist Crystals',
                            '${studentState.mistCrystals}',
                            'EARNED',
                            '✨',
                            () => _showMistCrystalStore(context, ref),
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            context,
                            'Ancestral XP',
                            '${studentState.xp}',
                            'LEVEL UP',
                            '🔥',
                            null,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),

                    // Mastery Trends Entry Card
                    GestureDetector(
                      onTap: () => context.push('/mastery-dashboard'),
                      child: BrandCard(
                        theme: BrandCardTheme.gold,
                        padding: const EdgeInsets.all(24),
                        borderRadius: 32,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_graph_rounded,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Learning Progress',
                                    style: AppTypography.h3.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'View your mastery trends and SRS analytics',
                                    style: AppTypography.body.copyWith(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.black54,
                              size: 16,
                            ),
                          ],
                        ),
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
    return Expanded(
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

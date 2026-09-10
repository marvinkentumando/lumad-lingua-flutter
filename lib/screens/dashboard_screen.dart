import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../providers/role_provider.dart';
import '../widgets/vine_progress_bar.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/wotd_widget.dart';
import '../widgets/crystal_burst_animation.dart';
import '../widgets/skeleton.dart';
import '../widgets/branded_empty_state.dart';
import '../widgets/brand_background.dart';
import '../services/upload_queue_service.dart';
import '../providers/student_provider.dart';
import '../providers/quest_provider.dart';
import '../providers/artifact_provider.dart';
import '../models/quest.dart';
import '../services/haptic_service.dart';
import '../providers/learning_provider.dart';
import '../models/app_config.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showBurst = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
    Future.microtask(() {
      ref.read(questActionProvider.notifier).generateDynamicQuests();
      ref.read(artifactProgressProvider.notifier).syncArtifactProgress();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final student = ref.watch(studentProvider);
    final questsAsync = ref.watch(dailyQuestsProvider);
    final currentRole = ref.watch(roleProvider);

    final profile = profileAsync.value;
    final displayName = profile?['username'] ?? 'Tribe Member';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          body: BrandBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSyncIndicator(ref),
                    const SizedBox(height: 16),
                    _buildHeroBanner(context, displayName, student),
                    const SizedBox(height: 24),
                    if (currentRole == UserRole.learner) ...[
                      _buildStreakSummaryCard(context, student),
                      const SizedBox(height: 24),
                    ],
                    const WotdWidget(),
                    const SizedBox(height: 24),
                    if (currentRole == UserRole.learner) ...[
                      _buildDailyQuests(context, questsAsync, ref),
                      const SizedBox(height: 24),
                      _buildCurrentLessonCard(context),
                      const SizedBox(height: 24),
                      _buildChallengeHub(context),
                      const SizedBox(height: 24),
                    ],
                    _buildLeaderboardHeader(context),
                    const SizedBox(height: 16),
                    _buildClimbersList(context, ref),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showBurst)
          CrystalBurstAnimation(
            onComplete: () => setState(() => _showBurst = false),
          ),
      ],
    );
  }

  Widget _buildSyncIndicator(WidgetRef ref) {
    final isSyncing = ref.watch(uploadQueueProvider);
    if (!isSyncing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold500,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Syncing offline changes...',
            style: AppTypography.label.copyWith(
              color: AppColors.gold500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    String displayName,
    StudentState student,
  ) {
    return SizedBox(
      height: 270,
      child: BrandCard(
        theme: BrandCardTheme.gold,
        padding: EdgeInsets.zero,
        borderRadius: 32,
        child: Row(
          children: [
            // Text Content
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 28, top: 32, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Madyaw na\nallaw,\n$displayName!',
                      style: AppTypography.displayBold.copyWith(
                        color: AppColors.forest900,
                        fontSize: 34,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LEVEL ${student.level} \u2022 ${student.levelTitle.toUpperCase()}',
                      style: AppTypography.label.copyWith(
                        color: AppColors.forest700,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: student.levelProgress,
                        backgroundColor: AppColors.forest900.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.forest700,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Character Image / Waves GIF
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.topRight,
                child: Image.asset(
                  'assets/images/lumad_waves.gif',
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyQuests(
    BuildContext context,
    AsyncValue<List<Quest>> questsAsync,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TRIBAL CHALLENGES',
              style: AppTypography.label.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
            Row(
              children: [
                Text(
                  'RESET IN ${_getTimeUntilReset()}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500.withValues(alpha: 0.3),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    HapticService.light();
                    ref.read(questActionProvider.notifier).generateDynamicQuests();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 12),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  color: AppColors.gold500.withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        questsAsync.when(
          data: (quests) {
            if (quests.isEmpty) {
              return const BrandedEmptyState(
                title: 'No Rituals',
                message: 'No rituals today. Check back soon for more tribal challenges!',
                icon: Icons.event_busy_rounded,
              );
            }
            return Column(
              children: quests
                  .map(
                    (q) => _buildQuestItem(
                      quest: q,
                      onClaim: () {
                        ref.read(questActionProvider.notifier).claimReward(q);
                        HapticService.success();
                        setState(() => _showBurst = true);

                      },
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => _buildQuestSkeleton(),
          error: (err, _) => Text('Error loading rituals: $err'),
        ),
      ],
    );
  }

  Widget _buildQuestItem({
    required Quest quest,
    required VoidCallback onClaim,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = quest.isCompleted;
    final isClaimed = quest.isClaimed;

    IconData icon;
    switch (quest.type) {
      case QuestType.xp:
        icon = Icons.flash_on_rounded;
        break;
      case QuestType.pronunciation:
        icon = Icons.mic_external_on_rounded;
        break;
      case QuestType.lesson:
        icon = Icons.auto_stories_rounded;
        break;
      case QuestType.flashcard:
        icon = Icons.style_rounded;
        break;
    }

    return GestureDetector(
      onTap: (isDone && !isClaimed) ? onClaim : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isClaimed
              ? AppColors.gold500.withValues(alpha: 0.02)
              : (isDone
                    ? AppColors.gold500.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isClaimed
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.creamBorder)
                : (isDone
                      ? AppColors.gold500.withValues(alpha: 0.3)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.creamBorder)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isClaimed
                    ? Colors.white.withValues(alpha: 0.05)
                    : (isDone
                          ? AppColors.gold500
                          : Colors.white.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isClaimed
                    ? Icons.done_all_rounded
                    : (isDone ? Icons.card_giftcard_rounded : icon),
                color: isDone ? Colors.black : AppColors.gold500,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: AppTypography.h3.copyWith(
                      color: isClaimed
                        ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      decoration: isClaimed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    quest.description,
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  if (!isClaimed) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: quest.progress,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone
                              ? AppColors.gold500
                              : AppColors.gold500.withValues(alpha: 0.5),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${quest.current}/${quest.target}',
                  style: AppTypography.mono.copyWith(
                    color: isDone
                        ? AppColors.gold500
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${quest.reward} ✨',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeHub(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHALLENGE HUB',
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildChallengeCard(
                context,
                title: 'Scenario Stories',
                subtitle: 'Choose your path',
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFF2D4F3C),
                route: '/scenario-hub',
              ),
              const SizedBox(width: 16),
              _buildChallengeCard(
                context,
                title: 'Lingua Duel',
                subtitle: 'P2P Battle',
                icon: Icons.bolt_rounded,
                color: const Color(0xFF4F3422),
                route: '/lingua-duel',
              ),
              const SizedBox(width: 16),
              _buildChallengeCard(
                context,
                title: 'Saka',
                subtitle: 'The Ascent',
                icon: Icons.terrain_rounded,
                color: const Color(0xFF6B4226),
                route: '/saka-game',
              ),
              const SizedBox(width: 16),
              _buildChallengeCard(
                context,
                title: 'Shadowing',
                subtitle: 'Audio Compare',
                icon: Icons.mic_external_on_rounded,
                color: const Color(0xFF4A2C2C),
                route: '/audio-comparison',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push(route);
      },

      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.body.copyWith(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLessonCard(BuildContext context) {
    final latestAsync = ref.watch(latestLessonProvider);
    final detailsAsync = ref.watch(latestLessonDetailsProvider);

    return detailsAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return _buildStartJourneyCard(context);
        }

        final progressData = latestAsync.value?['data'] ?? {};
        final stars = progressData['stars'] ?? 0;
        final progress = stars / 3.0;

        return BrandCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'CURRENT LESSON',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold500,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                lesson.title,
                style: AppTypography.h1ExtraBold.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lesson.description,
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lesson Progress',
                    style: AppTypography.label.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: AppTypography.mono.copyWith(
                      color: AppColors.gold500,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              VineProgressBar(value: progress),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: BrandButton(
                  text: progress >= 1.0 ? 'REVIEW ASCENT' : 'CONTINUE ASCENT',
                  onTap: () {
                    HapticService.light();
                    context.go('/learning/path');
                  },
                  type: BrandButtonType.primary,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.gold500),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStartJourneyCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BrandCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Your Journey',
            style: AppTypography.h1ExtraBold.copyWith(
              color: isDark ? Colors.white : AppColors.forest700,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Begin your ascent into the highlands and discover the Lumad heritage.',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white38 : AppColors.creamText2,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: BrandButton(
              text: 'START UNIT 1',
              onTap: () => context.go('/learning'),
              type: BrandButtonType.primary,
              icon: Icons.explore_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Climbers',
              style: AppTypography.h2ExtraBold.copyWith(
                color: AppColors.gold500,
              ),
            ),
            Text(
              'The season\'s most active botanical archivists.',
              style: AppTypography.body.copyWith(
                color: Colors.white24,
                fontSize: 12,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => context.push('/leaderboard'),
          child: Text(
            'VIEW ALL',
            style: AppTypography.label.copyWith(
              color: AppColors.gold500,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClimbersList(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topLearnersAsync = ref.watch(topLearnersProvider);
    final config = ref.watch(appConfigProvider).value;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
      ),
      child: topLearnersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const BrandedEmptyState(
              title: 'Quiet Mountains',
              message: 'No climbers yet! Be the first to start the ascent.',
              icon: Icons.terrain_rounded,
            );
          }
          // Only show top 3 on dashboard
          final top3 = users.take(3).toList();
          return Column(
            children: top3.asMap().entries.map((entry) {
              return _buildClimberRow(context, entry.value, entry.key + 1, config);
            }).toList(),
          );
        },
        loading: () => _buildClimberSkeleton(),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClimberSkeleton() {
    return Column(
      children: List.generate(3, (i) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Skeleton(width: 24, height: 16),
            SizedBox(width: 12),
            Skeleton(width: 48, height: 48, borderRadius: 12),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 120, height: 16),
                  SizedBox(height: 4),
                  Skeleton(width: 80, height: 12),
                ],
              ),
            ),
            Skeleton(width: 60, height: 16),
          ],
        ),
      )),
    );
  }

  Widget _buildQuestSkeleton() {
    return Column(
      children: List.generate(2, (i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Row(
          children: [
            Skeleton(width: 40, height: 40, borderRadius: 12),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 150, height: 16),
                  SizedBox(height: 4),
                  Skeleton(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  String _getLevelTitle(int xp, AppConfig? config) {
    if (config == null) {
      final level = (math.sqrt(xp / 50)).floor() + 1;
      if (level < 5) return "Novice Shaman";
      if (level < 10) return "Spiritual Seeker";
      if (level < 20) return "Tribal Guardian";
      if (level < 40) return "Ancestral Sage";
      return "Elder Guardian";
    }

    final sortedThresholds = config.spiritThresholds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedThresholds) {
      if (xp >= entry.value) {
        return entry.key;
      }
    }
    return "Seeker";
  }

  Widget _buildClimberRow(
    BuildContext context,
    Map<String, dynamic> user,
    int rank,
    AppConfig? config,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = user['username'] ?? user['name'] ?? 'Anonymous';
    final xp = user['xp'] ?? 0;
    final avatarUrl = user['photoURL'] ?? user['avatarUrl'];
    final title = _getLevelTitle(xp, config);
    final userId = user['uid'];

    return InkWell(
      onTap: userId != null
          ? () {
              HapticService.light();
              context.push('/member/$userId');
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: AppTypography.mono.copyWith(
                  color: isDark ? Colors.white24 : AppColors.creamText3,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.white10 : Colors.black12,
                image: avatarUrl != null
                    ? DecorationImage(
                        image: avatarUrl.startsWith('http')
                            ? NetworkImage(avatarUrl) as ImageProvider
                            : AssetImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: AppTypography.h3.copyWith(color: Colors.white24),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  '$xp',
                  style: AppTypography.mono.copyWith(
                    color: isDark ? AppColors.gold500 : AppColors.forest500,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'ARCHIVE XP',
                  style: AppTypography.label.copyWith(
                    color: isDark ? Colors.white10 : Colors.black12,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSummaryCard(BuildContext context, StudentState student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/streak');
      },
      child: BrandCard(
        theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: isDark ? AppColors.gold500.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                  size: 48,
                ).animate(onPlay: (c) => c.repeat()).scale(end: const Offset(1.2, 1.2)),
                Icon(
                  Icons.local_fire_department_rounded,
                  color: isDark ? AppColors.gold500 : Colors.black,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.displayedStreak} DAYS',
                    style: AppTypography.h3.copyWith(
                      color: isDark ? Colors.white : AppColors.forest900, 
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Keep the flame alive!',
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white70 : AppColors.forest700, 
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              color: isDark ? Colors.white24 : Colors.black26, 
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeUntilReset() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final hours = diff.inHours;
    if (hours > 0) return '${hours}H';
    final minutes = diff.inMinutes;
    return '${minutes}M';
  }
}


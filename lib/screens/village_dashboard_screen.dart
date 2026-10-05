import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_shimmer_skeleton.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../models/broadcast.dart';
import '../models/educator_models.dart';
import '../providers/learning_provider.dart';
import '../utils/app_localization.dart';

class VillageDashboardScreen extends ConsumerWidget {
  const VillageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final userProfile = ref.watch(userProfileProvider).value;
    final educatorId = userProfile?['educatorId'] as String?;
    final l10n = ref.watch(localizationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null || educatorId == null || educatorId.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
        body: BrandBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fort_rounded, size: 64, color: AppColors.gold500),
                    const SizedBox(height: 16),
                    Text(
                      l10n.translate('not_in_village'),
                      style: AppTypography.h2.copyWith(color: AppColors.gold500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('join_village_instructions'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => context.pop(),
                      child: Text(l10n.translate('back_to_profile')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final educatorProfileAsync = ref.watch(otherUserProfileProvider(educatorId));
    final leaderboardAsync = ref.watch(villageTopLearnersProvider(educatorId));
    final broadcastsAsync = ref.watch(villageBroadcastsProvider(educatorId));
    final assignedQuizzesAsync = ref.watch(assignedVillageMiniQuizzesProvider(educatorId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, ref, user.uid, educatorProfileAsync, l10n, isDark),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold500,
                  backgroundColor: isDark ? AppColors.forest800 : AppColors.creamBg,
                  onRefresh: () async {
                    HapticService.selection();
                    ref.invalidate(userProfileProvider);
                    ref.invalidate(otherUserProfileProvider(educatorId));
                    ref.invalidate(villageTopLearnersProvider(educatorId));
                    ref.invalidate(villageBroadcastsProvider(educatorId));
                    ref.invalidate(assignedVillageMiniQuizzesProvider(educatorId));
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVillageHeaderBanner(context, educatorProfileAsync, leaderboardAsync, l10n, isDark),
                        const SizedBox(height: 24),
                        _buildAnnouncementsSection(context, broadcastsAsync, l10n, isDark),
                        const SizedBox(height: 24),
                        _buildAssignedMiniQuizzesSection(context, ref, assignedQuizzesAsync, l10n, isDark),
                        const SizedBox(height: 24),
                        _buildVillageLeaderboardSection(context, user.uid, leaderboardAsync, l10n, isDark),
                        const SizedBox(height: 32),
                      ],
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

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AsyncValue<Map<String, dynamic>?> educatorProfileAsync,
    AppLocalization l10n,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold500),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.translate('village_sanctuary_title'),
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                letterSpacing: 2,
                fontSize: 15,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
            ),
            color: isDark ? AppColors.forest800 : AppColors.creamBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'leave') {
                _confirmLeaveVillage(context, ref, userId, l10n, isDark);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app_rounded, color: AppColors.semanticRed, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.translate('leave_village'),
                      style: const TextStyle(color: AppColors.semanticRed),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVillageHeaderBanner(
    BuildContext context,
    AsyncValue<Map<String, dynamic>?> educatorProfileAsync,
    AsyncValue<List<Map<String, dynamic>>> leaderboardAsync,
    AppLocalization l10n,
    bool isDark,
  ) {
    return educatorProfileAsync.when(
      loading: () => const AppShimmerSkeleton(height: 160),
      error: (e, _) => BrandCard(
        theme: isDark ? BrandCardTheme.gold : BrandCardTheme.vibrant,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '${l10n.translate('unable_load_village_details')} $e',
            style: TextStyle(color: isDark ? Colors.white : AppColors.forest900),
          ),
        ),
      ),
      data: (educator) {
        final educatorName = educator?['fullName'] ?? educator?['username'] ?? educator?['name'] ?? 'Educator';
        final villageCode = educator?['villageCode'] ?? '------';
        final villageName = educator?['villageName'] ?? l10n.translate('educators_tribe', params: {'name': educatorName});

        final memberCount = leaderboardAsync.value?.length ?? 0;
        final totalXp = leaderboardAsync.value?.fold<int>(0, (acc, item) => acc + ((item['xp'] as num?)?.toInt() ?? 0)) ?? 0;

        return BrandCard(
          theme: isDark ? BrandCardTheme.gold : BrandCardTheme.vibrant,
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold500, width: 2),
                    ),
                    child: const Icon(Icons.fort_rounded, color: AppColors.gold500, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          villageName,
                          style: AppTypography.h2.copyWith(color: AppColors.gold500, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.translate('led_by', params: {'name': educatorName}),
                          style: AppTypography.body.copyWith(
                            color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                color: isDark ? Colors.white12 : AppColors.forest900.withValues(alpha: 0.1),
                height: 1,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatPill(
                    icon: Icons.group_rounded,
                    label: l10n.translate('members_caps'),
                    value: '$memberCount',
                    isDark: isDark,
                  ),
                  _buildStatPill(
                    icon: Icons.bolt_rounded,
                    label: l10n.translate('tribe_xp'),
                    value: '$totalXp',
                    isDark: isDark,
                  ),
                  InkWell(
                    onTap: () {
                      HapticService.success();
                      Clipboard.setData(ClipboardData(text: villageCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.translate('village_code_copied')),
                          backgroundColor: AppColors.semanticGreen,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : AppColors.gold500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.key_rounded, color: AppColors.gold500, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            villageCode,
                            style: AppTypography.labelBold.copyWith(color: AppColors.gold500, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy_rounded,
                            color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.4),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.05);
      },
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold500, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
            Text(
              value,
              style: AppTypography.labelBold.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnouncementsSection(
    BuildContext context,
    AsyncValue<List<VillageBroadcast>> broadcastsAsync,
    AppLocalization l10n,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign_rounded, color: AppColors.gold500, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.translate('village_announcements'),
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        broadcastsAsync.when(
          loading: () => const AppShimmerSkeleton(height: 100),
          error: (e, _) => Text(
            '${l10n.translate('error_loading_announcements')} $e',
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
            ),
          ),
          data: (broadcasts) {
            if (broadcasts.isEmpty) {
              return BrandCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.translate('quiet_village_no_announcements'),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final visibleBroadcasts = broadcasts.take(3).toList();

            return Column(
              children: [
                ...visibleBroadcasts.map((b) => _buildAnnouncementCard(b, l10n, isDark)),
                if (broadcasts.length > 3) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold500,
                        side: const BorderSide(color: AppColors.gold500, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.campaign_outlined, size: 18),
                      label: Text(
                        '${l10n.translate('view_all_announcements')} (${broadcasts.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        HapticService.selection();
                        _showAllBroadcastsBottomSheet(context, broadcasts, l10n, isDark);
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAllBroadcastsBottomSheet(
    BuildContext context,
    List<VillageBroadcast> broadcasts,
    AppLocalization l10n,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: AppColors.gold500, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            l10n.translate('village_announcements'),
                            style: AppTypography.h2.copyWith(color: AppColors.gold500, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.7),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: broadcasts.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _buildAnnouncementCard(broadcasts[index], l10n, isDark);
                      },
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

  Widget _buildAnnouncementCard(VillageBroadcast broadcast, AppLocalization l10n, bool isDark) {
    final timeAgo = _formatRelativeTime(broadcast.timestamp, l10n);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: BrandCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.gold500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.black, size: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      broadcast.educatorName.isNotEmpty
                          ? broadcast.educatorName
                          : l10n.translate('researcher_educator'),
                      style: AppTypography.labelBold.copyWith(color: AppColors.gold500, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  timeAgo,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              broadcast.message,
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedMiniQuizzesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<VillageMiniQuiz>> quizzesAsync,
    AppLocalization l10n,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_turned_in_rounded, color: AppColors.gold500, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.translate('village_sanctuary_assessments'),
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        quizzesAsync.when(
          loading: () => const AppShimmerSkeleton(height: 100),
          error: (e, _) => Text(
            '${l10n.translate('error_loading_quizzes')} $e',
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
            ),
          ),
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return BrandCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.translate('no_quizzes_assigned'),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: quizzes.map((q) => _buildMiniQuizCard(context, ref, q, l10n, isDark)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniQuizCard(
    BuildContext context,
    WidgetRef ref,
    VillageMiniQuiz quiz,
    AppLocalization l10n,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: BrandCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${quiz.dialect.toUpperCase()} • ${quiz.tasks.length} ${l10n.translate('questions_caps')}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatRelativeTime(quiz.createdAt, l10n),
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.forest900,
                fontSize: 16,
              ),
            ),
            if (quiz.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                quiz.description,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold500,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  l10n.translate('take_assessment'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  HapticService.selection();
                  ref.read(quizSessionProvider.notifier).loadTasks(quiz.tasks);
                  context.push('/lesson_session');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVillageLeaderboardSection(
    BuildContext context,
    String currentUserId,
    AsyncValue<List<Map<String, dynamic>>> leaderboardAsync,
    AppLocalization l10n,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.gold500, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.translate('tribe_rankings'),
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        leaderboardAsync.when(
          loading: () => const AppShimmerSkeleton(height: 200),
          error: (e, _) => Text(
            '${l10n.translate('error_loading_leaderboard')} $e',
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
            ),
          ),
          data: (members) {
            if (members.isEmpty) {
              return BrandCard(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    l10n.translate('no_members_in_village'),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: members.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final member = entry.value;
                final isMe = member['uid'] == currentUserId;

                return _buildMemberRankCard(context, rank, member, isMe, l10n, isDark);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMemberRankCard(
    BuildContext context,
    int rank,
    Map<String, dynamic> member,
    bool isMe,
    AppLocalization l10n,
    bool isDark,
  ) {
    final name = member['username'] ?? member['fullName'] ?? member['name'] ?? 'Tribe Member';
    final xp = (member['xp'] as num?)?.toInt() ?? 0;
    final streak = (member['dailyStreak'] as num?)?.toInt() ?? 0;
    final photoUrl = member['photoURL'] as String?;

    Widget rankWidget;

    if (rank == 1) {
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 20));
    } else if (rank == 2) {
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 20));
    } else if (rank == 3) {
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 20));
    } else {
      rankWidget = Text(
        '#$rank',
        style: AppTypography.labelBold.copyWith(
          color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.gold500.withValues(alpha: 0.15)
            : (isDark ? AppColors.forest800.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.gold500
              : (isDark ? Colors.white12 : AppColors.forest900.withValues(alpha: 0.1)),
          width: isMe ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: rankWidget)),
          const SizedBox(width: 12),
          ProfileAvatar(
            photoUrl: photoUrl,
            radius: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTypography.labelBold.copyWith(
                          color: isMe
                              ? AppColors.gold500
                              : (isDark ? Colors.white : AppColors.forest900),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold500,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.translate('you'),
                          style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                if (streak > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '$streak ${l10n.translate('day_streak_label')}',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.gold500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.gold500, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$xp XP',
                  style: AppTypography.labelBold.copyWith(color: AppColors.gold500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(dynamic timestamp, AppLocalization l10n) {
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return l10n.translate('recently');
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.translate('just_now');
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  void _confirmLeaveVillage(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AppLocalization l10n,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.translate('leave_village_title'),
          style: AppTypography.h2.copyWith(color: AppColors.gold500),
        ),
        content: Text(
          l10n.translate('leave_village_desc'),
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n.translate('cancel'),
              style: TextStyle(
                color: isDark ? Colors.white38 : AppColors.forest900.withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
            onPressed: () async {
              HapticService.delete();
              Navigator.pop(dialogCtx);
              try {
                await ref.read(firebaseServiceProvider).leaveVillage(userId);
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('left_village_msg')),
                      backgroundColor: AppColors.gold500,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  HapticService.error();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.translate('error_leaving_village')} $e'),
                      backgroundColor: AppColors.semanticRed,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.translate('leave_village'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

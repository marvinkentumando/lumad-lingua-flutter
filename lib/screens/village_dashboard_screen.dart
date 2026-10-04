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

    if (user == null || educatorId == null || educatorId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.forest900,
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
                      'Not in a Village',
                      style: AppTypography.h2.copyWith(color: AppColors.gold500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join a community village using a code provided by your educator.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => context.pop(),
                      child: const Text('BACK TO PROFILE'),
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
              _buildTopBar(context, ref, user.uid, educatorProfileAsync, l10n),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVillageHeaderBanner(context, educatorProfileAsync, leaderboardAsync, l10n),
                      const SizedBox(height: 24),
                      _buildAnnouncementsSection(context, broadcastsAsync, l10n),
                      const SizedBox(height: 24),
                      _buildAssignedMiniQuizzesSection(context, ref, assignedQuizzesAsync),
                      const SizedBox(height: 24),
                      _buildVillageLeaderboardSection(context, user.uid, leaderboardAsync, l10n),
                      const SizedBox(height: 32),
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

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AsyncValue<Map<String, dynamic>?> educatorProfileAsync,
    AppLocalization l10n,
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
              'VILLAGE SANCTUARY 🌿',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                letterSpacing: 2,
                fontSize: 15,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            color: AppColors.forest800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'leave') {
                _confirmLeaveVillage(context, ref, userId, l10n);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, color: AppColors.semanticRed, size: 20),
                    SizedBox(width: 8),
                    Text('Leave Village', style: TextStyle(color: AppColors.semanticRed)),
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
  ) {
    return educatorProfileAsync.when(
      loading: () => const AppShimmerSkeleton(height: 160),
      error: (e, _) => BrandCard(
        theme: BrandCardTheme.gold,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Unable to load village details: $e', style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (educator) {
        final educatorName = educator?['fullName'] ?? educator?['username'] ?? educator?['name'] ?? 'Educator';
        final villageCode = educator?['villageCode'] ?? '------';
        final villageName = educator?['villageName'] ?? '$educatorName\'s Tribe';

        final memberCount = leaderboardAsync.value?.length ?? 0;
        final totalXp = leaderboardAsync.value?.fold<int>(0, (acc, item) => acc + ((item['xp'] as num?)?.toInt() ?? 0)) ?? 0;

        return BrandCard(
          theme: BrandCardTheme.gold,
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
                          'Led by $educatorName',
                          style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatPill(
                    icon: Icons.group_rounded,
                    label: 'MEMBERS',
                    value: '$memberCount',
                  ),
                  _buildStatPill(
                    icon: Icons.bolt_rounded,
                    label: 'TRIBE XP',
                    value: '$totalXp',
                  ),
                  InkWell(
                    onTap: () {
                      HapticService.success();
                      Clipboard.setData(ClipboardData(text: villageCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Village code copied to clipboard! 📋'),
                          backgroundColor: AppColors.semanticGreen,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
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
                          const Icon(Icons.copy_rounded, color: Colors.white38, size: 12),
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
              style: AppTypography.caption.copyWith(color: Colors.white38, fontSize: 9, letterSpacing: 1),
            ),
            Text(
              value,
              style: AppTypography.labelBold.copyWith(color: Colors.white, fontSize: 13),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign_rounded, color: AppColors.gold500, size: 20),
            const SizedBox(width: 8),
            Text(
              'VILLAGE ANNOUNCEMENTS',
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
          error: (e, _) => Text('Error loading announcements: $e', style: const TextStyle(color: Colors.white38)),
          data: (broadcasts) {
            if (broadcasts.isEmpty) {
              return BrandCard(
                padding: const EdgeInsets.all(20),
                child: const Row(
                  children: [
                    Text('🌿', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'The village is quiet. No announcements from your educator yet.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: broadcasts.take(3).map((b) => _buildAnnouncementCard(b)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(VillageBroadcast broadcast) {
    final timeAgo = _formatRelativeTime(broadcast.timestamp);

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
                      broadcast.educatorName.isNotEmpty ? broadcast.educatorName : 'Educator',
                      style: AppTypography.labelBold.copyWith(color: AppColors.gold500, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  timeAgo,
                  style: AppTypography.caption.copyWith(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              broadcast.message,
              style: AppTypography.body.copyWith(color: Colors.white, fontSize: 14, height: 1.4),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_turned_in_rounded, color: AppColors.gold500, size: 20),
            const SizedBox(width: 8),
            Text(
              'VILLAGE SANCTUARY ASSESSMENTS',
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
          error: (e, _) => Text('Error loading quizzes: $e', style: const TextStyle(color: Colors.white38)),
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return BrandCard(
                padding: const EdgeInsets.all(20),
                child: const Row(
                  children: [
                    Text('🎯', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'No custom mini-quizzes assigned by your educator at this time.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: quizzes.map((q) => _buildMiniQuizCard(context, ref, q)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniQuizCard(BuildContext context, WidgetRef ref, VillageMiniQuiz quiz) {
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
                    '${quiz.dialect.toUpperCase()} • ${quiz.tasks.length} QUESTIONS',
                    style: AppTypography.label.copyWith(
                      color: AppColors.gold500,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatRelativeTime(quiz.createdAt),
                  style: AppTypography.caption.copyWith(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 16),
            ),
            if (quiz.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                quiz.description,
                style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 13),
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
                label: const Text('TAKE ASSESSMENT', style: TextStyle(fontWeight: FontWeight.bold)),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.gold500, size: 20),
            const SizedBox(width: 8),
            Text(
              'TRIBE RANKINGS',
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
          error: (e, _) => Text('Error loading leaderboard: $e', style: const TextStyle(color: Colors.white38)),
          data: (members) {
            if (members.isEmpty) {
              return BrandCard(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: Text(
                    'No members found in this village yet.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }

            return Column(
              children: members.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final member = entry.value;
                final isMe = member['uid'] == currentUserId;

                return _buildMemberRankCard(context, rank, member, isMe);
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
        style: AppTypography.labelBold.copyWith(color: Colors.white54, fontSize: 14),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.gold500.withValues(alpha: 0.15)
            : AppColors.forest800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppColors.gold500 : Colors.white12,
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
                          color: isMe ? AppColors.gold500 : Colors.white,
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
                        child: const Text(
                          'YOU',
                          style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
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
                        '$streak Day Streak',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
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
              color: Colors.black.withValues(alpha: 0.3),
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

  String _formatRelativeTime(dynamic timestamp) {
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'Recently';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
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
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.forest900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Leave Village?', style: AppTypography.h2.copyWith(color: AppColors.gold500)),
        content: const Text(
          'Are you sure you want to leave this village community? You will need a new village code to rejoin.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
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
                    const SnackBar(
                      content: Text('You have left the village.'),
                      backgroundColor: AppColors.gold500,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  HapticService.error();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error leaving village: $e'), backgroundColor: AppColors.semanticRed),
                  );
                }
              }
            },
            child: const Text('LEAVE VILLAGE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

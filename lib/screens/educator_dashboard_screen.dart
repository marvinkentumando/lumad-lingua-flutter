import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/admin_models.dart';
import '../models/lesson.dart';
import '../models/dictionary_entry.dart';
import '../models/community_activity.dart';
import '../widgets/wotd_widget.dart';

class EducatorDashboardScreen extends ConsumerStatefulWidget {
  const EducatorDashboardScreen({super.key});

  @override
  ConsumerState<EducatorDashboardScreen> createState() =>
      _EducatorDashboardScreenState();
}

class _FeedItem {
  final String text;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _FeedItem({
    required this.text,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _EducatorDashboardScreenState
    extends ConsumerState<EducatorDashboardScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  String _greeting(String username) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Maayong Buntag,';
    if (hour < 18) return 'Maayong Hapon,';
    return 'Maayong Gabii,';
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final userAuth = ref.watch(authStateProvider).value;
    final notificationsAsync = userAuth != null
        ? ref.watch(userNotificationsStreamProvider(userAuth.uid))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);
    final lessonsAsync = ref.watch(allLessonsStreamProvider);
    final allUsersAsync = ref.watch(allUsersProvider);
    final totalWordsAsync = ref.watch(totalWordsCountProvider);
    final communityActivitiesAsync = ref.watch(communityFeedProvider);
    final pendingSubmissionsAsync = ref.watch(
      pendingDictionaryStreamProvider(const ValidatorQuery('all', 10)),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allLessonsStreamProvider);
            ref.invalidate(allUsersProvider);
            ref.invalidate(totalWordsCountProvider);
            ref.invalidate(communityFeedProvider);
            await Future.delayed(const Duration(seconds: 1));
          },
          color: AppColors.gold500,
          backgroundColor: isDark ? AppColors.forest800 : Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeroBanner(userProfileAsync, notificationsAsync),
                const SizedBox(height: 24),
                const WotdWidget(),
                const SizedBox(height: 32),
                _buildStatsRow(lessonsAsync, allUsersAsync),
                const SizedBox(height: 24),
                _buildQuickActions(allUsersAsync, userProfileAsync),
                const SizedBox(height: 32),
                _buildStrugglingStudentsAlert(allUsersAsync),
                const SizedBox(height: 24),
                _buildCulturalMilestone(totalWordsAsync),
                const SizedBox(height: 24),
                _buildUpcomingDeadlines(lessonsAsync),
                const SizedBox(height: 24),
                _buildRecentActivity(
                  allUsersAsync,
                  communityActivitiesAsync,
                  pendingSubmissionsAsync,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/lesson-editor'),
        backgroundColor: AppColors.gold500,
        child: const Icon(Icons.add_rounded, color: AppColors.forest900),
      ),
    );
  }

  Widget _buildHeroBanner(
    AsyncValue<Map<String, dynamic>?> profileAsync,
    AsyncValue<List<Map<String, dynamic>>> notifsAsync,
  ) {
    final profile = profileAsync.value;
    final name = profile?['username'] as String? ?? 'Educator';
    final unreadCount =
        notifsAsync.value?.where((n) => n['isRead'] == false).length ?? 0;

    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting(name)}\n$name',
                      style: AppTypography.displayBold.copyWith(
                        color: Colors.black,
                        fontSize: 32,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'WISDOM GUIDE  •  ELDER EDUCATOR',
                        style: AppTypography.label.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: isDark ? AppColors.gold500 : AppColors.forest900,
                  size: 36,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black.withValues(alpha: 0.4),
                    size: 24,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.semanticRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    AsyncValue<List<Lesson>> lessonsAsync,
    AsyncValue<List<AdminUser>> usersAsync,
  ) {
    int total = 0;
    int live = 0;
    int drafts = 0;

    if (lessonsAsync.hasValue) {
      final lessons = lessonsAsync.value!;
      total = lessons.length;
      live = lessons.where((l) => l.status == 'PUBLISHED').length;
      drafts = lessons.where((l) => l.status == 'DRAFT').length;
    }

    String studentsCount = '0';
    if (usersAsync.hasValue) {
      final students = usersAsync.value!
          .where((u) => u.role == 'learner')
          .length;
      studentsCount = students >= 1000
          ? '${(students / 1000).toStringAsFixed(1)}k'
          : students.toString();
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'TOTAL',
            total.toString(),
            Icons.auto_stories_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'LIVE',
            live.toString(),
            Icons.rocket_launch_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'DRAFTS',
            drafts.toString(),
            Icons.edit_document,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('STUDENTS', studentsCount, Icons.group_rounded),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return BrandCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold500.withValues(alpha: 0.5), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h2.copyWith(
              color: isDark ? Colors.white : AppColors.creamText,
            ),
          ),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white24 : AppColors.creamText3,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    AsyncValue<List<AdminUser>> allUsersAsync,
    AsyncValue<Map<String, dynamic>?> userProfileAsync,
  ) {
    return Column(
      children: [
        Row(
          children: [
            _buildQuickActionBtn(Icons.campaign_rounded, 'Broadcast', () {
              _showBroadcastDialog(allUsersAsync, userProfileAsync);
            }),
            const SizedBox(width: 12),
            _buildQuickActionBtn(Icons.perm_media_rounded, 'Gallery', () {
              context.push('/gallery');
            }),
            const SizedBox(width: 12),
            _buildQuickActionBtn(Icons.insights_rounded, 'Analytics', () {
              context.go('/educator/analytics');
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildQuickActionBtn(Icons.swap_vert_rounded, 'Manage Units', () {
              context.push('/educator/unit-management');
            }),
            const SizedBox(width: 12),
            _buildQuickActionBtn(
              Icons.add_circle_outline_rounded,
              'Create Lesson',
              () {
                context.push('/lesson-editor');
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showBroadcastDialog(
    AsyncValue<List<AdminUser>> allUsersAsync,
    AsyncValue<Map<String, dynamic>?> profileAsync,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.forestDarkCard : Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Village Broadcast',
              style: AppTypography.h3.copyWith(
                color: isDark ? Colors.white : AppColors.creamText,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/educator/broadcast-history');
              },
              icon: const Icon(Icons.history_rounded, color: AppColors.gold500),
              tooltip: 'Broadcast History',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send a message to all your students.',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white70 : AppColors.creamText2,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.creamText,
              ),
              decoration: InputDecoration(
                hintText: 'Type your announcement here...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : AppColors.creamText3,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.forest800
                    : AppColors.creamBg.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.transparent : AppColors.creamBorder,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.creamText3,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold500,
              foregroundColor: AppColors.forest900,
            ),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final msg = controller.text.trim();
              Navigator.pop(ctx);

              if (allUsersAsync.hasValue && profileAsync.hasValue) {
                final educator = profileAsync.value;
                final educatorId = educator?['uid'] ?? educator?['id'] ?? '';
                final educatorName = educator?['username'] ?? 'Educator';

                final studentIds = allUsersAsync.value!
                    .where((u) => u.role == 'learner')
                    .map((u) => u.id)
                    .toList();

                try {
                  await ref
                      .read(firebaseServiceProvider)
                      .sendVillageBroadcast(
                        educatorId: educatorId,
                        educatorName: educatorName,
                        title: 'Announcement from Educator',
                        message: msg,
                        studentIds: studentIds,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Announcement sent to ${studentIds.length} students!',
                        ),
                        backgroundColor: AppColors.semanticGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send broadcast: $e'),
                        backgroundColor: AppColors.semanticRed,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Send Broadcast',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forestDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.creamBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.gold500, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white54 : AppColors.creamText2,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrugglingStudentsAlert(
    AsyncValue<List<AdminUser>> allUsersAsync,
  ) {
    if (!allUsersAsync.hasValue) return const SizedBox.shrink();

    // Simple heuristic for struggling students: zero XP or hasn't logged in recently, just an example proxy
    final struggling = allUsersAsync.value!
        .where((u) => u.role == 'learner' && u.xp < 50)
        .toList();

    if (struggling.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        context.go('/educator/students');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.semanticRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.semanticRed.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.semanticRed,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attention Needed',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.semanticRed,
                    ),
                  ),
                  Text(
                    '${struggling.length} student${struggling.length > 1 ? 's' : ''} might be falling behind based on recent activity.',
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white70 : AppColors.creamText2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.semanticRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'VIEW',
                style: AppTypography.label.copyWith(
                  color: AppColors.semanticRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCulturalMilestone(AsyncValue<int> totalWordsAsync) {
    final wordsCount = totalWordsAsync.value ?? 0;
    // Assume milestone goal is next multiple of 100
    final target = ((wordsCount / 100).floor() + 1) * 100;
    final progress = (wordsCount % 100) / 100.0;
    final remaining = target - wordsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Village Milestone'),
        const SizedBox(height: 12),
        BrandCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dictionary Expansion',
                    style: AppTypography.h3.copyWith(
                      color: isDark ? Colors.white : AppColors.creamText,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTypography.h3.copyWith(color: AppColors.gold500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold500,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$remaining more words until the community unlocks the next milestone.',
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white38 : AppColors.creamText3,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingDeadlines(AsyncValue<List<Lesson>> lessonsAsync) {
    if (!lessonsAsync.hasValue) return const SizedBox.shrink();

    // Fetch actual drafts or pending lessons from Firestore
    final drafts = lessonsAsync.value!
        .where((l) => l.status == 'DRAFT')
        .take(3)
        .toList();
    if (drafts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pending Tasks'),
        const SizedBox(height: 12),
        ...drafts.map(
          (d) => _buildDeadlineItem({
            'title': 'Review "${d.title}" draft',
            'due': 'Needs completion',
            'icon': Icons.edit_note_rounded,
            'urgency': 'normal',
          }),
        ),
      ],
    );
  }

  Widget _buildDeadlineItem(Map<String, dynamic> item) {
    final isUrgent = item['urgency'] == 'urgent';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          context.push('/educator/lessons');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forestDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent
                  ? AppColors.semanticRed.withValues(alpha: 0.3)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.creamBorder),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isUrgent ? AppColors.semanticRed : AppColors.gold500)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: isUrgent ? AppColors.semanticRed : AppColors.gold500,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white : AppColors.creamText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      item['due'] as String,
                      style: AppTypography.label.copyWith(
                        color: isUrgent
                            ? AppColors.semanticRed
                            : (isDark ? Colors.white38 : AppColors.creamText3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.creamText3.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildRecentActivity(
    AsyncValue<List<AdminUser>> allUsersAsync,
    AsyncValue<List<CommunityActivity>> communityActivitiesAsync,
    AsyncValue<List<DictionaryEntry>> pendingSubmissionsAsync,
  ) {
    final List<_FeedItem> feedItems = [];

    // 1. Learner Joins
    if (allUsersAsync.hasValue) {
      final learners = allUsersAsync.value!.where((u) => u.role == 'learner');
      for (var u in learners) {
        feedItems.add(_FeedItem(
          text: '${u.name} joined as a new student',
          timestamp: u.joinedAt,
          icon: Icons.person_add_rounded,
          color: AppColors.semanticGreen,
        ));
      }
    }

    // 2. Community Activities (Lesson Completions, Achievements)
    if (communityActivitiesAsync.hasValue) {
      for (var activity in communityActivitiesAsync.value!) {
        feedItems.add(_FeedItem(
          text: '${activity.userName} ${activity.message}',
          timestamp: activity.createdAt ?? DateTime.now(),
          icon: activity.type == 'lesson_completed'
              ? Icons.task_alt_rounded
              : (activity.type == 'streak'
                  ? Icons.local_fire_department_rounded
                  : Icons.emoji_events_rounded),
          color: activity.type == 'lesson_completed'
              ? AppColors.semanticBlue
              : (activity.type == 'streak' ? Colors.orange : AppColors.gold500),
        ));
      }
    }

    // 3. Pending Submissions
    if (pendingSubmissionsAsync.hasValue) {
      for (var entry in pendingSubmissionsAsync.value!) {
        feedItems.add(_FeedItem(
          text: 'New contribution: "${entry.indigenousWord}" needs review',
          timestamp: entry.submittedAt ?? DateTime.now(),
          icon: Icons.rate_review_rounded,
          color: AppColors.terracotta,
          onTap: () => context.push('/educator/lessons'),
        ));
      }
    }

    feedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final displayItems = feedItems.take(8).toList();

    if (displayItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Recent Activity Feed'),
            GestureDetector(
              onTap: () => context.go('/educator/students'),
              child: Text(
                'VIEW ALL',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayItems.map((item) {
          return _buildActivityItem(
            item.text,
            _timeAgo(item.timestamp),
            item.icon,
            item.color,
            onTap: item.onTap,
          );
        }),
      ],
    );
  }

  Widget _buildActivityItem(
    String text,
    String time,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.creamText2,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              time,
              style: AppTypography.label.copyWith(
                color: isDark ? Colors.white24 : AppColors.creamText3,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.label.copyWith(
        color: AppColors.gold500,
        letterSpacing: 2,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}




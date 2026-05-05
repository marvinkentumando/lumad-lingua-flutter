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
import '../widgets/wotd_widget.dart';

class EducatorDashboardScreen extends ConsumerStatefulWidget {
  const EducatorDashboardScreen({super.key});

  @override
  ConsumerState<EducatorDashboardScreen> createState() =>
      _EducatorDashboardScreenState();
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allLessonsStreamProvider);
            ref.invalidate(allUsersProvider);
            ref.invalidate(totalWordsCountProvider);
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
                _buildQuickActions(allUsersAsync),
                const SizedBox(height: 32),
                _buildStrugglingStudentsAlert(allUsersAsync),
                const SizedBox(height: 24),
                _buildCulturalMilestone(totalWordsAsync),
                const SizedBox(height: 24),
                _buildUpcomingDeadlines(lessonsAsync),
                const SizedBox(height: 24),
                _buildRecentActivity(allUsersAsync),
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
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'WISDOM GUIDE  â€¢  ELDER EDUCATOR',
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
                  color: Colors.black.withOpacity(0.05),
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
                    color: Colors.black.withOpacity(0.4),
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
          Icon(icon, color: AppColors.gold500.withOpacity(0.5), size: 20),
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

  Widget _buildQuickActions(AsyncValue<List<AdminUser>> allUsersAsync) {
    return Column(
      children: [
        Row(
          children: [
            _buildQuickActionBtn(Icons.campaign_rounded, 'Broadcast', () {
              _showBroadcastDialog(allUsersAsync);
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

  void _showBroadcastDialog(AsyncValue<List<AdminUser>> allUsersAsync) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.forestDarkCard : Colors.white,
        title: Text(
          'Village Broadcast',
          style: AppTypography.h3.copyWith(
            color: isDark ? Colors.white : AppColors.creamText,
          ),
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
                    : AppColors.creamBg.withOpacity(0.5),
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

              if (allUsersAsync.hasValue) {
                final studentIds = allUsersAsync.value!
                    .where((u) => u.role == 'learner')
                    .map((u) => u.id)
                    .toList();

                try {
                  await ref
                      .read(firebaseServiceProvider)
                      .broadcastNotification(studentIds, {
                        'title': 'Announcement from Educator',
                        'message': msg,
                        'type': 'broadcast',
                      });
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
                  ? Colors.white.withOpacity(0.05)
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
          color: AppColors.semanticRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.semanticRed.withOpacity(0.3),
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
                color: AppColors.semanticRed.withOpacity(0.15),
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
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
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
                  ? AppColors.semanticRed.withOpacity(0.3)
                  : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : AppColors.creamBorder),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isUrgent ? AppColors.semanticRed : AppColors.gold500)
                      .withOpacity(0.1),
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
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.creamText3.withOpacity(0.3),
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

  Widget _buildRecentActivity(AsyncValue<List<AdminUser>> allUsersAsync) {
    if (!allUsersAsync.hasValue) return const SizedBox.shrink();

    // Fetch actual recent learner joins from Firestore
    final recentLearners =
        allUsersAsync.value!.where((u) => u.role == 'learner').toList()
          ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));

    final topLearners = recentLearners.take(5).toList();
    if (topLearners.isEmpty) return const SizedBox.shrink();

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
                  color: AppColors.gold500.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...topLearners.map((u) {
          return _buildActivityItem(
            '${u.name} joined as a new student',
            _timeAgo(u.joinedAt),
            Icons.person_add_rounded,
            AppColors.semanticGreen,
          );
        }),
      ],
    );
  }

  Widget _buildActivityItem(
    String text,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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



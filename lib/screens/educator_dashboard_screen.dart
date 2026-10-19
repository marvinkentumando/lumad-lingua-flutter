import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../services/firebase_service.dart';
import '../services/haptic_service.dart';
import '../services/auth_service.dart';
import '../models/dictionary_entry.dart';
import '../models/community_activity.dart';
import '../widgets/wotd_widget.dart';
import '../providers/educator_provider.dart';
import '../models/educator_models.dart';
import '../widgets/brand_background.dart';
import '../widgets/admin/create_mini_quiz_modal.dart';
import '../utils/app_localization.dart';

class EducatorDashboardScreen extends ConsumerStatefulWidget {
  const EducatorDashboardScreen({super.key});

  @override
  ConsumerState<EducatorDashboardScreen> createState() => _EducatorDashboardScreenState();
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

class _EducatorDashboardScreenState extends ConsumerState<EducatorDashboardScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  String _greeting(String username, AppLocalization l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.translate('good_morning');
    if (hour < 18) return l10n.translate('good_afternoon');
    return l10n.translate('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final userAuth = ref.watch(authStateProvider).value;
    final notificationsAsync = userAuth != null
        ? ref.watch(userNotificationsStreamProvider(userAuth.uid))
        : const AsyncValue<List<Map<String, dynamic>>>.data([]);
    final educatorStudentsAsync = ref.watch(educatorStudentsProvider);
    final totalWordsAsync = ref.watch(totalWordsCountProvider);
    final communityActivitiesAsync = ref.watch(communityFeedProvider);
    final pendingSubmissionsAsync = ref.watch(
      pendingDictionaryStreamProvider(const ValidatorQuery('all', 10)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allLessonsStreamProvider);
              ref.invalidate(educatorStudentsProvider);
              ref.invalidate(totalWordsCountProvider);
              ref.invalidate(communityFeedProvider);
              await Future.delayed(const Duration(seconds: 1));
            },
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeroBanner(userProfileAsync, notificationsAsync, l10n),
                  const SizedBox(height: 24),
                  const WotdWidget(),
                  const SizedBox(height: 32),
                  _buildStrugglingStudentsAlert(educatorStudentsAsync, l10n),
                  const SizedBox(height: 24),
                  _buildMiniQuizManagementSection(userAuth?.uid ?? '', l10n),
                  const SizedBox(height: 24),
                  _buildCulturalMilestone(totalWordsAsync, l10n),
                  const SizedBox(height: 24),
                  _buildRecentActivity(
                    educatorStudentsAsync,
                    communityActivitiesAsync,
                    pendingSubmissionsAsync,
                    l10n,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
    AsyncValue<Map<String, dynamic>?> profileAsync,
    AsyncValue<List<Map<String, dynamic>>> notifsAsync,
    AppLocalization l10n,
  ) {
    final profile = profileAsync.value;
    if (profile == null) return const SizedBox.shrink();
    final name = profile['username'] as String? ?? l10n.translate('role_educator');
    final unreadCount = notifsAsync.value?.where((n) => n['isRead'] == false).length ?? 0;
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
                      '${_greeting(name, l10n)},\n$name',
                      style: AppTypography.displayBold.copyWith(color: Colors.black, fontSize: 32, height: 1.1),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            l10n.translate('wisdom_guide_elder_educator'),
                            style: AppTypography.label.copyWith(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1),
                          ),
                        ),
                        if (profile['villageCode'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () {
                                HapticService.selection();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.translate(
                                        'village_code_copied_val',
                                        params: {'code': '${profile['villageCode']}'},
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.gold500.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.fort_rounded, size: 10, color: Colors.black),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.translate('village_code_val_label', params: {'code': '${profile['villageCode']}'}),
                                      style: AppTypography.label.copyWith(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () => context.push('/profile'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.semanticRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.semanticRed.withValues(alpha: 0.2))),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 10, color: AppColors.semanticRed),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.translate('activate_village_caps'),
                                      style: AppTypography.label.copyWith(color: AppColors.semanticRed, fontWeight: FontWeight.w900, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), shape: BoxShape.circle), child: Icon(Icons.auto_stories_rounded, color: isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, size: 36)),
            ],
          ),
          Positioned(top: 0, right: 0, child: GestureDetector(onTap: () { HapticService.selection(); context.push('/notifications'); }, child: Stack(children: [Icon(Icons.notifications_none_rounded, color: Colors.black.withValues(alpha: 0.4), size: 24), if (unreadCount > 0) Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.semanticRed, shape: BoxShape.circle)))]))),
        ],
      ),
    );
  }

  Widget _buildStrugglingStudentsAlert(
    AsyncValue<List<EducatorStudent>> studentsAsync,
    AppLocalization l10n,
  ) {
    final struggling = studentsAsync.value?.where((u) => u.isStruggling).toList() ?? [];
    if (struggling.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => context.go('/educator/students'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.semanticRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.semanticRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.semanticRed, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.translate('attention_needed'), style: AppTypography.h3.copyWith(color: AppColors.semanticRed)),
                  Text(
                    l10n.translate('students_falling_behind', params: {'count': '${struggling.length}'}),
                    style: AppTypography.body.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.semanticRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(
                l10n.translate('view_caps'),
                style: AppTypography.label.copyWith(color: AppColors.semanticRed, fontWeight: FontWeight.w900, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCulturalMilestone(
    AsyncValue<int> totalWordsAsync,
    AppLocalization l10n,
  ) {
    final wordsCount = totalWordsAsync.value ?? 0;
    final target = ((wordsCount / 100).floor() + 1) * 100;
    final progress = (wordsCount % 100) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.translate('village_milestone')),
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
                    l10n.translate('dictionary_expansion'),
                    style: AppTypography.h3.copyWith(color: Theme.of(context).colorScheme.onSurface),
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
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold500),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('words_until_next_milestone', params: {'count': '${target - wordsCount}'}),
                style: AppTypography.body.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime d, AppLocalization l10n) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 365) {
      return l10n.translate('years_ago', params: {'count': '${(diff.inDays / 365).floor()}'});
    }
    if (diff.inDays > 30) {
      return l10n.translate('months_ago', params: {'count': '${(diff.inDays / 30).floor()}'});
    }
    if (diff.inDays > 0) {
      return l10n.translate('days_ago', params: {'days': '${diff.inDays}'});
    }
    if (diff.inHours > 0) {
      return l10n.translate('hours_ago', params: {'hours': '${diff.inHours}'});
    }
    if (diff.inMinutes > 0) {
      return l10n.translate('mins_ago', params: {'mins': '${diff.inMinutes}'});
    }
    return l10n.translate('just_now');
  }

  Widget _buildRecentActivity(
    AsyncValue<List<EducatorStudent>> studentsAsync,
    AsyncValue<List<CommunityActivity>> communityActivitiesAsync,
    AsyncValue<List<DictionaryEntry>> pendingSubmissionsAsync,
    AppLocalization l10n,
  ) {
    final List<_FeedItem> feedItems = [];
    if (studentsAsync.hasValue) {
      for (var u in studentsAsync.value!) {
        feedItems.add(_FeedItem(
          text: l10n.translate('user_joined_village', params: {'name': u.name}),
          timestamp: DateTime.now(),
          icon: Icons.person_add_rounded,
          color: AppColors.semanticGreen,
        ));
      }
    }
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
    if (pendingSubmissionsAsync.hasValue) {
      for (var entry in pendingSubmissionsAsync.value!) {
        feedItems.add(_FeedItem(
          text: l10n.translate('new_contribution_needs_review', params: {'word': entry.indigenousWord}),
          timestamp: entry.submittedAt ?? DateTime.now(),
          icon: Icons.rate_review_rounded,
          color: AppColors.terracotta,
          onTap: () => context.push('/admin/lessons'),
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
            _buildSectionTitle(l10n.translate('recent_activity_feed')),
            GestureDetector(
              onTap: () => context.go('/educator/students'),
              child: Text(
                l10n.translate('view_all_caps'),
                style: AppTypography.label.copyWith(color: AppColors.gold500.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayItems.map((item) => _buildActivityItem(
              item.text,
              _timeAgo(item.timestamp, l10n),
              item.icon,
              item.color,
              onTap: item.onTap,
            )),
      ],
    );
  }

  Widget _buildActivityItem(String text, String time, IconData icon, Color color, {VoidCallback? onTap}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: GestureDetector(onTap: onTap, child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)), const SizedBox(width: 12), Expanded(child: Text(text, style: AppTypography.body.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))), Text(time, style: AppTypography.label.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 10))])));
  }

  Widget _buildSectionTitle(String title) {
    return Text(title.toUpperCase(), style: AppTypography.label.copyWith(color: AppColors.gold500, letterSpacing: 2, fontWeight: FontWeight.w900));
  }

  Widget _buildMiniQuizManagementSection(String educatorId, AppLocalization l10n) {
    final miniQuizzesAsync = ref.watch(villageMiniQuizzesProvider(educatorId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(l10n.translate('village_custom_mini_quizzes')),
            GestureDetector(
              onTap: () {
                HapticService.selection();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CreateMiniQuizModal(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: AppColors.gold500, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      l10n.translate('create_caps'),
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        miniQuizzesAsync.when(
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return BrandCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.translate('no_mini_quizzes_created_yet'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: quizzes.map((q) => _buildEducatorQuizCard(q, l10n)).toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold500),
          ),
          error: (e, _) => Text(
            l10n.translate('error_prefix', params: {'error': '$e'}),
            style: const TextStyle(color: AppColors.semanticRed),
          ),
        ),
      ],
    );
  }

  Widget _buildEducatorQuizCard(VillageMiniQuiz quiz, AppLocalization l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: AppColors.gold500,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz.title,
                    style: AppTypography.h3.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.translate(
                      'dialect_questions_count',
                      params: {
                        'dialect': quiz.dialect,
                        'count': '${quiz.tasks.length}',
                      },
                    ),
                    style: AppTypography.label.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: quiz.isAssigned,
              activeThumbColor: AppColors.gold500,
              onChanged: (val) async {
                HapticService.toggle();
                await ref
                    .read(firebaseServiceProvider)
                    .toggleMiniQuizAssignment(quiz.id, val);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.semanticRed,
                size: 20,
              ),
              onPressed: () async {
                HapticService.delete();
                await ref
                    .read(firebaseServiceProvider)
                    .deleteVillageMiniQuiz(quiz.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

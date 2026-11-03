import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/daily_challenge_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/app_localization.dart';
import '../utils/learning_next_action.dart';
import 'app_shimmer_skeleton.dart';
import 'brand_card.dart';

class LearningNextActionCard extends ConsumerWidget {
  const LearningNextActionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final lessons = ref.watch(lessonsStreamProvider);
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull;
    final progress = user == null
        ? const AsyncValue<Map<String, dynamic>>.data({})
        : ref.watch(userProgressStreamProvider(user.uid));
    final profile = ref.watch(userProfileProvider);
    final due = user == null
        ? const AsyncValue<int>.data(0)
        : ref.watch(dueSRSCountProvider(user.uid));
    final challenge = ref.watch(dailyChallengeProvider);

    // Do not mistake a pending progress snapshot for a new learner.
    if ((!lessons.hasValue && lessons.isLoading) ||
        (!auth.hasValue && auth.isLoading) ||
        (!progress.hasValue && progress.isLoading) ||
        (!profile.hasValue && profile.isLoading) ||
        (!due.hasValue && due.isLoading) ||
        (!challenge.hasValue && challenge.isLoading)) {
      return const HubCardSkeleton();
    }
    if ((!lessons.hasValue && lessons.hasError) ||
        (!progress.hasValue && progress.hasError) ||
        (!auth.hasValue && auth.hasError) ||
        (!profile.hasValue && profile.hasError)) {
      return BrandCard(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.translate('hub_next_unavailable')),
          TextButton(
            onPressed: () {
              ref.invalidate(lessonsStreamProvider);
              ref.invalidate(authStateProvider);
              ref.invalidate(userProfileProvider);
              if (user != null) ref.invalidate(userProgressStreamProvider(user.uid));
            },
            child: Text(l10n.translate('hub_next_retry')),
          ),
        ]),
      );
    }

    final action = selectLearningNextAction(
      lessons: lessons.valueOrNull ?? [],
      progress: progress.valueOrNull ?? {},
      dueCount: due.valueOrNull ?? 0,
      challenge: profile.hasValue ? challenge.valueOrNull : null,
      challengeCompleted: ref.watch(dailyChallengeStatusProvider),
    );
    final (titleKey, bodyKey, buttonKey, icon) = switch (action.type) {
      LearningNextActionType.resume => ('hub_next_resume', 'hub_next_lesson_body', 'hub_next_continue', Icons.play_arrow_rounded),
      LearningNextActionType.review => ('hub_next_review', 'hub_next_review_body', 'hub_next_review_button', Icons.refresh_rounded),
      LearningNextActionType.dailyGoal => ('hub_next_goal', 'hub_next_goal_body', 'hub_next_goal_button', Icons.flag_rounded),
      LearningNextActionType.lesson => (action.hasProgress ? 'hub_next_continue' : 'hub_next_start', 'hub_next_lesson_body', action.hasProgress ? 'hub_next_continue' : 'hub_next_start', Icons.school_rounded),
      LearningNextActionType.explore => ('hub_next_explore', 'hub_next_explore_body', 'hub_next_explore_button', Icons.menu_book_rounded),
    };
    final params = {
      'lesson': action.lesson?.title ?? '',
      'language': action.lesson?.language ?? '',
      'count': '${action.dueCount}',
      'challenge': action.challenge?.title ?? '',
    };
    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.forest900, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.translate('hub_next_label'),
              style: AppTypography.label.copyWith(color: AppColors.forest700))),
          ]),
          const SizedBox(height: 16),
          Text(l10n.translate(titleKey),
            style: AppTypography.h3.copyWith(color: AppColors.forest900)),
          const SizedBox(height: 8),
          Text(l10n.translate(bodyKey, params: params),
            style: AppTypography.body.copyWith(color: AppColors.forest700)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('learning-next-action'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onPressed: () => context.push(action.location, extra: action.challenge),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.translate(buttonKey)),
            ),
          ),
        ],
      ),
    );
  }
}

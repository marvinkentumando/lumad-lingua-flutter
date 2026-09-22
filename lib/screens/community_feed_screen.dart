import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../models/community_activity.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/brand_background.dart';
import '../utils/app_localization.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: feedAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Center(
                        child: Text(
                          l10n.translate('community_quiet'),
                          style: TextStyle(
                            color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return _FeedItemWidget(activity: activity, l10n: l10n)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: index * 100))
                            .slideY(begin: 0.1, curve: Curves.easeOutCubic);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold500),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.white),
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

  Widget _buildHeader(BuildContext context, AppLocalization l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Text(
            l10n.translate('living_feed'),
            style: AppTypography.h1ExtraBold.copyWith(
              color: AppColors.gold500,
              fontSize: 32,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedItemWidget extends ConsumerStatefulWidget {
  final CommunityActivity activity;
  final AppLocalization l10n;

  const _FeedItemWidget({required this.activity, required this.l10n});

  @override
  ConsumerState<_FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends ConsumerState<_FeedItemWidget> {
  final TextEditingController _commentController = TextEditingController();

  void _toggleLike() {
    final user = ref.read(authStateProvider).value;
    final profile = ref.read(userProfileProvider).value;
    if (user != null) {
      ref.read(firebaseServiceProvider).toggleLike(
            widget.activity.id,
            user.uid,
            userName: profile?['username'] ?? 'A tribe member',
            userPhotoUrl: profile?['photoURL'],
          );
    }
  }

  Color _getThemeColor(String type) {
    switch (type) {
      case 'lesson_completed':
        return AppColors.gold500;
      case 'streak':
        return AppColors.semanticRed;
      case 'contribution':
        return AppColors.semanticBlue;
      case 'validation':
        return AppColors.semanticGreen;
      case 'achievement':
        return AppColors.gold700;
      default:
        return Colors.white54;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isLiked = user != null && widget.activity.likedBy.contains(user.uid);
    final themeColor = _getThemeColor(widget.activity.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.activity.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                      ),
                      children: [
                        TextSpan(
                          text: widget.activity.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.gold500 : AppColors.forest700,
                          ),
                        ),
                        TextSpan(text: ' ${widget.activity.message}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.activity.relativeTime.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Spark (Like) button
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isLiked
                                ? AppColors.semanticRed.withValues(alpha: 0.1)
                                : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLiked
                                  ? AppColors.semanticRed.withValues(alpha: 0.2)
                                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                    isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border,
                                    color: isLiked
                                        ? AppColors.semanticRed
                                        : (isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4)),
                                    size: 16,
                                  )
                                  .animate(target: isLiked ? 1 : 0)
                                  .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.3, 1.3),
                                    curve: Curves.elasticOut,
                                  ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.activity.likeCount}',
                                style: AppTypography.label.copyWith(
                                  color: isLiked
                                      ? AppColors.semanticRed
                                      : (isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5)),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Comment button
                      GestureDetector(
                        onTap: () => _showComments(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mode_comment_outlined,
                                color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${widget.activity.commentCount}",
                                style: AppTypography.label.copyWith(
                                  color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Share
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.l10n.translate('sharing_update', params: {'name': widget.activity.userName}),
                              ),
                              backgroundColor: AppColors.semanticBlue,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.4),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.forest800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.l10n.translate('comments_label'),
              style: AppTypography.h3.copyWith(color: AppColors.gold500),
            ),
            const SizedBox(height: 16),
            // We'd add a StreamBuilder for comments here later
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.l10n.translate('conversation_soon'),
                  style: const TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: widget.l10n.translate('add_comment_hint'),
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: AppColors.forest900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final profileAsync = ref.watch(userProfileProvider);
                    return profileAsync.when(
                      data: (profile) => IconButton(
                        onPressed: () async {
                          if (_commentController.text.trim().isEmpty) return;
                          final user = ref.read(authStateProvider).value;
                          if (user != null && profile != null) {
                            await ref
                                .read(firebaseServiceProvider)
                                .addComment(
                                  widget.activity.id,
                                  user.uid,
                                  profile['username'] ?? 'Anonymous',
                                  _commentController.text.trim(),
                                  userPhotoUrl: profile['photoURL'],
                                );
                            _commentController.clear();
                            if (context.mounted) context.pop();
                          }
                        },
                        icon: const Icon(
                          Icons.send_rounded,
                          color: AppColors.gold500,
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold500,
                        ),
                      ),
                      error: (_, __) => const Icon(
                        Icons.error_outline,
                        color: AppColors.semanticRed,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

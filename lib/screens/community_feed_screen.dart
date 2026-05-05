import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../models/community_activity.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/brand_background.dart';

class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: feedAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return const Center(
                        child: Text(
                          "The community is quiet... for now. 🌿",
                          style: TextStyle(color: Colors.white24),
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
                        return _FeedItemWidget(activity: activity)
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Text(
            'LIVING FEED',
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
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedItemWidget extends ConsumerStatefulWidget {
  final CommunityActivity activity;

  const _FeedItemWidget({required this.activity});

  @override
  ConsumerState<_FeedItemWidget> createState() => _FeedItemWidgetState();
}

class _FeedItemWidgetState extends ConsumerState<_FeedItemWidget> {
  final TextEditingController _commentController = TextEditingController();

  void _toggleLike() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref
          .read(firebaseServiceProvider)
          .toggleLike(widget.activity.id, user.uid);
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
                      style: AppTypography.body.copyWith(color: Colors.white),
                      children: [
                        TextSpan(
                          text: widget.activity.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold500,
                          ),
                        ),
                        TextSpan(text: ' ${widget.activity.message}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white24,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.activity.relativeTime.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          color: Colors.white24,
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
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLiked
                                  ? AppColors.semanticRed.withValues(alpha: 0.2)
                                  : Colors.white10,
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
                                        : Colors.white54,
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
                                      : Colors.white54,
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
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mode_comment_outlined,
                                color: Colors.white54,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${widget.activity.commentCount}",
                                style: AppTypography.label.copyWith(
                                  color: Colors.white54,
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
                                'Sharing update by ${widget.activity.userName}...',
                              ),
                              backgroundColor: AppColors.semanticBlue,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            color: Colors.white54,
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
              "Comments",
              style: AppTypography.h3.copyWith(color: AppColors.gold500),
            ),
            const SizedBox(height: 16),
            // We'd add a StreamBuilder for comments here later
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Conversation starting soon... 🌿",
                  style: TextStyle(color: Colors.white24, fontSize: 12),
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
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.white38),
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
                                );
                            _commentController.clear();
                            if (context.mounted) Navigator.pop(context);
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

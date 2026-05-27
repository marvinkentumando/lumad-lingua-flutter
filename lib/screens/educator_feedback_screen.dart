import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/firebase_service.dart';
import '../models/feedback.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/branded_empty_state.dart';
import '../widgets/profile_avatar.dart';

class EducatorFeedbackScreen extends ConsumerWidget {
  const EducatorFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(studentFeedbackProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Student Feedback'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.forest900,
      ),
      body: AmbientTopoBackground(
        child: feedbackAsync.when(
          data: (feedbackList) {
            if (feedbackAsync.value!.isEmpty) {
              return const BrandedEmptyState(
                title: 'No Feedback Yet',
                message: 'Messages from your students will appear here.',
                icon: Icons.forum_outlined,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final feedback = feedbackList[index];
                return _FeedbackCard(feedback: feedback);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold500),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading feedback: $err'),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends ConsumerStatefulWidget {
  final StudentFeedback feedback;
  const _FeedbackCard({required this.feedback});

  @override
  ConsumerState<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends ConsumerState<_FeedbackCard> {
  final TextEditingController _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM dd • hh:mm a').format(widget.feedback.timestamp);
    final hasReplied = widget.feedback.educatorReply != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.feedback.isRead
              ? (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.creamBorder)
              : AppColors.gold500.withValues(alpha: 0.3),
          width: widget.feedback.isRead ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(
                radius: 20,
                photoUrl: widget.feedback.studentPhotoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.feedback.studentName,
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.forest900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: AppTypography.label.copyWith(
                        color: isDark ? Colors.white24 : AppColors.creamText3,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.feedback.isRead)
                const CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.gold500,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.feedback.message,
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white70 : AppColors.creamText2,
              height: 1.5,
            ),
          ),
          if (hasReplied) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, size: 14, color: AppColors.gold500),
                      const SizedBox(width: 8),
                      Text(
                        'YOUR REPLY',
                        style: AppTypography.label.copyWith(
                          color: AppColors.gold500,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.feedback.educatorReply!,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white60 : AppColors.forest700,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (!_isReplying && !hasReplied)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isReplying = true),
                    icon: const Icon(Icons.reply_rounded, size: 18),
                    label: const Text('REPLY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold500,
                      foregroundColor: AppColors.forest900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!widget.feedback.isRead)
                  TextButton(
                    onPressed: () => ref.read(firebaseServiceProvider).markFeedbackAsRead(widget.feedback.id),
                    child: const Text('MARK AS READ'),
                  ),
              ],
            ),
          if (_isReplying)
            Column(
              children: [
                TextField(
                  controller: _replyController,
                  maxLines: 3,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.creamText),
                  decoration: InputDecoration(
                    hintText: 'Type your reply...',
                    hintStyle: TextStyle(color: isDark ? Colors.white24 : AppColors.creamText3),
                    filled: true,
                    fillColor: isDark ? AppColors.forest800 : AppColors.creamBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isReplying = false),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (_replyController.text.trim().isEmpty) return;
                        await ref.read(firebaseServiceProvider).replyToFeedback(
                          widget.feedback.id,
                          _replyController.text.trim(),
                        );
                        setState(() => _isReplying = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold500,
                        foregroundColor: AppColors.forest900,
                      ),
                      child: const Text('SEND REPLY'),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

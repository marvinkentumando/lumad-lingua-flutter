import 'package:flutter/material.dart';
import '../../models/lesson_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../preview_audio_player.dart';

class OverviewPreview extends StatelessWidget {
  final LessonStep step;

  const OverviewPreview({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final title = step.title.isNotEmpty ? step.title : 'Lesson Overview';
    final content = (step.data['content'] ?? step.data['overviewText'] ?? '').toString();
    final culturalNotes = (step.data['culturalNotes'] ?? '').toString();
    final imageUrl = step.data['imageUrl'] as String?;
    final audioUrl = step.data['audioUrl'] as String?;

    return Container(
      color: AppColors.forest900,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'LESSON OVERVIEW',
                style: AppTypography.label.copyWith(
                  color: AppColors.gold500,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.h3.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (audioUrl != null && audioUrl.isNotEmpty) ...[
              PreviewAudioPlayer(audioUrl: audioUrl),
              const SizedBox(height: 12),
            ],
            Text(
              content.isNotEmpty
                  ? content
                  : 'Structured educational overview and abstract content will appear here...',
              style: AppTypography.body.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (culturalNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.gold500,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'CULTURAL HERITAGE NOTE',
                          style: TextStyle(
                            color: AppColors.gold500,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      culturalNotes,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

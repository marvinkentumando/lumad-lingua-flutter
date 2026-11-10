import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../preview_audio_player.dart';

class OverviewView extends ConsumerWidget {
  final String title;
  final String content;
  final String? culturalNotes;
  final String? imageUrl;
  final String? audioUrl;

  const OverviewView({
    super.key,
    required this.title,
    required this.content,
    this.culturalNotes,
    this.imageUrl,
    this.audioUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? AppColors.forestDarkCard : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.gold500,
                  size: 44,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LESSON OVERVIEW',
              style: AppTypography.label.copyWith(
                color: AppColors.gold500,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title.isNotEmpty && title != 'overview' ? title : 'Lesson Overview',
            style: AppTypography.h2.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (audioUrl != null && audioUrl!.isNotEmpty) ...[
            PreviewAudioPlayer(audioUrl: audioUrl!),
            const SizedBox(height: 16),
          ],
          Text(
            content.isNotEmpty ? content : title,
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.forest900.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (culturalNotes != null && culturalNotes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
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
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'CULTURAL HERITAGE NOTE',
                        style: TextStyle(
                          color: AppColors.gold500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    culturalNotes!,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.forest900,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

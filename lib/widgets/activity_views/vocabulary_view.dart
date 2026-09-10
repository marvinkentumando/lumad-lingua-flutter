import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/supabase_storage_service.dart';
import '../preview_audio_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Fix #15: VocabularyView now renders the actual network image instead of a placeholder icon.
class VocabularyView extends ConsumerWidget {
  final String nativeWord;
  final String translation;
  final String definition;
  final String? imageUrl;
  final String? audioUrl;
  final bool isFlipped;
  final VoidCallback? onFlip;
  final bool isReadOnly;

  const VocabularyView({
    super.key,
    required this.nativeWord,
    required this.translation,
    required this.definition,
    this.imageUrl,
    this.audioUrl,
    this.isFlipped = false,
    this.onFlip,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedImageUrl = imageUrl != null && imageUrl!.isNotEmpty
        ? ref.read(supabaseStorageServiceProvider).getImageUrl(imageUrl!)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review this word',
          style: AppTypography.h2.copyWith(
            color: isDark ? Colors.white : AppColors.forest900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: isReadOnly ? null : onFlip,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final rotateAnim = Tween(
                begin: 3.14,
                end: 0.0,
              ).animate(animation);
              return AnimatedBuilder(
                animation: rotateAnim,
                child: child,
                builder: (context, child) {
                  final angle = child!.key == ValueKey(isFlipped)
                      ? rotateAnim.value
                      : -rotateAnim.value;
                  return Transform(
                    transform: Matrix4.rotationY(angle),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
              );
            },
            child: Container(
              key: ValueKey(isFlipped),
              height: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.forestDarkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.gold500.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: isFlipped
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            translation.isEmpty ? 'Translation' : translation,
                            style: AppTypography.h1ExtraBold.copyWith(
                              color: AppColors.semanticBlue,
                              fontSize: 32,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            definition,
                            style: AppTypography.body.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Fix #15: Render the actual network image instead of a placeholder icon.
                          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  resolvedImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported_rounded,
                                    color: AppColors.gold500,
                                    size: 48,
                                  ),
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                            : null,
                                        color: AppColors.gold500,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            nativeWord.isEmpty ? 'Native Word' : nativeWord,
                            style: AppTypography.h1ExtraBold.copyWith(
                              color: AppColors.gold500,
                              fontSize: imageUrl != null && imageUrl!.isNotEmpty
                                  ? 28
                                  : 40,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (audioUrl != null && audioUrl!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            PreviewAudioPlayer(audioUrl: audioUrl!, size: 32),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isReadOnly ? 'Educator Preview Mode' : 'Tap the card to flip',
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.white54 : AppColors.forest900.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}




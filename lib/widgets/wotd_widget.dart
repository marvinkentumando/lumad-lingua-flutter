import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/audio_service.dart';
import '../providers/saved_words_provider.dart';
import '../providers/wotd_provider.dart';
import '../models/dictionary_entry.dart';
import 'brand_card.dart';
import 'brand_button.dart';

class WotdWidget extends ConsumerWidget {
  const WotdWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wotdAsync = ref.watch(wordOfTheDayProvider);
    final savedIds = ref.watch(savedWordsProvider);

    return wotdAsync.when(
      data: (entry) {
        if (entry == null) return const SizedBox.shrink();
        final isSaved = savedIds.contains(entry.id);
        return _buildContent(context, ref, entry, isSaved);
      },
      loading: () => _buildLoading(context),
      error: (error, stack) {
        debugPrint('Error loading WOTD: $error');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    DictionaryEntry entry,
    bool isSaved,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: BrandCard(
        theme: BrandCardTheme.vibrant,
        padding: const EdgeInsets.all(24),
        borderRadius: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.gold500,
                          size: 18,
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2.seconds),
                    const SizedBox(width: 8),
                    Text(
                      'WORD OF THE DAY',
                      style: AppTypography.label.copyWith(
                        color: AppColors.gold500,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.language.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: isDark ? Colors.white38 : AppColors.forest400,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.indigenousWord,
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.forest500,
                          letterSpacing: -1,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1),
                      if (entry.phonetic != null)
                        Text(
                          entry.phonetic!,
                          style: AppTypography.mono.copyWith(
                            color: AppColors.gold500.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref
                            .read(savedWordsProvider.notifier)
                            .toggleSave(entry.id, context: context);
                      },
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: AppColors.gold500,
                        size: 28,
                      ),
                    ).animate(target: isSaved ? 1 : 0).scale(duration: 200.ms),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (entry.audioUrl != null &&
                            entry.audioUrl!.isNotEmpty) {
                          ref
                              .read(audioServiceProvider)
                              .playFromUrl(entry.audioUrl!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No audio available')),
                          );
                        }
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.gold500,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold500.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ).animate().scale(delay: 200.ms).shimmer(delay: 1.seconds),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.gold500,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.usageContext,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white70 : AppColors.creamText,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: BrandButton(
                text: 'LEARN MORE IN DICTIONARY',
                onTap: () => context.go('/dictionary'),
                type: BrandButtonType.primary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return RepaintBoundary(
      child:
          BrandCard(
                theme: BrandCardTheme.vibrant,
                padding: const EdgeInsets.all(24),
                borderRadius: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 180,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 100,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 1.5.seconds,
                color: Colors.white.withValues(alpha: 0.05),
              ),
    );
  }
}

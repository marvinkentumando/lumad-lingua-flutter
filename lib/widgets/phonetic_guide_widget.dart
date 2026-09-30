import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/ipa_parser.dart';
import '../services/audio_service.dart';

/// Interactive Phonetic IPA Guide component displaying parsed syllable units
/// and educational symbol tooltips for dictionary entries.
class PhoneticGuideWidget extends ConsumerWidget {
  final String? phonetic;
  final String? audioUrl;
  final String indigenousWord;
  final bool isDark;

  const PhoneticGuideWidget({
    super.key,
    required this.phonetic,
    this.audioUrl,
    required this.indigenousWord,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syllables = IpaParser.parseSyllables(phonetic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.record_voice_over_rounded,
              size: 14,
              color: isDark ? AppColors.gold500 : AppColors.forest700,
            ),
            const SizedBox(width: 6),
            Text(
              'PRONUNCIATION (IPA GUIDE)',
              style: AppTypography.label.copyWith(
                color: isDark ? AppColors.gold500 : AppColors.forest700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (syllables.isEmpty)
          _buildUnavailableFallback(context)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: syllables.map((syl) {
              return GestureDetector(
                onTap: () => _showSyllableTooltip(context, syl, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.gold500.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.gold500.withValues(alpha: 0.3)
                          : AppColors.forest900.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '/$syl/',
                        style: AppTypography.mono.copyWith(
                          color: isDark ? AppColors.gold500 : AppColors.forest900,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: isDark ? AppColors.gold500 : AppColors.forest900,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildUnavailableFallback(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Text(
        'IPA guide unavailable for this entry',
        style: AppTypography.caption.copyWith(
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : AppColors.forest700.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  void _showSyllableTooltip(BuildContext context, String syllable, WidgetRef ref) {
    final symbols = IpaParser.extractSymbols(syllable);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.forest800 : AppColors.creamBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? AppColors.gold500.withValues(alpha: 0.2) : AppColors.creamBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IPA SYLLABLE GUIDANCE',
                        style: AppTypography.label.copyWith(
                          color: isDark ? AppColors.gold500 : AppColors.forest700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '/$syllable/',
                        style: AppTypography.h1ExtraBold.copyWith(
                          color: isDark ? AppColors.gold500 : AppColors.forest900,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : AppColors.forest700,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'DETECTED IPA SYMBOLS',
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white60 : AppColors.creamText2,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              if (symbols.isEmpty)
                Text(
                  'No distinct IPA symbols identified.',
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.forest700,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Column(
                  children: symbols.map((sym) {
                    final description = IpaParser.getSymbolDescription(sym);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.gold500.withValues(alpha: 0.15)
                                  : AppColors.forest900.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? AppColors.gold500.withValues(alpha: 0.3) : AppColors.forest900.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              sym,
                              style: AppTypography.mono.copyWith(
                                color: isDark ? AppColors.gold500 : AppColors.forest900,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  description ?? 'Pronunciation symbol (standard guide unavailable)',
                                  style: AppTypography.body.copyWith(
                                    color: isDark ? Colors.white.withValues(alpha: 0.87) : AppColors.forest900,
                                    fontSize: 13,
                                    fontWeight: description != null ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              if (audioUrl != null && audioUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    try {
                      ref.read(audioServiceProvider).playFromUrl(audioUrl!);
                    } catch (e) {
                      debugPrint('Error playing reference audio: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Native Reference Audio ("$indigenousWord")',
                                style: AppTypography.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Full-word recording by native speaker',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: isDark ? Colors.white60 : AppColors.forest700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No reference recording is currently attached for this entry.',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white70 : AppColors.forest700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

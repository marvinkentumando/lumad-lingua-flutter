import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/geo_recording.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'recording_card.dart';

class MunicipalityPanel extends ConsumerWidget {
  final GeoRecording rec;
  final ScrollController scrollController;
  final Set<String> favorites;
  final String? playingAudioId;
  final Duration duration;
  final Duration position;
  final Function(Map<String, dynamic>) onTogglePlay;
  final Function(double) onSeek;
  final Function(String) onToggleFavorite;
  final String Function(Duration) formatDuration;

  const MunicipalityPanel({
    super.key,
    required this.rec,
    required this.scrollController,
    required this.favorites,
    required this.playingAudioId,
    required this.duration,
    required this.position,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onToggleFavorite,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.forestDarkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black26),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 20),
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.gold500
                                : AppColors.forest500,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'AMBER PIN',
                            style: AppTypography.label.copyWith(
                              color: isDark ? Colors.black : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Community Archive',
                          style: AppTypography.body.copyWith(
                            color: isDark
                                ? AppColors.gold700
                                : AppColors.forest700,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => onToggleFavorite(rec.id),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: favorites.contains(rec.id)
                              ? AppColors.gold500.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: favorites.contains(rec.id)
                                ? AppColors.gold500
                                : (isDark ? Colors.white : Colors.black)
                                      .withOpacity(0.1),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          favorites.contains(rec.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border,
                          color: isDark
                              ? AppColors.gold500
                              : AppColors.forest500,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rec.title,
                  style: AppTypography.h1ExtraBold.copyWith(
                    color: isDark ? Colors.white : AppColors.forest700,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.domain,
                      color: isDark ? AppColors.gold500 : AppColors.forest500,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rec.province,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white38 : AppColors.creamText2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Explore the authentic voices and linguistic heritage of ${rec.title}, located in the province of ${rec.province}.',
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white38 : AppColors.creamText2,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 16),

                // Live Recordings Sub-collection
                ref
                    .watch(municipalityRecordingsProvider(rec.id))
                    .when(
                      data: (recordings) {
                        if (recordings.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.mic_off_rounded,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No recordings yet for ${rec.title}',
                                    style: AppTypography.label.copyWith(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recordings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final recording = recordings[index];
                            return RecordingCard(
                              audio: recording,
                              isPlaying: playingAudioId == recording['id'],
                              duration: duration,
                              position: position,
                              onTogglePlay: () => onTogglePlay(recording),
                              onSeek: onSeek,
                              formatDuration: formatDuration,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



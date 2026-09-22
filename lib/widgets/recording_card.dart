import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_card.dart';

class RecordingCard extends StatelessWidget {
  final Map<String, dynamic> audio;
  final bool isPlaying;
  final Duration duration;
  final Duration position;
  final VoidCallback onTogglePlay;
  final Function(double) onSeek;
  final String Function(Duration) formatDuration;

  const RecordingCard({
    super.key,
    required this.audio,
    required this.isPlaying,
    required this.duration,
    required this.position,
    required this.onTogglePlay,
    required this.onSeek,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = audio['title'] ?? 'Untitled Recording';
    final speakerName = audio['speakerName'] ?? 'Tribe Member';
    final speakerRole = audio['speakerRole'] ?? 'Community Member';
    final barangay = audio['barangay'];
    final dialect = audio['dialect'] ?? 'Indigenous';
    final photoUrl = audio['speakerPhotoUrl'];
    final transcription = audio['transcript'] ?? audio['transcription'];
    final culturalNote = audio['culturalNote'] ?? audio['note'];

    return BrandCard(
      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.cream,
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: isDark ? AppColors.gold500 : AppColors.forest700,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dialect.toUpperCase(),
                  style: AppTypography.label.copyWith(
                    color: AppColors.gold500,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold500, width: 2),
                  boxShadow: isPlaying
                      ? [
                          BoxShadow(
                            color: AppColors.gold500.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.forest900,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : NetworkImage(
                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(speakerName)}&background=1B2D2A&color=D4B886',
                            )
                            as ImageProvider,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speakerName,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white : AppColors.forest700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$speakerRole${barangay != null ? " • $barangay" : ""}',
                      style: AppTypography.label.copyWith(
                        color: isDark ? Colors.white60 : AppColors.creamText2,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onTogglePlay,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPlaying ? AppColors.forest700 : AppColors.gold500,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isPlaying
                                    ? AppColors.forest700
                                    : AppColors.gold500)
                                .withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isDark || isPlaying
                        ? Colors.white
                        : AppColors.forest900,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Waveform Visualizer & Seek Bar
          if (isPlaying)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: AppColors.gold500,
                      inactiveTrackColor: isDark
                          ? Colors.white10
                          : Colors.black12,
                      thumbColor: AppColors.gold500,
                    ),
                    child: Slider(
                      min: 0,
                      max: duration.inMilliseconds.toDouble(),
                      value: position.inMilliseconds.toDouble().clamp(
                        0,
                        duration.inMilliseconds.toDouble(),
                      ),
                      onChanged: onSeek,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(position),
                          style: AppTypography.label.copyWith(
                            color: isDark ? Colors.white60 : Colors.black26,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          formatDuration(duration),
                          style: AppTypography.label.copyWith(
                            color: isDark ? Colors.white60 : Colors.black26,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      20,
                      (index) =>
                          Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                width: 4,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.gold500,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleY(
                                begin: 0.5,
                                end: 2.5,
                                duration: (200 + (index * 50 % 300)).ms,
                                curve: Curves.easeInOut,
                                delay: (index * 20).ms,
                              )
                              .tint(color: AppColors.gold700, duration: 400.ms),
                    ),
                  ),
                ],
              ),
            ),

          if (transcription != null && transcription.isNotEmpty) ...[
            Text(
              '“$transcription”',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white70 : AppColors.forest700,
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (culturalNote != null && culturalNote.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.gold500,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      culturalNote,
                      style: AppTypography.body.copyWith(
                        color: isDark ? Colors.white60 : AppColors.creamText3,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (audio['contributorName'] != null)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Contributed by: ${audio['contributorName']}',
                style: AppTypography.label.copyWith(
                  color: isDark ? Colors.white24 : AppColors.creamText3,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}




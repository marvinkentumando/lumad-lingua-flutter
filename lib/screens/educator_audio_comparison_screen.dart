import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../models/learner_attempt.dart';
import '../models/supabase_dataset_entry.dart';
import '../services/firebase_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/supabase_dataset_service.dart';

class EducatorAudioComparisonScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const EducatorAudioComparisonScreen({super.key, this.studentId});

  @override
  ConsumerState<EducatorAudioComparisonScreen> createState() =>
      _EducatorAudioComparisonScreenState();
}

class _EducatorAudioComparisonScreenState
    extends ConsumerState<EducatorAudioComparisonScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  int _selectedDatasetIndex = 0;
  bool _isLoadingNative = false;
  final ap.AudioPlayer _nativePlayer = ap.AudioPlayer();

  @override
  void dispose() {
    _nativePlayer.dispose();
    super.dispose();
  }

  Future<void> _playNativeAudio(SupabaseDatasetEntry item) async {
    if (item.takes.isEmpty) return;
    final take = item.primaryTake ?? item.takes.first;
    if (take.audioUrl.isEmpty) return;
    setState(() => _isLoadingNative = true);
    try {
      final resolvedUrl = ref.read(supabaseStorageServiceProvider).getAudioUrl(take.audioUrl);
      await _nativePlayer.stop();
      await _nativePlayer.play(ap.UrlSource(resolvedUrl));
    } catch (e) {
      debugPrint('Error playing reference audio: $e');
    } finally {
      if (mounted) setState(() => _isLoadingNative = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final datasetAsync = ref.watch(supabaseDatasetEntriesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.forest900),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Pronunciation & Learning Effectiveness Analytics',
          style: AppTypography.label.copyWith(
            color: AppColors.gold500,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: BrandBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Cohort Overview Summary Cards
                FutureBuilder<List<LearnerAttempt>>(
                  future: ref.read(firebaseServiceProvider).fetchLearnerPronunciationAttempts(),
                  builder: (context, snapshot) {
                    final attempts = snapshot.data ?? [];
                    final totalAttempts = attempts.length;
                    final avgScore = totalAttempts > 0
                        ? attempts.map((a) => a.bestScore).reduce((a, b) => a + b) / totalAttempts
                        : 0.0;
                    final masteryCount = attempts.where((a) => a.bestScore >= 80.0).length;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Practice Logs',
                            '$totalAttempts',
                            Icons.mic_rounded,
                            AppColors.semanticBlue,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Class Average Accuracy',
                            '${avgScore.toStringAsFixed(1)}%',
                            Icons.analytics_rounded,
                            AppColors.gold500,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Mastered (≥ 80%)',
                            '$masteryCount',
                            Icons.emoji_events_rounded,
                            AppColors.semanticGreen,
                            isDark,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 2. Dataset Reference Browser (Aligned with Learner Audio)
                Text(
                  'Curriculum Reference Audio & Phrase Statistics',
                  style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.forest900),
                ),
                const SizedBox(height: 12),
                datasetAsync.when(
                  data: (entries) {
                    final primaryEntries = entries
                        .where((e) => !e.isSupplementaryReference && e.isCompatible && e.isAvailable)
                        .toList();

                    if (primaryEntries.isEmpty) {
                      return const Text('No reference audio entries found.', style: TextStyle(color: Colors.white70));
                    }

                    if (_selectedDatasetIndex >= primaryEntries.length) {
                      _selectedDatasetIndex = 0;
                    }
                    final currentItem = primaryEntries[_selectedDatasetIndex];

                    return BrandCard(
                      theme: isDark ? BrandCardTheme.vibrant : BrandCardTheme.gold,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.gold500,
                                child: Icon(Icons.record_voice_over_rounded, color: Colors.black),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentItem.title,
                                      style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.forest900),
                                    ),
                                    Text(
                                      currentItem.subtitle,
                                      style: AppTypography.body.copyWith(color: isDark ? Colors.white60 : AppColors.forest700, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              _isLoadingNative
                                  ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold500))
                                  : IconButton(
                                      onPressed: () => _playNativeAudio(currentItem),
                                      icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.gold500, size: 36),
                                    ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: _selectedDatasetIndex > 0
                                    ? () => setState(() => _selectedDatasetIndex--)
                                    : null,
                                icon: Icon(Icons.arrow_back_ios_rounded, color: _selectedDatasetIndex > 0 ? AppColors.gold500 : Colors.white24),
                              ),
                              Text(
                                'Phrase ${_selectedDatasetIndex + 1} of ${primaryEntries.length}',
                                style: AppTypography.mono.copyWith(color: isDark ? Colors.white70 : AppColors.forest800, fontSize: 11),
                              ),
                              IconButton(
                                onPressed: _selectedDatasetIndex < primaryEntries.length - 1
                                    ? () => setState(() => _selectedDatasetIndex++)
                                    : null,
                                icon: Icon(Icons.arrow_forward_ios_rounded, color: _selectedDatasetIndex < primaryEntries.length - 1 ? AppColors.gold500 : Colors.white24),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
                  error: (e, _) => Text('Error loading reference dataset: $e', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 28),

                // 3. Learner Pronunciation Attempts Table / List
                Text(
                  'Learner Pronunciation Practice History',
                  style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.forest900),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<LearnerAttempt>>(
                  future: ref.read(firebaseServiceProvider).fetchLearnerPronunciationAttempts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.gold500));
                    }
                    final attempts = snapshot.data ?? [];
                    if (attempts.isEmpty) {
                      return BrandCard(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No learner practice attempts logged yet. Attempts with scores ≥ 60% will appear here.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(color: isDark ? Colors.white60 : AppColors.forest700),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attempts.length,
                      itemBuilder: (context, index) {
                        final attempt = attempts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: attempt.bestScore >= 80 ? AppColors.semanticGreen : AppColors.gold500,
                                child: Text(
                                  '${attempt.bestScore.toInt()}%',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attempt.phraseTitle.isNotEmpty ? attempt.phraseTitle : attempt.phraseId,
                                      style: AppTypography.label.copyWith(color: isDark ? Colors.white : AppColors.forest900, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Learner ID: ${attempt.learnerId} • Attempts: ${attempt.attemptCount}',
                                      style: AppTypography.caption.copyWith(color: isDark ? Colors.white60 : AppColors.forest700, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                attempt.lastAttemptedAt.toLocal().toString().split('.')[0],
                                style: AppTypography.mono.copyWith(color: isDark ? Colors.white54 : AppColors.forest600, fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark) {
    return BrandCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.displayBold.copyWith(
              color: isDark ? Colors.white : AppColors.forest900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.forest700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/firebase_service.dart';
import '../../services/sentiment_service.dart';
import '../../services/pronunciation_service.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/brand_background.dart';

class AlgorithmSelectionScreen extends ConsumerStatefulWidget {
  const AlgorithmSelectionScreen({super.key});

  @override
  ConsumerState<AlgorithmSelectionScreen> createState() => _AlgorithmSelectionScreenState();
}

class _AlgorithmSelectionScreenState extends ConsumerState<AlgorithmSelectionScreen> {
  bool _isSaving = false;

  // Mock evaluation dataset for Pronunciation (since we can't easily load files here)
  final List<Map<String, dynamic>> _pronunciationEvalDataset = [
    {
      'native': [0.1, 0.5, 0.8, 0.4, 0.1],
      'user': [0.1, 0.45, 0.75, 0.4, 0.1],
      'label': 0.95,
    },
    {
      'native': [0.1, 0.5, 0.8, 0.4, 0.1],
      'user': [0.8, 0.1, 0.2, 0.1, 0.5],
      'label': 0.20,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: configAsync.when(
            data: (config) => _buildContent(config, isDark),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
            error: (e, _) => Center(child: Text('Error loading config: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(dynamic config, bool isDark) {
    return Column(
      children: [
        _buildAppBar(isDark),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Sentiment Analysis Models', 'Evaluation based on labeled community posts'),
                const SizedBox(height: 16),
                _buildSentimentGrid(config, isDark),
                const SizedBox(height: 40),
                _buildSectionHeader('Pronunciation Algorithms', 'Evaluation based on acoustic tone similarity'),
                const SizedBox(height: 16),
                _buildPronunciationGrid(config, isDark),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.forest900),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'MODEL DEPLOYMENT CONTROL',
            style: AppTypography.label.copyWith(
              color: AppColors.gold500,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h2.copyWith(color: Colors.white)),
        Text(subtitle, style: AppTypography.body.copyWith(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildSentimentGrid(dynamic config, bool isDark) {
    final sentimentService = ref.read(sentimentServiceProvider);
    
    return Column(
      children: SentimentModelType.values.map((model) {
        final metrics = sentimentService.calculateMetrics(model);
        final isSelected = config.activeSentimentAlgorithm == model.name;

        return _buildModelCard(
          title: _getSentimentModelName(model),
          isSelected: isSelected,
          metrics: {
            'Accuracy': '${(metrics.accuracy * 100).toStringAsFixed(1)}%',
            'F1-Score': metrics.f1Score.toStringAsFixed(2),
            'Precision': metrics.precision.toStringAsFixed(2),
          },
          onSelect: () => _updateActiveModel('sentiment', model.name),
        );
      }).toList(),
    );
  }

  Widget _buildPronunciationGrid(dynamic config, bool isDark) {
    return Column(
      children: PronunciationAlgorithm.values.map((algo) {
        final metrics = PronunciationService.calculateMetrics(algo, _pronunciationEvalDataset);
        final isSelected = config.activePronunciationAlgorithm == algo.name;

        return _buildModelCard(
          title: _getPronunciationAlgoName(algo),
          isSelected: isSelected,
          metrics: {
            'Accuracy': '${(metrics.accuracy * 100).toStringAsFixed(1)}%',
            'Correlation': metrics.correlation.toStringAsFixed(2),
            'MAE': metrics.meanAbsoluteError.toStringAsFixed(3),
          },
          onSelect: () => _updateActiveModel('pronunciation', algo.name),
        );
      }).toList(),
    );
  }

  Widget _buildModelCard({
    required String title,
    required bool isSelected,
    required Map<String, String> metrics,
    required VoidCallback onSelect,
  }) {
    return BrandCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      theme: isSelected ? BrandCardTheme.gold : BrandCardTheme.cream,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.h3.copyWith(
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: AppTypography.label.copyWith(color: AppColors.gold500, fontSize: 10),
                  ),
                )
              else
                BrandButton(
                  text: 'DEPLOY',
                  type: BrandButtonType.small,
                  onTap: _isSaving ? null : onSelect,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: metrics.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      color: isSelected ? Colors.black45 : Colors.white24,
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: AppTypography.mono.copyWith(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSentimentModelName(SentimentModelType type) {
    switch (type) {
      case SentimentModelType.naiveBayes: return 'Naïve Bayes';
      case SentimentModelType.svm: return 'Support Vector Machine';
      case SentimentModelType.biLstm: return 'Bidirectional LSTM';
    }
  }

  String _getPronunciationAlgoName(PronunciationAlgorithm type) {
    switch (type) {
      case PronunciationAlgorithm.dtw: return 'Dynamic Time Warping';
      case PronunciationAlgorithm.hmm: return 'Hidden Markov Model';
      case PronunciationAlgorithm.cosineSimilarity: return 'Cosine Similarity';
    }
  }

  Future<void> _updateActiveModel(String type, String value) async {
    setState(() => _isSaving = true);
    try {
      final config = ref.read(appConfigProvider).value;
      if (config == null) return;

      final Map<String, dynamic> updates = {};
      if (type == 'sentiment') {
        updates['activeSentimentAlgorithm'] = value;
      } else {
        updates['activePronunciationAlgorithm'] = value;
      }

      await ref.read(firebaseServiceProvider).updateAppConfig(updates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model "$value" locked for production deployment.'),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deployment failed: $e'), backgroundColor: AppColors.semanticRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

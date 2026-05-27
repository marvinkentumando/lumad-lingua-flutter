import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../services/pronunciation_service.dart';
import 'brand_card.dart';

class PronunciationAnalysisWidget extends StatelessWidget {
  final PronunciationScore score;

  const PronunciationAnalysisWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildScoreHeader(context),
          const SizedBox(height: 32),
          _buildWaveformComparison(context),
          const SizedBox(height: 32),
          _buildMetricRow(context),
          const SizedBox(height: 24),
          _buildFeedbackText(context),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: score.overallScore / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white10,
                color: _getScoreColor(score.overallScore),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score.overallScore.toStringAsFixed(0),
                  style: AppTypography.displayBold.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.forest900,
                    fontSize: 32,
                  ),
                ),
                Text(
                  'SCORE',
                  style: AppTypography.label.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white24
                        : AppColors.creamText3,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'AI Analysis Result',
          style: AppTypography.h3.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.gold500
                : AppColors.forest500,
            fontSize: 18,
          ),
        ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildWaveformComparison(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWaveLabel(
          'NATIVE FINGERPRINT',
          isDark ? Colors.white38 : AppColors.creamText2,
        ),
        const SizedBox(height: 8),
        _buildWaveform(
          score.nativeWaveform,
          AppColors.gold500.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        _buildWaveLabel('YOUR FINGERPRINT', AppColors.semanticBlue),
        const SizedBox(height: 8),
        _buildWaveform(score.studentWaveform, AppColors.semanticBlue),
      ],
    );
  }

  Widget _buildWaveLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform(List<double> values, Color color) {
    if (values.isEmpty) return const SizedBox(height: 40);

    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: values.map((v) {
          return Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              height: (v * 40).clamp(2.0, 40.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }

  Widget _buildMetricRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric(context, 'ACCURACY', score.accuracy),
        _buildMetric(context, 'FLUENCY', score.fluency),
        _buildMetric(context, 'CLARITY', score.clarity),
      ],
    );
  }

  Widget _buildMetric(BuildContext context, String label, double value) {
    return Column(
      children: [
        Text(
          '${(value * 100).toStringAsFixed(0)}%',
          style: AppTypography.h3.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.forest700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white24
                : AppColors.creamText3,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackText(BuildContext context) {
    String feedback;
    if (score.overallScore > 90) {
      feedback = "Native-like! Your pronunciation is exceptional.";
    } else if (score.overallScore > 75) {
      feedback = "Great job! Minor adjustments in pitch needed.";
    } else {
      feedback = "Keep practicing. Focus on the vowel emphasis.";
    }

    return Text(
      feedback,
      textAlign: TextAlign.center,
      style: AppTypography.body.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : AppColors.creamText,
        fontSize: 13,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score > 85) return AppColors.semanticGreen;
    if (score > 65) return AppColors.gold500;
    return AppColors.terracotta;
  }
}




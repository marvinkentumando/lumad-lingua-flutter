import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/firebase_service.dart';
import '../../models/assessment.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/brand_background.dart';
import '../../widgets/branded_empty_state.dart';
import '../../utils/app_localization.dart';

class AdminAssessmentsScreen extends ConsumerWidget {
  const AdminAssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentResultsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark, l10n),
              Expanded(
                child: assessmentsAsync.when(
                  data: (data) => data.isEmpty
                      ? BrandedEmptyState.empty(
                          title: l10n.translate('no_assessments_title'),
                          message: l10n.translate('no_assessments_message'),
                          advice: 'Completed pronunciation and dialect assessments will appear here.',
                          imagePath: 'assets/images/lumad_character (1).png',
                          icon: Icons.assignment_turned_in_rounded,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: data.length,
                          itemBuilder: (context, index) => _buildAssessmentCard(data[index], isDark, index, l10n),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
                  error: (e, _) => BrandedEmptyState.error(
                    error: e.toString(),
                    advice: 'Unable to load assessment records. Tap retry to reconnect.',
                    onRetry: () => ref.invalidate(assessmentResultsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppLocalization l10n) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.forest900),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.translate('effectiveness_assessments'),
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

  Widget _buildAssessmentCard(AssessmentResult assessment, bool isDark, int index, AppLocalization l10n) {
    const cardTextColor = AppColors.forest900;
    final cardSubColor = AppColors.forest700.withValues(alpha: 0.8);
    final cardLabelColor = AppColors.forest900.withValues(alpha: 0.5);

    return BrandCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      theme: assessment.type == AssessmentType.preTest ? BrandCardTheme.cream : BrandCardTheme.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.forest900.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assessment.type == AssessmentType.preTest ? l10n.translate('pre_test') : l10n.translate('post_test'),
                  style: AppTypography.label.copyWith(
                    color: assessment.type == AssessmentType.preTest ? AppColors.semanticBlue : AppColors.forest900,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(assessment.timestamp),
                style: AppTypography.label.copyWith(color: cardLabelColor, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.translate('user_id')}: ${assessment.userId}',
            style: AppTypography.mono.copyWith(fontSize: 10, color: cardSubColor),
          ),
          if (assessment.lessonTitle != null || assessment.lessonId != null)
            Text(
              '${l10n.translate('lesson')}: ${assessment.lessonTitle ?? assessment.lessonId}',
              style: AppTypography.body.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: cardTextColor),
            ),
          if (assessment.ratingScore != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < assessment.ratingScore!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.gold500,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('stars_count', params: {'count': '${assessment.ratingScore}'}),
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cardTextColor,
                  ),
                ),
              ],
            ),
          ],
          if (assessment.openTextFeedback != null &&
              assessment.openTextFeedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.forest900.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${assessment.openTextFeedback}"',
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: cardTextColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: AppColors.forest900.withValues(alpha: 0.12)),
          const SizedBox(height: 8),
          ...assessment.answers.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: AppTypography.label.copyWith(color: cardLabelColor, fontSize: 8),
                    ),
                    Text(
                      entry.value.toString(),
                      style: AppTypography.body.copyWith(color: cardTextColor, fontSize: 13),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
  }
}

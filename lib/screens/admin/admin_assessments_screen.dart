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

class AdminAssessmentsScreen extends ConsumerWidget {
  const AdminAssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentResultsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: assessmentsAsync.when(
                  data: (data) => data.isEmpty
                      ? const BrandedEmptyState(
                          title: 'No Assessments Yet',
                          message: 'Learning effectiveness tests will appear here once learners complete them.',
                          icon: Icons.assignment_turned_in_rounded,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: data.length,
                          itemBuilder: (context, index) => _buildAssessmentCard(data[index], isDark, index),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
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
            'EFFECTIVENESS ASSESSMENTS',
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

  Widget _buildAssessmentCard(AssessmentResult assessment, bool isDark, int index) {
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
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assessment.type == AssessmentType.preTest ? 'PRE-TEST' : 'POST-TEST',
                  style: AppTypography.label.copyWith(
                    color: assessment.type == AssessmentType.preTest ? AppColors.semanticBlue : AppColors.forest900,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(assessment.timestamp),
                style: AppTypography.label.copyWith(color: Colors.black26, fontSize: 8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'User ID: ${assessment.userId}',
            style: AppTypography.mono.copyWith(fontSize: 10, color: Colors.black45),
          ),
          if (assessment.lessonId != null)
            Text(
              'Lesson: ${assessment.lessonId}',
              style: AppTypography.body.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12),
          const SizedBox(height: 8),
          ...assessment.answers.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: AppTypography.label.copyWith(color: Colors.black38, fontSize: 8),
                    ),
                    Text(
                      entry.value.toString(),
                      style: AppTypography.body.copyWith(color: Colors.black87, fontSize: 13),
                    ),
                  ],
                ),
              )),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
  }
}

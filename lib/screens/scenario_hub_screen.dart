import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../providers/student_provider.dart';

class ScenarioHubScreen extends ConsumerWidget {
  const ScenarioHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    // Assuming scenario completion is tracked in lessonProgress or a similar map
    final completedScenarios = student.lessonProgress;

    return Scaffold(
      body: Stack(
        children: [
          BrandBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          'Scenario Stories',
                          style: AppTypography.displayBold.copyWith(
                            color: AppColors.gold500,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your path. Every word matters.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildScenarioCard(
                          context,
                          title: 'The Elder\'s Request',
                          description:
                              'Help an elder navigate the forest by following their Mansaka instructions.',
                          difficulty: 'Beginner',
                          reward: '50 XP',
                          id: 'elders_request',
                          icon: Icons.person_search_rounded,
                          isCompleted: completedScenarios.containsKey('elders_request'),
                        ),
                        const SizedBox(height: 16),
                        _buildScenarioCard(
                          context,
                          title: 'Market Negotiations',
                          description:
                              'Trade goods at the local market using traditional counting and naming.',
                          difficulty: 'Intermediate',
                          reward: '100 XP',
                          id: 'market_negotiations',
                          icon: Icons.storefront_rounded,
                          isCompleted: completedScenarios.containsKey('market_negotiations'),
                        ),
                        const SizedBox(height: 16),
                        _buildScenarioCard(
                          context,
                          title: 'The Sacred Ritual',
                          description:
                              'Participate in a village ceremony and learn the sacred terminology.',
                          difficulty: 'Advanced',
                          reward: '200 XP',
                          id: 'sacred_ritual',
                          icon: Icons.auto_awesome_rounded,
                          isCompleted: completedScenarios.containsKey('sacred_ritual'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context, {
    required String title,
    required String description,
    required String difficulty,
    required String reward,
    required String id,
    required IconData icon,
    bool isCompleted = false,
  }) {
    return BrandCard(
      theme: isCompleted ? BrandCardTheme.gold : BrandCardTheme.vibrant,
      child: InkWell(
        onTap: () {
          // Navigate to scenario session
          context.push('/scenario-session/$id');
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isCompleted ? Colors.black : AppColors.gold500)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? Colors.black87 : AppColors.gold500,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isCompleted ? Colors.black : AppColors.gold500)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (isCompleted ? Colors.black : AppColors.gold500)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isCompleted ? 'MASTERED' : difficulty.toUpperCase(),
                            style: AppTypography.label.copyWith(
                              color: isCompleted ? Colors.black : AppColors.gold500,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.black54, size: 20)
                        else
                          Text(
                            reward,
                            style: AppTypography.mono.copyWith(
                              color: AppColors.gold500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: AppTypography.h2.copyWith(
                        color: isCompleted ? Colors.black : Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.body.copyWith(
                        color: isCompleted ? Colors.black54 : Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.replay_rounded
                              : Icons.play_circle_filled_rounded,
                          color: isCompleted ? Colors.black : AppColors.gold500,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompleted ? 'REPLAY STORY' : 'START SCENARIO',
                          style: AppTypography.label.copyWith(
                            color: isCompleted ? Colors.black : AppColors.gold500,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}




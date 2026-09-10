import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../providers/student_provider.dart';
import '../services/haptic_service.dart';
import '../services/firebase_service.dart';

class ScenarioHubScreen extends ConsumerWidget {
  const ScenarioHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider);
    final completedScenarios = student.lessonProgress;
    final scenariosAsync = ref.watch(scenariosProvider);

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
                    child: scenariosAsync.when(
                      data: (scenarios) => ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: scenarios.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                              ],
                            );
                          }

                          final scenario = scenarios[index - 1];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildScenarioCard(
                              context,
                              title: scenario.title,
                              description: scenario.description,
                              difficulty: scenario.difficulty,
                              reward: '${scenario.baseReward} XP',
                              id: scenario.id,
                              icon: _getIconData(scenario.iconName),
                              isCompleted: completedScenarios.containsKey(scenario.id),
                            ),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
                      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
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

  IconData _getIconData(String name) {
    switch (name) {
      case 'person_search': return Icons.person_search_rounded;
      case 'storefront': return Icons.storefront_rounded;
      case 'auto_awesome': return Icons.auto_awesome_rounded;
      default: return Icons.auto_stories_rounded;
    }
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
          HapticService.selection();
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




import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../providers/student_provider.dart';
import '../models/scenario_models.dart';

class ScenarioSessionScreen extends ConsumerStatefulWidget {
  final String scenarioId;
  const ScenarioSessionScreen({super.key, required this.scenarioId});

  @override
  ConsumerState<ScenarioSessionScreen> createState() => _ScenarioSessionScreenState();
}

class _ScenarioSessionScreenState extends ConsumerState<ScenarioSessionScreen> {
  Scenario? _scenario;
  String? _currentNodeId;
  int _totalXp = 0;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScenario();
  }

  Future<void> _loadScenario() async {
    try {
      final scenario = await ref.read(firebaseServiceProvider).getScenarioById(widget.scenarioId);
      if (mounted) {
        setState(() {
          _scenario = scenario;
          _currentNodeId = scenario?.initialNodeId ?? 'start';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading scenario: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleChoice(ScenarioChoice choice) async {
    if (choice.targetNodeId == 'end') {
      if (_isSaving) return;
      setState(() => _isSaving = true);
      
      try {
        final user = ref.read(authServiceProvider).currentUser;
        if (user != null) {
          // Add a base reward for completion
          final completionXp = _totalXp + (_scenario?.baseReward ?? 20);
          await ref.read(firebaseServiceProvider).completeScenario(
            user.uid, 
            widget.scenarioId, 
            completionXp,
          );
          // Manually update local state to reflect change immediately
          ref.read(studentProvider.notifier).addXp(completionXp);
        }
      } catch (e) {
        debugPrint("Error saving scenario progress: $e");
      } finally {
        if (mounted) {
          context.pop();
        }
      }
      return;
    }
    setState(() {
      _totalXp += choice.xpReward;
      _currentNodeId = choice.targetNodeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.forest900,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold500)),
      );
    }

    if (_scenario == null || _currentNodeId == null) {
      return Scaffold(
        backgroundColor: AppColors.forest900,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scenario not found', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              BrandButton(text: 'Go Back', onTap: () => context.pop(), type: BrandButtonType.primary),
            ],
          ),
        ),
      );
    }

    final node = _scenario!.nodes[_currentNodeId];

    return Scaffold(
      body: Stack(
        children: [
          BrandBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (node != null) ...[
                            _buildNodeImage(node.imagePath ?? ''),
                            const SizedBox(height: 32),
                            _buildStoryText(node.text),
                            const SizedBox(height: 48),
                            if (_isSaving)
                              const Center(child: CircularProgressIndicator(color: AppColors.gold500))
                            else
                              _buildChoices(node.choices),
                          ] else
                            const Center(child: Text('Invalid Story State', style: TextStyle(color: Colors.white))),
                        ],
                      ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold500.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on, color: AppColors.gold500, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$_totalXp XP EARNED',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.gold500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeImage(String path) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Icon(
          Icons.auto_stories,
          size: 80,
          color: AppColors.gold500.withValues(alpha: 0.2),
        ),
        // In a real app: Image.asset(path, fit: BoxFit.cover),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStoryText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.h2.copyWith(
        color: Colors.white,
        height: 1.5,
        fontSize: 20,
      ),
    ).animate(key: ValueKey(_currentNodeId)).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildChoices(List<ScenarioChoice> choices) {
    return Column(
      children: choices.map((choice) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            child: BrandButton(
              text: choice.label,
              onTap: () => _handleChoice(choice),
              type: BrandButtonType.secondary,
            ),
          ),
        );
      }).toList(),
    ).animate(key: ValueKey(_currentNodeId)).fadeIn(delay: 400.ms);
  }
}




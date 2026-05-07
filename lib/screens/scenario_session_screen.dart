import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';

class ScenarioNode {
  final String text;
  final String imagePath;
  final List<ScenarioChoice> choices;

  ScenarioNode({
    required this.text,
    required this.imagePath,
    required this.choices,
  });
}

class ScenarioChoice {
  final String label;
  final String targetNodeId;
  final int xpReward;

  ScenarioChoice({
    required this.label,
    required this.targetNodeId,
    this.xpReward = 0,
  });
}

class ScenarioSessionScreen extends StatefulWidget {
  final String scenarioId;
  const ScenarioSessionScreen({super.key, required this.scenarioId});

  @override
  State<ScenarioSessionScreen> createState() => _ScenarioSessionScreenState();
}

class _ScenarioSessionScreenState extends State<ScenarioSessionScreen> {
  late String _currentNodeId;
  int _totalXp = 0;

  // Hardcoded scenario for demonstration
  final Map<String, ScenarioNode> _nodes = {
    'start': ScenarioNode(
      text:
          "You arrive at the edge of the forest. An elder approaches you and speaks in Mansaka: 'Madyaw na allaw, kailan. Hain kaw padulong?'",
      imagePath: 'assets/images/scenario_forest.png',
      choices: [
        ScenarioChoice(
          label: "Padulong ako sa sapa. (I am going to the river.)",
          targetNodeId: 'river',
        ),
        ScenarioChoice(
          label: "Padulong ako sa bukid. (I am going to the mountain.)",
          targetNodeId: 'mountain',
        ),
      ],
    ),
    'river': ScenarioNode(
      text:
          "At the river, you see children playing. They ask if you have seen the 'isda'.",
      imagePath: 'assets/images/scenario_river.png',
      choices: [
        ScenarioChoice(
          label: "Oo, nakita nako. (Yes, I saw it.)",
          targetNodeId: 'success',
          xpReward: 20,
        ),
        ScenarioChoice(
          label: "Wala pa nako nakita. (I haven't seen it yet.)",
          targetNodeId: 'start',
        ),
      ],
    ),
    'mountain': ScenarioNode(
      text:
          "The mountain air is cold. You meet a hunter who needs help tracking a 'langgam'.",
      imagePath: 'assets/images/scenario_mountain.png',
      choices: [
        ScenarioChoice(
          label: "Tabangan tika. (I will help you.)",
          targetNodeId: 'success',
          xpReward: 25,
        ),
        ScenarioChoice(
          label: "Dili ko kabalo. (I don't know how.)",
          targetNodeId: 'start',
        ),
      ],
    ),
    'success': ScenarioNode(
      text:
          "Excellent! You have successfully navigated the conversation and helped the community. Your understanding of the language grows.",
      imagePath: 'assets/images/scenario_success.png',
      choices: [ScenarioChoice(label: "Finish Story", targetNodeId: 'end')],
    ),
  };

  @override
  void initState() {
    super.initState();
    _currentNodeId = 'start';
  }

  void _handleChoice(ScenarioChoice choice) {
    if (choice.targetNodeId == 'end') {
      context.pop();
      return;
    }
    setState(() {
      _totalXp += choice.xpReward;
      _currentNodeId = choice.targetNodeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final node = _nodes[_currentNodeId] ?? _nodes['start']!;

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
                          _buildNodeImage(node.imagePath),
                          const SizedBox(height: 32),
                          _buildStoryText(node.text),
                          const SizedBox(height: 48),
                          _buildChoices(node.choices),
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
              color: AppColors.gold500.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold500.withOpacity(0.3),
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
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Icon(
          Icons.auto_stories,
          size: 80,
          color: AppColors.gold500.withOpacity(0.2),
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



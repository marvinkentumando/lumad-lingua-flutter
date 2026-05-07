import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../services/haptic_service.dart';

enum DuelPhase { idle, searching, matchFound, battling, results }

class LinguaDuelScreen extends StatefulWidget {
  const LinguaDuelScreen({super.key});

  @override
  State<LinguaDuelScreen> createState() => _LinguaDuelScreenState();
}

class _LinguaDuelScreenState extends State<LinguaDuelScreen> {
  DuelPhase _phase = DuelPhase.idle;
  double _playerHp = 1.0;
  double _opponentHp = 1.0;
  int _currentQuestionIndex = 0;
  bool _isPlayerWinning = true;

  final List<Map<String, dynamic>> _hardcodedQuestions = [
    {
      'question': 'How do you say "Good Morning" in Mansaka?',
      'options': ['Madyaw na gabi', 'Madyaw na allaw', 'Madyaw na amase', 'Madyaw na hapon'],
      'correct': 2,
    },
    {
      'question': 'What does "Tribe" translate to?',
      'options': ['Kailan', 'Banwa', 'Lawa', 'Kabilin'],
      'correct': 1,
    },
    {
      'question': 'Translate: "The mountain is sacred"',
      'options': ['Banal ang bundok', 'Madyaw ang bukid', 'Sacred ang bukid', 'Banal ang langit'],
      'correct': 1,
    }
  ];

  void _startSearch() {
    HapticService.medium();
    setState(() => _phase = DuelPhase.searching);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _phase = DuelPhase.matchFound);
        HapticService.success();
      }
    });
  }

  void _beginBattle() {
    HapticService.heavy();
    setState(() {
      _phase = DuelPhase.battling;
      _playerHp = 1.0;
      _opponentHp = 1.0;
      _currentQuestionIndex = 0;
    });
  }

  void _handleAnswer(int index) {
    final isCorrect = index == _hardcodedQuestions[_currentQuestionIndex]['correct'];
    
    setState(() {
      if (isCorrect) {
        HapticService.light();
        _opponentHp = (_opponentHp - 0.35).clamp(0.0, 1.0);
      } else {
        HapticService.error();
        _playerHp = (_playerHp - 0.25).clamp(0.0, 1.0);
      }

      if (_opponentHp <= 0 || _playerHp <= 0 || _currentQuestionIndex >= _hardcodedQuestions.length - 1) {
        _isPlayerWinning = _playerHp >= _opponentHp;
        _phase = DuelPhase.results;
      } else {
        _currentQuestionIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildCurrentPhase(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_phase) {
      case DuelPhase.idle:
        return _buildLanding();
      case DuelPhase.searching:
        return _buildSearching();
      case DuelPhase.matchFound:
        return _buildMatchFound();
      case DuelPhase.battling:
        return _buildBattleArena();
      case DuelPhase.results:
        return _buildResults();
    }
  }

  Widget _buildLanding() {
    return Column(
      children: [
        _buildHeader('BATTLE HUB'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildMainGraphic(),
                const SizedBox(height: 40),
                Text(
                  'Lingua Duel',
                  style: AppTypography.displayBold.copyWith(
                    color: AppColors.gold500,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Challenge warriors to a real-time language duel.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 48),
                _buildDuelModeCard(
                  title: 'Quick Match',
                  subtitle: 'Battle a random learner',
                  icon: Icons.bolt_rounded,
                  onTap: _startSearch,
                ),
                const SizedBox(height: 16),
                _buildDuelModeCard(
                  title: 'Warriors Circle',
                  subtitle: 'Challenge a friend',
                  icon: Icons.people_rounded,
                  onTap: () => context.push('/warriors-circle'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearching() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.gold500),
        const SizedBox(height: 32),
        Text(
          'Summoning Opponents...',
          style: AppTypography.h2.copyWith(color: AppColors.gold500),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
        const SizedBox(height: 16),
        const Text(
          'Warriors are gathering at the spirit tree...',
          style: TextStyle(color: Colors.white38),
        ),
        const SizedBox(height: 48),
        BrandButton(
          text: 'CANCEL',
          onTap: () => setState(() => _phase = DuelPhase.idle),
          type: BrandButtonType.text,
        ),
      ],
    );
  }

  Widget _buildMatchFound() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'MATCH FOUND',
          style: AppTypography.label.copyWith(color: AppColors.gold500, letterSpacing: 4),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCombatantInfo('YOU', 'assets/images/lumad_character.png', isPlayer: true),
            Text('VS', style: AppTypography.displayBold.copyWith(color: AppColors.gold500, fontSize: 40)),
            _buildCombatantInfo('DATU MATU', 'assets/images/lumad_character (1).png', isPlayer: false),
          ],
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 60),
        BrandButton(
          text: 'START DUEL',
          onTap: _beginBattle,
          type: BrandButtonType.primary,
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }

  Widget _buildBattleArena() {
    final q = _hardcodedQuestions[_currentQuestionIndex];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(child: _buildHpBar('YOU', _playerHp, isPlayer: true)),
              const SizedBox(width: 20),
              Expanded(child: _buildHpBar('OPPONENT', _opponentHp, isPlayer: false)),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                'ROUND ${_currentQuestionIndex + 1}',
                style: AppTypography.label.copyWith(color: AppColors.gold500),
              ),
              const SizedBox(height: 12),
              Text(
                q['question'],
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 40),
              ...List.generate(q['options'].length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BrandButton(
                    text: q['options'][index],
                    onTap: () => _handleAnswer(index),
                    type: BrandButtonType.secondary,
                  ),
                );
              }),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isPlayerWinning ? Icons.emoji_events_rounded : Icons.sentiment_very_dissatisfied_rounded,
          size: 100,
          color: AppColors.gold500,
        ).animate().scale(duration: 1.seconds, curve: Curves.bounceOut),
        const SizedBox(height: 24),
        Text(
          _isPlayerWinning ? 'VICTORY!' : 'DEFEAT',
          style: AppTypography.displayBold.copyWith(
            color: _isPlayerWinning ? AppColors.gold500 : AppColors.semanticRed,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isPlayerWinning ? 'You have defended the ancestral honor.' : 'The mountain will remember your bravery.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 48),
        BrandButton(
          text: 'RETURN TO HUB',
          onTap: () => setState(() => _phase = DuelPhase.idle),
          type: BrandButtonType.primary,
        ),
      ],
    );
  }

  Widget _buildHpBar(String label, double val, {required bool isPlayer}) {
    return Column(
      crossAxisAlignment: isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTypography.label.copyWith(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              val > 0.3 ? (isPlayer ? Colors.greenAccent : Colors.orangeAccent) : AppColors.semanticRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCombatantInfo(String name, String asset, {required bool isPlayer}) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold500, width: 2),
            image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const Spacer(),
          Text(title, style: AppTypography.label.copyWith(color: Colors.white38, letterSpacing: 2)),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainGraphic() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.gold500.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold500.withOpacity(0.1), width: 2),
          ),
        ).animate(onPlay: (c) => c.repeat()).scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOut),
        const Icon(Icons.flash_on_rounded, size: 80, color: AppColors.gold500),
      ],
    );
  }

  Widget _buildDuelModeCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return BrandCard(
      theme: BrandCardTheme.vibrant,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.gold500.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.gold500),
        ),
        title: Text(title, style: AppTypography.h3.copyWith(color: Colors.white)),
        subtitle: Text(subtitle, style: AppTypography.body.copyWith(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}



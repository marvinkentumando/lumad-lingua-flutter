import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lumad_lingua/theme/app_colors.dart';
import 'package:lumad_lingua/theme/app_typography.dart';
import 'package:lumad_lingua/widgets/brand_button.dart';
import 'package:lumad_lingua/widgets/brand_background.dart';
import 'package:lumad_lingua/widgets/brand_card.dart';
import 'package:lumad_lingua/widgets/crystal_burst_animation.dart';
import 'package:lumad_lingua/services/haptic_service.dart';
import 'package:lumad_lingua/services/firebase_service.dart';
import 'package:lumad_lingua/models/quest.dart';
import 'package:lumad_lingua/services/auth_service.dart';
import 'package:lumad_lingua/providers/quest_provider.dart';
import 'package:lumad_lingua/providers/student_provider.dart';
import 'package:lumad_lingua/models/dictionary_entry.dart';
import 'package:lumad_lingua/utils/app_localization.dart';

enum DuelPhase { idle, searching, matchFound, battling, results }

class LinguaDuelScreen extends ConsumerStatefulWidget {
  const LinguaDuelScreen({super.key});

  @override
  ConsumerState<LinguaDuelScreen> createState() => _LinguaDuelScreenState();
}

class _LinguaDuelScreenState extends ConsumerState<LinguaDuelScreen> {
  DuelPhase _phase = DuelPhase.idle;
  double _playerHp = 1.0;
  double _opponentHp = 1.0;
  int _currentQuestionIndex = 0;
  bool _isPlayerWinning = true;
  
  String? _matchId;
  bool _isHost = false;
  StreamSubscription? _matchSubscription;
  Timer? _roundTimer;
  int _secondsLeft = 15;
  bool _showDamageEffect = false;
  List<Map<String, dynamic>> _battleQuestions = [];

  void _startMatchmaking() async {
    setState(() => _phase = DuelPhase.searching);
    HapticService.light();

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final matchQuery = await FirebaseFirestore.instance
          .collection('duel_matchmaking')
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      if (matchQuery.docs.isNotEmpty) {
        final doc = matchQuery.docs.first;
        _matchId = doc.id;
        _isHost = false;

        await doc.reference.update({
          'opponentId': user.uid,
          'opponentName': user.displayName ?? 'Warrior',
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        _isHost = true;
        final newDoc = await FirebaseFirestore.instance.collection('duel_matchmaking').add({
          'hostId': user.uid,
          'hostName': user.displayName ?? 'Warrior',
          'opponentId': null,
          'opponentName': null,
          'status': 'waiting',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _matchId = newDoc.id;
      }

      _listenToMatch();
    } catch (e) {
      debugPrint("Matchmaking error: $e");
      setState(() => _phase = DuelPhase.idle);
    }
  }

  void _listenToMatch() {
    if (_matchId == null) return;

    _matchSubscription = FirebaseFirestore.instance
        .collection('duel_matchmaking')
        .doc(_matchId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;

      if (data['status'] == 'active' && _phase == DuelPhase.searching) {
        _roundTimer?.cancel();
        setState(() => _phase = DuelPhase.matchFound);
        HapticService.celebration();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _generateBattleQuestions();
            setState(() {
              _phase = DuelPhase.battling;
              _playerHp = 1.0;
              _opponentHp = 1.0;
              _currentQuestionIndex = 0;
            });
            _startTimer();
          }
        });
      } else if (_phase == DuelPhase.battling) {
        final hostHp = (data['hostHp'] ?? 1.0).toDouble();
        final oppHp = (data['opponentHp'] ?? 1.0).toDouble();

        setState(() {
          _playerHp = _isHost ? hostHp : oppHp;
          _opponentHp = _isHost ? oppHp : hostHp;
        });

        if (_playerHp <= 0) {
          _roundTimer?.cancel();
          setState(() {
            _isPlayerWinning = false;
            _phase = DuelPhase.results;
          });
        }
        
        if (_opponentHp <= 0) {
          _roundTimer?.cancel();
          setState(() {
             _isPlayerWinning = true;
             _phase = DuelPhase.results;
          });
          _awardVictoryRewards();
        }
      }
    });
  }

  void _generateBattleQuestions() {
    final dictionary = ref.read(allWordsProvider).value ?? [];
    final l10n = ref.read(localizationProvider);
    
    List<Map<String, dynamic>> questions = [];
    
    if (dictionary.isNotEmpty) {
      final sample = List.from(dictionary)..shuffle();
      for (int i = 0; i < 5 && i < sample.length; i++) {
        final DictionaryEntry entry = sample[i];
        
        List<String> options = [entry.translation];
        final distractors = dictionary.where((w) => w.id != entry.id).toList()..shuffle();
        options.addAll(distractors.take(3).map((w) => w.translation));
        options.shuffle();

        questions.add({
          'question': l10n.translate('duel_question_prefix', params: {'word': entry.indigenousWord}),
          'options': options,
          'correct': options.indexOf(entry.translation),
        });
      }
    }

    if (questions.isEmpty) {
      questions = [
        {
          'question': l10n.translate('duel_question_gm'),
          'options': ['Madyaw na gabi', 'Madyaw na allaw', 'Madyaw na amase', 'Madyaw na hapon'],
          'correct': 2,
        },
        {
          'question': l10n.translate('duel_question_land'),
          'options': ['Duta', 'Danaw', 'Allaw', 'Gabi'],
          'correct': 0,
        }
      ];
    }

    _battleQuestions = questions;
  }

  void _startTimer() {
    _roundTimer?.cancel();
    setState(() => _secondsLeft = 15);
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _handleAnswer(-1);
      }
    });
  }

  void _handleAnswer(int selectedIndex) async {
    _roundTimer?.cancel();
    if (_battleQuestions.isEmpty) return;
    
    final q = _battleQuestions[_currentQuestionIndex];
    final isCorrect = selectedIndex == q['correct'];

    if (isCorrect) {
      HapticService.light();
      _opponentHp = math.max(0.0, _opponentHp - 0.25);
    } else {
      HapticService.error();
      _playerHp = math.max(0.0, _playerHp - 0.25);
      _showDamageEffect = true;
    }

    if (_matchId != null) {
      final updateData = _isHost
          ? {'opponentHp': _opponentHp, 'hostHp': _playerHp}
          : {'hostHp': _opponentHp, 'opponentHp': _playerHp};
      FirebaseFirestore.instance.collection('duel_matchmaking').doc(_matchId).update(updateData);
    }

    setState(() {});

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      if (_playerHp <= 0 || _opponentHp <= 0 || _currentQuestionIndex >= _battleQuestions.length - 1) {
        _phase = DuelPhase.results;
        if (_playerHp > _opponentHp) _isPlayerWinning = true;
        if (_playerHp < _opponentHp) _isPlayerWinning = false;
        
        if (_isPlayerWinning) _awardVictoryRewards();
        
        if (_matchId != null && _isHost) {
          FirebaseFirestore.instance.collection('duel_matchmaking').doc(_matchId).delete();
        }
      } else {
        _currentQuestionIndex++;
        _startTimer();
      }
    });
    
    if (_showDamageEffect) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _showDamageEffect = false);
    }
  }

  void _awardVictoryRewards() {
    ref.read(studentProvider.notifier).addXp(150);
    ref.read(studentProvider.notifier).addMistCrystals(25);
    ref.read(questActionProvider.notifier).updateProgress(QuestType.duel, 1);
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _matchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildCurrentPhase(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase(AppLocalization l10n) {
    switch (_phase) {
      case DuelPhase.idle:
        return _buildIdle(l10n);
      case DuelPhase.searching:
        return _buildSearching(l10n);
      case DuelPhase.matchFound:
        return _buildMatchFound(l10n);
      case DuelPhase.battling:
        return _buildBattling(l10n);
      case DuelPhase.results:
        return _buildResults(l10n);
    }
  }

  Widget _buildIdle(AppLocalization l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      key: const ValueKey('idle'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BrandCard(
          theme: isDark ? BrandCardTheme.cream : BrandCardTheme.gold,
          padding: const EdgeInsets.all(32),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fort_rounded, size: 80, color: AppColors.gold500),
              const SizedBox(height: 24),
              Text(
                l10n.translate('lingua_duel'),
                style: AppTypography.displayBold.copyWith(
                  color: isDark ? Colors.white : AppColors.forest900,
                  fontSize: 28,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.translate('duel_desc'),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.forest700,
                ),
              ),
              const SizedBox(height: 32),
              BrandButton(
                text: l10n.translate('enter_arena'),
                onTap: _startMatchmaking,
                type: BrandButtonType.primary,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.translate('retreat'), style: TextStyle(color: isDark ? Colors.white60 : AppColors.forest600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearching(AppLocalization l10n) {
    return Center(
      key: const ValueKey('searching'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.gold500)
              .animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds, curve: Curves.easeInOut),
          const SizedBox(height: 32),
          Text(
            l10n.translate('seeking_opponent'),
            style: AppTypography.label.copyWith(color: AppColors.gold500, letterSpacing: 4),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('stirring_spirits'),
            style: AppTypography.body.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchFound(AppLocalization l10n) {
    return Center(
      key: const ValueKey('matchFound'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on_rounded, size: 80, color: AppColors.gold500)
              .animate()
              .shake(duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            l10n.translate('match_found'),
            style: AppTypography.displayBold.copyWith(color: Colors.white, fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('prepare_combat'),
            style: AppTypography.body.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildBattling(AppLocalization l10n) {
    if (_battleQuestions.isEmpty) return const SizedBox.shrink();
    final q = _battleQuestions[_currentQuestionIndex];

    return Stack(
      key: const ValueKey('battling'),
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.translate('you_label'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _playerHp,
                          child: Container(decoration: BoxDecoration(color: AppColors.semanticGreen, borderRadius: BorderRadius.circular(6))),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.gold500, shape: BoxShape.circle),
                    child: Text(
                      '$_secondsLeft',
                      style: AppTypography.mono.copyWith(color: AppColors.forest900, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(l10n.translate('ancestral_guardian').toUpperCase(), style: const TextStyle(color: AppColors.gold500, fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 4),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: _opponentHp,
                          child: Container(decoration: BoxDecoration(color: AppColors.semanticRed, borderRadius: BorderRadius.circular(6))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: BrandCard(
                theme: BrandCardTheme.gold,
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                child: Text(
                  q['question'],
                  textAlign: TextAlign.center,
                  style: AppTypography.h2.copyWith(color: Colors.white),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
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
        ),
        if (_showDamageEffect)
           Center(child: CrystalBurstAnimation(onComplete: () {
             if (mounted) setState(() => _showDamageEffect = false);
           })),
      ],
    );
  }

  Widget _buildResults(AppLocalization l10n) {
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
          _isPlayerWinning ? l10n.translate('victory') : l10n.translate('defeat'),
          style: AppTypography.displayBold.copyWith(
            color: _isPlayerWinning ? AppColors.gold500 : AppColors.semanticRed,
            fontSize: 48,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isPlayerWinning ? l10n.translate('victory_reward') : l10n.translate('defeat_desc'),
          style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: BrandButton(
            text: l10n.translate('leave_arena'),
            onTap: () => context.pop(),
            type: BrandButtonType.primary,
          ),
        ),
      ],
    );
  }
}

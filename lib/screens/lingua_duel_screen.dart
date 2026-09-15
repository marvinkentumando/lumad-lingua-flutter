import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../services/haptic_service.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_card.dart';
import '../widgets/crystal_burst_animation.dart';
import '../services/haptic_service.dart';
import '../services/firebase_service.dart';
import '../providers/quest_provider.dart';
import '../models/quest.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

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
  
  // Real-time & Game Logic
  Timer? _roundTimer;
  int _timeLeft = 10;
  int _comboCount = 0;
  String? _matchId;
  final math.Random _random = math.Random();
  List<Map<String, dynamic>> _battleQuestions = [];
  
  // Opponent Mock Info (In real Firebase sync, this would come from the match doc)
  String _opponentName = "DATU MATU";
  String _opponentAvatar = "assets/images/lumad_character (1).png";
  String _opponentTitle = "Ancestral Guardian";

  StreamSubscription? _matchSubscription;
  bool _isHost = false;

  void _startSearch() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    HapticService.medium();
    setState(() => _phase = DuelPhase.searching);

    final db = FirebaseFirestore.instance;
    
    try {
      // 1. Look for available matches
      final availableMatches = await db.collection('duel_matchmaking')
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      if (availableMatches.docs.isNotEmpty) {
        // Join existing match
        final matchDoc = availableMatches.docs.first;
        _matchId = matchDoc.id;
        _isHost = false;

        await matchDoc.reference.update({
          'opponentId': user.uid,
          'opponentName': user.displayName ?? 'Warrior',
          'status': 'matched',
        });
      } else {
        // Create new match
        _isHost = true;
        final newMatch = await db.collection('duel_matchmaking').add({
          'hostId': user.uid,
          'hostName': user.displayName ?? 'Warrior',
          'status': 'waiting',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _matchId = newMatch.id;
      }

      // 2. Listen for match updates
      _matchSubscription = db.collection('duel_matchmaking').doc(_matchId).snapshots().listen((snap) {
        if (!snap.exists) return;
        final data = snap.data()!;
        
        if (data['status'] == 'matched' && _phase == DuelPhase.searching) {
          if (!_isHost) {
            setState(() {
              _opponentName = data['hostName'] ?? "Opponent";
            });
          } else {
            setState(() {
              _opponentName = data['opponentName'] ?? "Opponent";
            });
          }
          
          _generateBattleQuestions();
          setState(() => _phase = DuelPhase.matchFound);
          HapticService.success();
        }

        // Real-time HP sync
        if (_phase == DuelPhase.battling) {
          setState(() {
            if (_isHost) {
              _opponentHp = (data['opponentHp'] ?? 1.0).toDouble();
            } else {
              _opponentHp = (data['hostHp'] ?? 1.0).toDouble();
            }
          });
          
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

    } catch (e) {
      debugPrint("Matchmaking error: $e");
      setState(() => _phase = DuelPhase.idle);
    }
  }

  void _generateBattleQuestions() {
    final dictionary = ref.read(allWordsProvider).value ?? [];
    
    List<Map<String, dynamic>> questions = [];
    
    // Mix of dictionary and lesson terms
    if (dictionary.isNotEmpty) {
      final sample = List.from(dictionary)..shuffle();
      for (int i = 0; i < 5 && i < sample.length; i++) {
        final entry = sample[i] as DictionaryEntry;
        
        // Generate distractors
        List<String> options = [entry.translation];
        final distractors = dictionary.where((w) => w.id != entry.id).toList()..shuffle();
        options.addAll(distractors.take(3).map((w) => w.translation));
        options.shuffle();

        questions.add({
          'question': 'What does "${entry.indigenousWord}" mean?',
          'options': options,
          'correct': options.indexOf(entry.translation),
        });
      }
    }

    if (questions.isEmpty) {
      // Fallback
      questions = [
        {
          'question': 'How do you say "Good Morning" in Mansaka?',
          'options': ['Madyaw na gabi', 'Madyaw na allaw', 'Madyaw na amase', 'Madyaw na hapon'],
          'correct': 2,
        },
      ];
    }
    
    setState(() {
      _battleQuestions = questions;
    });
  }

  void _startTimer() {
    _roundTimer?.cancel();
    _timeLeft = 10;
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _handleAnswer(-1); // Timeout
        }
      });
    });
  }

  void _beginBattle() {
    HapticService.heavy();
    setState(() {
      _phase = DuelPhase.battling;
      _playerHp = 1.0;
      _opponentHp = 1.0;
      _currentQuestionIndex = 0;
      _comboCount = 0;
    });
    
    // Sync initial HP to Firestore
    if (_matchId != null) {
      FirebaseFirestore.instance.collection('duel_matchmaking').doc(_matchId).update({
        _isHost ? 'hostHp' : 'opponentHp': 1.0,
      });
    }
    
    _startTimer();
  }

  bool _showDamageEffect = false;

  void _handleAnswer(int index) async {
    _roundTimer?.cancel();
    final q = _battleQuestions[_currentQuestionIndex];
    final isCorrect = index == q['correct'];
    
    setState(() {
      if (isCorrect) {
        HapticService.light();
        _comboCount++;
        _showDamageEffect = true;
        
        // Calculate Damage: Base 0.2 + Speed Bonus (up to 0.1) + Combo (up to 0.1)
        double speedBonus = (_timeLeft / 10.0) * 0.1;
        double comboBonus = math.min(_comboCount - 1, 2) * 0.05;
        double damage = 0.2 + speedBonus + comboBonus;
        
        _opponentHp = (_opponentHp - damage).clamp(0.0, 1.0);
      } else {
        HapticService.error();
        _comboCount = 0;
        _playerHp = (_playerHp - 0.2).clamp(0.0, 1.0);
      }

      // Sync HP to Firestore
      if (_matchId != null) {
        FirebaseFirestore.instance.collection('duel_matchmaking').doc(_matchId).update({
          _isHost ? 'hostHp' : 'opponentHp': _playerHp,
        });
      }

      if (_opponentHp <= 0 || _playerHp <= 0 || _currentQuestionIndex >= _battleQuestions.length - 1) {
        _isPlayerWinning = _playerHp >= _opponentHp;
        _phase = DuelPhase.results;
        if (_isPlayerWinning) _awardVictoryRewards();
        
        // Cleanup match doc
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
    final userProfile = ref.watch(userProfileProvider).value;
    final playerName = userProfile?['username'] ?? 'YOU';
    final playerAvatar = userProfile?['avatar'] ?? 'assets/images/lumad_character.png';

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
            _buildCombatantInfo(playerName.toUpperCase(), playerAvatar, isPlayer: true),
            Text('VS', style: AppTypography.displayBold.copyWith(color: AppColors.gold500, fontSize: 40)),
            _buildCombatantInfo(_opponentName.toUpperCase(), _opponentAvatar, isPlayer: false),
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
    final q = _battleQuestions[_currentQuestionIndex];
    final userProfile = ref.watch(userProfileProvider).value;
    final playerName = userProfile?['username'] ?? 'YOU';

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(child: _buildHpBar(playerName.toUpperCase(), _playerHp, isPlayer: true)),
                  const SizedBox(width: 40),
                  Expanded(child: _buildHpBar(_opponentName.toUpperCase(), _opponentHp, isPlayer: false)),
                ],
              ),
            ),
            
            // Timer Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _timeLeft / 10,
                  minHeight: 2,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _timeLeft > 3 ? AppColors.gold500 : AppColors.semanticRed,
                  ),
                ),
              ),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ROUND ${_currentQuestionIndex + 1}',
                        style: AppTypography.label.copyWith(color: AppColors.gold500),
                      ),
                      if (_comboCount > 1) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.semanticRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'COMBO X$_comboCount',
                            style: AppTypography.label.copyWith(color: Colors.white, fontSize: 10),
                          ),
                        ).animate().shake(),
                      ],
                    ],
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
        ),
        
        // Damage/Effect Overlay
        if (_showDamageEffect)
           const Center(child: CrystalBurstAnimation()),
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
        if (_isPlayerWinning) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRewardBadge('+150 XP', Icons.trending_up_rounded),
              const SizedBox(width: 16),
              _buildRewardBadge('+25 CRYSTALS', Icons.auto_awesome_rounded),
            ],
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ],
        const SizedBox(height: 48),
        BrandButton(
          text: 'RETURN TO HUB',
          onTap: () => setState(() => _phase = DuelPhase.idle),
          type: BrandButtonType.primary,
        ),
      ],
    );
  }

  Widget _buildRewardBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold500, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.label.copyWith(color: AppColors.gold500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHpBar(String label, double val, {required bool isPlayer}) {
    return Column(
      crossAxisAlignment: isPlayer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTypography.label.copyWith(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            AnimatedContainer(
              duration: 300.ms,
              height: 10,
              width: (MediaQuery.of(context).size.width * 0.35) * val,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: val > 0.3 
                      ? (isPlayer ? [Colors.greenAccent, Colors.green] : [Colors.orangeAccent, Colors.deepOrange]) 
                      : [AppColors.semanticRed, Colors.red.shade900],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: (val > 0.3 ? (isPlayer ? Colors.green : Colors.orange) : Colors.red).withValues(alpha: 0.5),
                    blurRadius: 8,
                  )
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCombatantInfo(String name, String avatar, {required bool isPlayer}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3), width: 2),
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.gold500.withValues(alpha: 0.1),
              backgroundImage: avatar.startsWith('http') 
                  ? NetworkImage(avatar) as ImageProvider 
                  : (avatar.contains('👤') ? null : AssetImage(avatar)),
              child: avatar.contains('👤') ? const Text('👤', style: TextStyle(fontSize: 40)) : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name, 
          style: AppTypography.h3.copyWith(color: Colors.white, fontSize: 14, letterSpacing: 1.2),
        ),
        Text(
          isPlayer ? (ref.watch(studentProvider).levelTitle) : _opponentTitle,
          style: AppTypography.label.copyWith(color: AppColors.gold500, fontSize: 8),
        ),
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
            color: AppColors.gold500.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.1), width: 2),
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
          decoration: BoxDecoration(color: AppColors.gold500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.gold500),
        ),
        title: Text(title, style: AppTypography.h3.copyWith(color: Colors.white)),
        subtitle: Text(subtitle, style: AppTypography.body.copyWith(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}




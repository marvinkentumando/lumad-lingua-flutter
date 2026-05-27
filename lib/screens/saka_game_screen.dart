import 'dart:ui';
import 'dart:math';
import '../widgets/saka_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/quest_provider.dart';
import '../models/quest.dart';

class SakaGameScreen extends ConsumerStatefulWidget {
  const SakaGameScreen({super.key});

  @override
  ConsumerState<SakaGameScreen> createState() => _SakaGameScreenState();
}

class _SakaGameScreenState extends ConsumerState<SakaGameScreen> with TickerProviderStateMixin {
  // Game State
  double playerX = 0;
  double playerY = 348;
  double velocityX = 0;
  double velocityY = 0;
  bool isJumping = false;
  bool isMovingLeft = false;
  bool isMovingRight = false;
  bool isQuizActive = false;
  int currentStage = 1;
  double score = 0;
  double standingStillTime = 0;
  String? currentLore;

  // VFX State
  final List<Offset> playerTrail = [];
  double transitionOpacity = 0;
  Color transitionColor = Colors.black;
  double landingSquash = 0;
  double mistTransition = 0;
  bool isVictorySequence = false;
  double victoryTimer = 0;
  final List<SakaEnvParticle> envParticles = [];

  // Constants
  static const double groundLevel = 348;
  static const double targetX = 5400;
  static const double gravity = 40.0;
  static const double jumpForce = -800.0;
  static const double baseMoveSpeed = 350.0;

  // Slope Segments (Varied Terrain)
  final List<SakaSegment> segments = [
    SakaSegment(startX: 0, endX: 800, startY: 348, endY: 340),      // Level-ish start
    SakaSegment(startX: 800, endX: 1600, startY: 340, endY: 280),   // Gentle climb
    SakaSegment(startX: 1600, endX: 2400, startY: 280, endY: 300),  // Slight dip near waterfall
    SakaSegment(startX: 2400, endX: 3200, startY: 300, endY: 240),  // Forest incline
    SakaSegment(startX: 3200, endX: 4200, startY: 240, endY: 210),  // Rocky ridge
    SakaSegment(startX: 4200, endX: 5400, startY: 210, endY: 185),  // Final summit push
  ];

  // Shrines (Quiz Checkpoints)
  final List<double> shrines = [1000, 2000, 3000, 4000, 5000];
  final Set<int> clearedShrines = {};

  // Mist Crystals
  final List<Offset> mistCrystals = [];
  final Set<int> collectedCrystals = {};
  double speedBoost = 0;

  // Particles
  final List<SakaParticle> particles = [];

  // Camera & Juice
  double cameraShake = 0;
  double zoomLevel = 1.0;
  
  // Time management
  late Stopwatch _stopwatch;
  double _lastFrameTime = 0;

  late AnimationController _gameLoopController;
  late AnimationController _characterController;

  // Audio
  late AudioPlayer _bgPlayer;
  late AudioPlayer _sfxPlayer;

  @override
  void initState() {
    super.initState();
    _bgPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _bgPlayer.setReleaseMode(ReleaseMode.loop);
    _bgPlayer.play(AssetSource('audio/forest_bg.MP3'), volume: 0.3);
    _stopwatch = Stopwatch()..start();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_updateGame);
    _gameLoopController.repeat();

    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _generateCrystals();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrologue();
    });
  }

  void _generateCrystals() {
    final rand = Random();
    for (int i = 0; i < 30; i++) {
      double x = 300 + rand.nextDouble() * (targetX - 600);
      double y = _getSlopeY(x) - 50 - rand.nextDouble() * 50;
      mistCrystals.add(Offset(x, y));
    }
  }

  double _getSlopeY(double x) {
    for (var seg in segments) {
      if (x >= seg.startX && x <= seg.endX) {
        double t = (x - seg.startX) / (seg.endX - seg.startX);
        return lerpDouble(seg.startY, seg.endY, t)!;
      }
    }
    return groundLevel;
  }

  @override
  void dispose() {
    _bgPlayer.stop();
    _sfxPlayer.stop();
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
    _gameLoopController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  void _updateGame() {
    final double currentTime = _stopwatch.elapsedMilliseconds / 1000.0;
    final double dt = currentTime - _lastFrameTime;
    _lastFrameTime = currentTime;

    if (isQuizActive) return;

    setState(() {
      for (int i = particles.length - 1; i >= 0; i--) {
        particles[i].update(dt);
        if (particles[i].life <= 0) particles.removeAt(i);
      }

      // Trail Logic
      if (speedBoost > 0) {
        playerTrail.add(Offset(playerX, playerY));
        if (playerTrail.length > 8) playerTrail.removeAt(0);
      } else {
        if (playerTrail.isNotEmpty) playerTrail.removeAt(0);
      }

      double currentMoveSpeed = baseMoveSpeed + speedBoost;
      if (isMovingLeft) {
        velocityX = -currentMoveSpeed;
      } else if (isMovingRight) {
        velocityX = currentMoveSpeed;
      } else {
        velocityX = 0;
      }

      playerX += velocityX * dt;
      playerX = playerX.clamp(0, targetX);

      double slopeY = _getSlopeY(playerX);
      if (isJumping) {
        velocityY += gravity;
        playerY += velocityY * dt * 60;

        if (playerY >= slopeY) {
          playerY = slopeY;
          if (velocityY > 10) {
            cameraShake = 8.0;
            landingSquash = (velocityY * 0.0005).clamp(0.0, 0.4);
            _createDustPuff(playerX, playerY);
            HapticFeedback.mediumImpact(); // thump
          }
          velocityY = 0;
          isJumping = false;
        }
      } else {
        playerY = slopeY;
      }

      for (int i = 0; i < mistCrystals.length; i++) {
        if (!collectedCrystals.contains(i)) {
          double dx = playerX - mistCrystals[i].dx;
          double dy = playerY - 30 - mistCrystals[i].dy;
          if (sqrt(dx * dx + dy * dy) < 40) {
            _collectCrystal(i);
          }
        }
      }

      if (cameraShake > 0) cameraShake *= 0.9;
      
      double summitProgress = (playerX - 4500) / 900;
      if (summitProgress > 0) {
        zoomLevel = 1.0 - (summitProgress.clamp(0.0, 1.0) * 0.2);
      }

      for (int i = 0; i < shrines.length; i++) {
        if (!clearedShrines.contains(i) && (playerX - shrines[i]).abs() < 15) {
          _triggerQuiz(i);
          break;
        }
      }

      int newStage = (playerX / (targetX / 5)).floor() + 1;
      if (newStage > 5) newStage = 5;
      if (newStage != currentStage) {
        currentStage = newStage;
        _triggerTransition(newStage == 5 ? Colors.white : Colors.black);
      }

      if (playerX >= targetX && !isQuizActive && !isVictorySequence) {
        _triggerVictorySequence();
      }

      if (isVictorySequence) {
        victoryTimer += dt;
        zoomLevel = lerpDouble(zoomLevel, 0.5, dt * 0.5)!;
        if (victoryTimer > 4.0) {
          _showWinScreen();
          isVictorySequence = false;
        }
      }

      if (speedBoost > 0) speedBoost -= 50 * dt;
      if (speedBoost < 0) speedBoost = 0;

      if (landingSquash > 0) landingSquash -= 2 * dt;
      if (landingSquash < 0) landingSquash = 0;

      if (mistTransition > 0) mistTransition -= dt;
      if (mistTransition < 0) mistTransition = 0;

      _updateEnvParticles(dt);

      // Echoes of the Elders Logic
      _updateLore(dt);
    });
  }

  void _updateLore(double dt) {
    bool isNearWaterfall = (playerX - 1500).abs() < 100;
    bool isNearTree = (playerX - 2800).abs() < 100;
    bool isNearTotem = (playerX - 3500).abs() < 100;
    
    bool isNearShrine = false;
    int nearestShrine = -1;
    for (int i = 0; i < shrines.length; i++) {
      if ((playerX - shrines[i]).abs() < 100) {
        isNearShrine = true;
        nearestShrine = i;
        break;
      }
    }

    if (velocityX == 0 && (isNearWaterfall || isNearTree || isNearTotem || isNearShrine)) {
      standingStillTime += dt;
      if (standingStillTime > 2.0) {
        if (isNearWaterfall) {
          currentLore = "The daliyog's song is the memory of our first breath. It washes the dust of the world from the spirit.";
        } else if (isNearTree) {
          currentLore = "The diwata sleep in the roots of the daku. To pass is to be judged by the silence of the forest.";
        } else if (isNearTotem) {
          currentLore = "The ancestors carved their names in the stone. They watch your ascent, Baylan.";
        } else if (isNearShrine) {
          currentLore = _getShrineLore(nearestShrine);
        }
      }
    } else {
      standingStillTime = 0;
      currentLore = null;
    }
  }

  String _getShrineLore(int index) {
    switch (index) {
      case 0: return "The first step is always the heaviest. Remember your roots.";
      case 1: return "The mountain provides, but it also tests. Patience is your shield.";
      case 2: return "The clouds gather below you. The world is small from here.";
      case 3: return "The air grows thin, but the spirit grows strong.";
      case 4: return "The summit is near. The ancestors await your arrival.";
      default: return "Echoes of the elders whisper in the wind.";
    }
  }

  void _triggerTransition(Color color) {
    setState(() {
      mistTransition = 1.0;
      transitionColor = color;
      transitionOpacity = 1.0;
    });
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          transitionOpacity = 0.0;
        });
      }
    });
  }

  void _triggerVictorySequence() async {
    setState(() {
      isVictorySequence = true;
      victoryTimer = 0;
    });
    _bgPlayer.stop();
    _sfxPlayer.play(AssetSource('audio/success_1.MP3'), volume: 1.0);
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.vibrate();
  }

  void _updateEnvParticles(double dt) {
    final rand = Random();
    // Spawn particles based on stage
    if (currentStage == 3 && envParticles.length < 20) {
      // Falling Leaves
      envParticles.add(SakaEnvParticle(
        x: rand.nextDouble() * 1000 - 200, // Relative to screen
        y: -20,
        vx: (rand.nextDouble() - 0.5) * 50,
        vy: 40 + rand.nextDouble() * 30,
        type: SakaEnvType.leaf,
        life: 5.0,
      ));
    } else if (currentStage == 5 && envParticles.length < 50) {
      // Snow/Glow flakes
      envParticles.add(SakaEnvParticle(
        x: rand.nextDouble() * 1000,
        y: rand.nextDouble() * 800,
        vx: -100 - rand.nextDouble() * 100, // Wind blowing left
        vy: 20 + rand.nextDouble() * 20,
        type: SakaEnvType.snow,
        life: 3.0,
      ));
    }

    for (int i = envParticles.length - 1; i >= 0; i--) {
      envParticles[i].update(dt);
      if (envParticles[i].life <= 0) envParticles.removeAt(i);
    }
  }

  void _collectCrystal(int index) {
    collectedCrystals.add(index);
    score += 10;
    speedBoost = 150.0;
    HapticFeedback.lightImpact();
    _sfxPlayer.play(AssetSource('audio/success.MP3'), volume: 0.8);
    _createBurst(mistCrystals[index].dx, mistCrystals[index].dy, Colors.cyanAccent, 5);
  }

  void _createBurst(double x, double y, Color color, int count) {
    final rand = Random();
    for (int i = 0; i < count; i++) {
      particles.add(SakaParticle(
        x: x, y: y,
        vx: (rand.nextDouble() - 0.5) * 400,
        vy: (rand.nextDouble() - 0.5) * 400,
        color: color, life: 1.0,
      ));
    }
  }

  void _createDustPuff(double x, double y) {
    final rand = Random();
    for (int i = 0; i < 8; i++) {
      particles.add(SakaParticle(
        x: x,
        y: y,
        vx: (rand.nextDouble() - 0.5) * 150,
        vy: -rand.nextDouble() * 80,
        color: Colors.white70.withValues(alpha: 0.5),
        life: 0.4 + rand.nextDouble() * 0.4,
      ));
    }
  }

  void _triggerQuiz(int index) {
    setState(() {
      isQuizActive = true;
      velocityX = 0;
      isMovingLeft = false;
      isMovingRight = false;
    });

    final questions = _allQuestions[index + 1] ?? _allQuestions[1]!;
    final question = questions[Random().nextInt(questions.length)];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SakaQuizPanel(
        question: question,
        onSuccess: () async {
          _createBurst(playerX, playerY - 30, AppColors.gold500, 30);
          setState(() {
            clearedShrines.add(index);
            isQuizActive = false;
            score += 100;
          });
          
          // Update Tribal Challenges progress
          ref.read(questActionProvider.notifier).updateProgress(QuestType.flashcard, 1);

          Navigator.pop(context);
          
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 150));
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 150));
          HapticFeedback.heavyImpact();
        },
      ),
    );
  }

  void _showPrologue() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SakaIntroScreen(
        onStart: () {
          Navigator.pop(context);
          _triggerTransition(Colors.black);
        },
      ),
    );
  }

  void _showWinScreen() {
    _gameLoopController.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SakaWinScreen(
        onClose: () {
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _getStageColors(currentStage),
              ),
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(
              painter: SakaPainter(
                playerX: playerX,
                playerY: playerY,
                velocityX: velocityX,
                velocityY: velocityY,
                isJumping: isJumping,
                currentStage: currentStage,
                shrines: shrines,
                clearedShrines: clearedShrines,
                animValue: _characterController.value,
                particles: particles,
                mistCrystals: mistCrystals,
                collectedCrystals: collectedCrystals,
                cameraShake: cameraShake,
                zoomLevel: zoomLevel,
                segments: segments,
                playerTrail: playerTrail,
                landingSquash: landingSquash,
                mistTransition: mistTransition,
                envParticles: envParticles,
                isVictory: isVictorySequence,
                speedBoost: speedBoost,
              ),
              size: Size.infinite,
            ),
          ),
          if (currentLore != null)
            Positioned(
              left: 0, right: 0,
              bottom: 250,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentLore!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppColors.gold500.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildTopHUD(),
                  const Spacer(),
                  _buildNarrativeOverlay(),
                  const SizedBox(height: 20),
                  _buildControls(),
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: transitionOpacity,
              duration: const Duration(milliseconds: 400),
              child: Container(color: transitionColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getStageColors(int stage) {
    switch (stage) {
      case 1: return [const Color(0xFF0D0B21), const Color(0xFF1A1A2E)]; // Dawn/Night
      case 2: return [const Color(0xFF1A1A2E), const Color(0xFF2C3E50)]; // Deep Blue
      case 3: return [const Color(0xFF2C3E50), const Color(0xFFE67E22).withValues(alpha: 0.4)]; // Morning Glow
      case 4: return [const Color(0xFFE67E22), const Color(0xFFF39C12)]; // Sunrise
      case 5: return [const Color(0xFFF39C12), const Color(0xFFF1C40F)]; // Golden Summit
      default: return [Colors.black, Colors.blueGrey];
    }
  }

  Widget _buildTopHUD() {
    int distance = (targetX - playerX).toInt();
    int distanceKey = (distance / 100).floor(); // Animate every 100m
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SCORE: ${score.toInt()}', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
              .animate(key: ValueKey(score.toInt()))
              .scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0), duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 4),
            Text('DISTANCE: ${distance > 0 ? distance : 0}m', style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2))
              .animate(key: ValueKey(distanceKey))
              .scale(begin: const Offset(1.2, 1.2), end: const Offset(1.0, 1.0), duration: 200.ms, curve: Curves.easeOut),
            const SizedBox(height: 8),
            _buildProgressBar(),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: _showGlossary,
              icon: const Icon(Icons.book, color: AppColors.gold500),
              tooltip: 'Glossary',
            ),
            IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close, color: Colors.white)),
          ],
        ),
      ],
    );
  }

  void _showGlossary() {
    showDialog(
      context: context,
      builder: (context) => SakaGlossaryPanel(clearedShrines: clearedShrines),
    );
  }

  Widget _buildProgressBar() {
    double progress = playerX / targetX;
    return Container(
      width: 200, height: 12,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Icon(Icons.terrain, size: 10, color: Colors.white54),
            const Icon(Icons.wb_sunny, size: 10, color: Color(0xFFFFC200)),
          ]),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gold500,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: AppColors.gold500.withValues(alpha: 0.5), blurRadius: 4)],
                      ),
                    ),
                  ),
                  Positioned(left: (200 * value) - 8, top: -6, child: const Icon(Icons.person, size: 20, color: Colors.white)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeOverlay() {
    final stageInfo = _getStageInfo(currentStage);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Column(
        children: [
          Text(stageInfo.mansaka, textAlign: TextAlign.center, style: GoogleFonts.nunito(color: AppColors.gold500, fontSize: 15, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)).animate(key: ValueKey(currentStage)).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 4),
          Text(stageInfo.english, textAlign: TextAlign.center, style: GoogleFonts.nunito(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          _controlButton(icon: Icons.arrow_back_ios_new, onTapDown: (_) => setState(() => isMovingLeft = true), onTapUp: (_) => setState(() => isMovingLeft = false)),
          const SizedBox(width: 20),
          _controlButton(icon: Icons.arrow_forward_ios, onTapDown: (_) => setState(() => isMovingRight = true), onTapUp: (_) => setState(() => isMovingRight = false)),
        ]),
        _controlButton(icon: Icons.expand_less, onTapDown: (_) { if (!isJumping) setState(() { isJumping = true; velocityY = jumpForce / 60; }); }, onTapUp: (_) { if (isJumping && velocityY < 0) setState(() => velocityY *= 0.4); }),
      ],
    );
  }

  Widget _controlButton({required IconData icon, required Function(TapDownDetails) onTapDown, required Function(TapUpDetails) onTapUp}) {
    return GestureDetector(
      onTapDown: onTapDown, onTapUp: onTapUp,
      onTapCancel: () => onTapUp(TapUpDetails(kind: PointerDeviceKind.touch)),
      child: Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Icon(icon, color: Colors.white, size: 30)),
    );
  }

  SakaStageInfo _getStageInfo(int stage) {
    final stageFallbacks = {
      1: SakaStageInfo(mansaka: "Palakawon pa yagwakat da, minang pyagabalibali ing daliyog.", english: "Dawn yet already awaken—rattan-working diligently."),
      2: SakaStageInfo(mansaka: "Manubong sang baboy aw manok, magabalin sang carabao.", english: "Feed the pig and chicken, pasture the carabao."),
      3: SakaStageInfo(mansaka: "Managkas sang bula sang kagulangan aw maglakar sa mga abot.", english: "Get rattan from the timberland and load it for goods."),
      4: SakaStageInfo(mansaka: "Ing mangayso dag bukid tig akbas, maglabon nang tangsangawlaw.", english: "A child goes to the mountain farm to weed grasses."),
      5: SakaStageInfo(mansaka: "Ampan way kyakatagtagaan nang taga mambukid tungod sang kalayo nang banwa.", english: "Far from the town—yet the mountain people carry ancient wisdom."),
    };
    if (playerX > 1400 && playerX < 1600) return SakaStageInfo(mansaka: "Bagus nang daliyog, dumaan sang gubatan.", english: "The waterfall speaks of ancestors' breath—refreshing the soul.");
    if (playerX > 2700 && playerX < 2900) return SakaStageInfo(mansaka: "Balete na daku, tagoanan nang diwata.", english: "The Great Balete watches; its roots are the veins of the earth.");
    return stageFallbacks[stage] ?? SakaStageInfo(mansaka: "", english: "");
  }

  static const Map<int, List<SakaQuestion>> _allQuestions = {
    1: [
      SakaQuestion(text: "What does 'Yagwakat' mean?", options: ["Dawn", "Sunset", "Forest", "Mountain"], correctIndex: 0),
      SakaQuestion(text: "Which material is used for Mansaka weaving?", options: ["Rattan", "Silk", "Plastic", "Wool"], correctIndex: 0),
      SakaQuestion(text: "What time does the 'Yagwakat' occur?", options: ["Morning", "Afternoon", "Evening", "Night"], correctIndex: 0),
      SakaQuestion(text: "What is 'Daliyog'?", options: ["Waterfall", "River", "Lake", "Ocean"], correctIndex: 0),
    ],
    2: [
      SakaQuestion(text: "Which animal is commonly pastured in the farm?", options: ["Carabao", "Lion", "Elephant", "Tiger"], correctIndex: 0),
      SakaQuestion(text: "What is 'Uma'?", options: ["Farm", "Sea", "Cloud", "Sky"], correctIndex: 0),
      SakaQuestion(text: "Who feeds the pig and chicken?", options: ["Farmers", "Fishermen", "Hunters", "Warriors"], correctIndex: 0),
      SakaQuestion(text: "What is the primary role of a 'Carabao'?", options: ["Farming", "Racing", "Hunting", "Guarding"], correctIndex: 0),
    ],
    3: [
      SakaQuestion(text: "Where is rattan primarily collected?", options: ["Timberland", "Desert", "Ocean", "Village"], correctIndex: 0),
      SakaQuestion(text: "What is the Mansaka word for Forest?", options: ["Kagulangan", "Banwa", "Bukid", "Uma"], correctIndex: 0),
      SakaQuestion(text: "What is the purpose of gathering rattan?", options: ["Goods/Trade", "Cooking", "Weapons", "Clothing"], correctIndex: 0),
      SakaQuestion(text: "Which word means 'Get' or 'Gather' in Mansaka?", options: ["Managkas", "Maglakar", "Manubong", "Magabalin"], correctIndex: 0),
    ],
    4: [
      SakaQuestion(text: "Why does a child go to the mountain farm?", options: ["Weed grasses", "Play games", "Sleep", "Swim"], correctIndex: 0),
      SakaQuestion(text: "What is 'Bukid'?", options: ["Mountain", "River", "Valley", "Path"], correctIndex: 0),
      SakaQuestion(text: "What does 'Maglabon' mean?", options: ["To weed", "To plant", "To harvest", "To water"], correctIndex: 0),
      SakaQuestion(text: "Who is 'Mangayso'?", options: ["Child", "Elder", "Warrior", "Healer"], correctIndex: 0),
    ],
    5: [
      SakaQuestion(text: "What is carried by mountain people far from town?", options: ["Ancient wisdom", "Modern tech", "Nothing", "Gold only"], correctIndex: 0),
      SakaQuestion(text: "What does 'Kalibutan' represent?", options: ["The World", "A house", "A tool", "A fruit"], correctIndex: 0),
      SakaQuestion(text: "What is 'Banwa'?", options: ["Town/Village", "Mountain", "Forest", "Sea"], correctIndex: 0),
      SakaQuestion(text: "Who are the 'taga mambukid'?", options: ["Mountain people", "City dwellers", "Fishermen", "Traders"], correctIndex: 0),
    ],
  };
}


class SakaQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;
  const SakaQuestion({required this.text, required this.options, required this.correctIndex});
}

class SakaStageInfo {
  final String mansaka, english;
  SakaStageInfo({required this.mansaka, required this.english});
}



class SakaIntroScreen extends StatelessWidget {
  final VoidCallback onStart;
  const SakaIntroScreen({super.key, required this.onStart});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: const Color(0xFF0D0B21), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PROLOGUE: THE AWAKENING', style: GoogleFonts.fredoka(color: AppColors.gold500, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("\"The stars are still sharp over Davao de Oro when young Baylan stirs. The air in the valley is thick with the scent of damp earth and woodsmoke. For the Mansaka, the mountain is not just land—it is a living ancestor.\n\nTo reach the summit of Mount Hamiguitan is to retrace the steps of the elders. Every vine cut, every seed planted, and every word spoken is a thread in the poem of our people.\n\nRise, Baylan. The climb begins before the sun.\"", style: GoogleFonts.nunito(color: Colors.white, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: onStart, style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('BEGIN CLIMB', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}

class SakaQuizPanel extends StatefulWidget {
  final SakaQuestion question;
  final VoidCallback onSuccess;
  const SakaQuizPanel({super.key, required this.question, required this.onSuccess});
  @override
  State<SakaQuizPanel> createState() => _SakaQuizPanelState();
}

class _SakaQuizPanelState extends State<SakaQuizPanel> {
  int selectedOption = -1;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF3E2723),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF5D4037), width: 8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 10)), const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(4, 4), spreadRadius: -5)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.architecture, color: Color(0xFFD7CCC8), size: 16),
              const SizedBox(width: 8),
              Text('SHRINE REFLECTION', style: GoogleFonts.fredoka(color: const Color(0xFFD7CCC8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(width: 8),
              const Icon(Icons.architecture, color: Color(0xFFD7CCC8), size: 16),
            ]),
            const Divider(color: Color(0xFF5D4037), height: 32, thickness: 2),
            Text(widget.question.text, textAlign: TextAlign.center, style: GoogleFonts.nunito(color: const Color(0xFFEFEBE9), fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)),
            const SizedBox(height: 24),
            ...List.generate(widget.question.options.length, (index) => _optionTile(index)),
            const SizedBox(height: 24),
            if (selectedOption != -1)
              ElevatedButton(
                onPressed: () {
                  if (selectedOption == widget.question.correctIndex) {
                    widget.onSuccess();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: const Color(0xFF5D4037), content: Text('Try again, reflect on the words of the elders.', style: GoogleFonts.nunito(color: Colors.white))));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500, foregroundColor: Colors.black, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), shape: const RoundedRectangleBorder()),
                child: Text('SUBMIT', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _optionTile(int index) {
    bool isSelected = selectedOption == index;
    return GestureDetector(
      onTap: () => setState(() => selectedOption = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF5D4037) : const Color(0xFF4E342E), border: Border.all(color: isSelected ? AppColors.gold500 : Colors.white10, width: 2), boxShadow: isSelected ? [BoxShadow(color: AppColors.gold500.withValues(alpha: 0.2), blurRadius: 8)] : null),
        child: Row(children: [
          Icon(isSelected ? Icons.circle : Icons.circle_outlined, color: isSelected ? AppColors.gold500 : Colors.white24, size: 16),
          const SizedBox(width: 16),
          Text(widget.question.options[index], style: GoogleFonts.nunito(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}


class SakaWinScreen extends StatelessWidget {
  final VoidCallback onClose;
  const SakaWinScreen({super.key, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: const Color(0xFF14241A), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.gold500)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: AppColors.gold500, size: 60).animate().scale().shimmer(),
            const SizedBox(height: 20),
            Text('NAABOT ANG TUKTOK!', style: GoogleFonts.fredoka(color: AppColors.gold500, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('THE SUMMIT IS REACHED', style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 20),
            Text("You stand where the earth meets the sky. You have carried the poem of the Mansaka from the forest floor to the sacred height. The words you learned are not just vocabulary—they are the breath of the mountain.\n\nYou are Man-saka. You are the one who climbs.", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: Colors.white, fontSize: 14, height: 1.5)),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: onClose, style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), child: const Text('CONTINUE JOURNEY')),
          ],
        ),
      ),
    );
  }
}

class SakaGlossaryPanel extends StatelessWidget {
  final Set<int> clearedShrines;
  const SakaGlossaryPanel({super.key, required this.clearedShrines});

  static const Map<String, String> words = {
    "Yagwakat": "Dawn",
    "Daliyog": "Waterfall",
    "Uma": "Farm",
    "Kagulangan": "Forest",
    "Bukid": "Mountain",
    "Kalibutan": "The World/Universe",
    "Diwata": "Nature Spirits",
    "Daku": "Big/Great (often referring to the Balete tree)",
  };

  @override
  Widget build(BuildContext context) {
    final collected = words.entries.toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold500.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('MANSAKA GLOSSARY', style: GoogleFonts.fredoka(color: AppColors.gold500, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: collected.length,
                itemBuilder: (context, index) {
                  final word = collected[index];
                  // Determine if unlocked - for now let's show all or base it on shrines
                  // To keep it simple, we show all learned words
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(word.key, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(word.value, style: GoogleFonts.nunito(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: AppColors.gold500))),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class SakaGameScreen extends StatefulWidget {
  const SakaGameScreen({super.key});

  @override
  State<SakaGameScreen> createState() => _SakaGameScreenState();
}

class _SakaGameScreenState extends State<SakaGameScreen> with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
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
            _createDustPuff(playerX, playerY);
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

      if (playerX >= targetX && !isQuizActive) {
        _showWinScreen();
      }

      if (speedBoost > 0) speedBoost -= 50 * dt;
      if (speedBoost < 0) speedBoost = 0;

      // Echoes of the Elders Logic
      _updateLore(dt);
    });
  }

  void _updateLore(double dt) {
    bool isNearWaterfall = (playerX - 1500).abs() < 100;
    bool isNearTree = (playerX - 2800).abs() < 100;

    if (velocityX == 0 && (isNearWaterfall || isNearTree)) {
      standingStillTime += dt;
      if (standingStillTime > 2.0) {
        currentLore = isNearWaterfall 
          ? "The daliyog's song is the memory of our first breath. It washes the dust of the world from the spirit."
          : "The diwata sleep in the roots of the daku. To pass is to be judged by the silence of the forest.";
      }
    } else {
      standingStillTime = 0;
      currentLore = null;
    }
  }

  void _triggerTransition(Color color) {
    setState(() {
      transitionColor = color;
      transitionOpacity = 1.0;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => transitionOpacity = 0.0);
      }
    });
  }

  void _collectCrystal(int index) {
    collectedCrystals.add(index);
    score += 10;
    speedBoost = 150.0;
    HapticFeedback.lightImpact();
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
        onSuccess: () {
          _createBurst(playerX, playerY - 30, AppColors.gold500, 30);
          setState(() {
            clearedShrines.add(index);
            isQuizActive = false;
            score += 100;
          });
          Navigator.pop(context);
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SCORE: ${score.toInt()}', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('DISTANCE TO SUMMIT', style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
        _controlButton(icon: Icons.expand_less, onTapDown: (_) { if (!isJumping) setState(() { isJumping = true; velocityY = jumpForce / 60; }); }, onTapUp: (_) {}),
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
    ],
    2: [
      SakaQuestion(text: "Which animal is commonly pastured in the farm?", options: ["Carabao", "Lion", "Elephant", "Tiger"], correctIndex: 0),
      SakaQuestion(text: "What is 'Uma'?", options: ["Farm", "Sea", "Cloud", "Sky"], correctIndex: 0),
    ],
    3: [
      SakaQuestion(text: "Where is rattan primarily collected?", options: ["Timberland", "Desert", "Ocean", "Village"], correctIndex: 0),
      SakaQuestion(text: "What is the Mansaka word for Forest?", options: ["Kagulangan", "Banwa", "Bukid", "Uma"], correctIndex: 0),
    ],
    4: [
      SakaQuestion(text: "Why does a child go to the mountain farm?", options: ["Weed grasses", "Play games", "Sleep", "Swim"], correctIndex: 0),
      SakaQuestion(text: "What is 'Bukid'?", options: ["Mountain", "River", "Valley", "Path"], correctIndex: 0),
    ],
    5: [
      SakaQuestion(text: "What is carried by mountain people far from town?", options: ["Ancient wisdom", "Modern tech", "Nothing", "Gold only"], correctIndex: 0),
      SakaQuestion(text: "What does 'Kalibutan' represent?", options: ["The World", "A house", "A tool", "A fruit"], correctIndex: 0),
    ],
  };
}

class SakaSegment {
  final double startX, endX, startY, endY;
  SakaSegment({required this.startX, required this.endX, required this.startY, required this.endY});
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

class SakaParticle {
  double x, y, vx, vy, life;
  Color color;
  SakaParticle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.life});
  void update(double dt) { x += vx * dt; y += vy * dt; vy += 500 * dt; life -= dt; }
}

class SakaPainter extends CustomPainter {
  final double playerX, playerY, velocityX, animValue, cameraShake, zoomLevel;
  final bool isJumping;
  final int currentStage;
  final List<double> shrines;
  final Set<int> clearedShrines;
  final List<SakaParticle> particles;
  final List<Offset> mistCrystals;
  final Set<int> collectedCrystals;
  final List<SakaSegment> segments;
  final List<Offset> playerTrail;

  SakaPainter({
    required this.playerX, required this.playerY, required this.velocityX, required this.isJumping,
    required this.currentStage, required this.shrines, required this.clearedShrines,
    required this.animValue, required this.particles, required this.mistCrystals,
    required this.collectedCrystals, required this.cameraShake, required this.zoomLevel,
    required this.segments, required this.playerTrail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double cameraX = playerX - (size.width / 3);
    if (cameraX < 0) cameraX = 0;
    canvas.save();
    if (cameraShake > 0) {
      final rand = Random();
      canvas.translate((rand.nextDouble() - 0.5) * cameraShake, (rand.nextDouble() - 0.5) * cameraShake);
    }

    _drawCelestialBodies(canvas, size);

    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoomLevel);
    canvas.translate(-size.width / 2, -size.height / 2);
    _drawParallaxLayer(canvas, size, cameraX, 0.1, const Color(0xFF080712), 150);
    _drawParallaxLayer(canvas, size, cameraX, 0.3, const Color(0xFF0F1424), 100);
    _drawParallaxLayer(canvas, size, cameraX, 0.5, const Color(0xFF141B2D), 50);
    if (currentStage == 3) _drawMist(canvas, size, true);
    _drawOrganicGround(canvas, size, cameraX);
    _drawLandmarks(canvas, size, cameraX);
    _drawMistCrystals(canvas, cameraX, size);
    for (int i = 0; i < shrines.length; i++) {
      double sx = shrines[i] - cameraX;
      if (sx > -200 && sx < size.width + 200) _drawShrine(canvas, sx, clearedShrines.contains(i), shrines[i], size);
    }
    _drawSpeedTrail(canvas, cameraX, size);
    _drawParticles(canvas, cameraX, size);
    if (currentStage == 1) _drawFireflies(canvas, size);
    if (currentStage == 4) _drawWind(canvas, size);
    if (currentStage == 5) _drawSummitGlow(canvas, size);
    _drawPlayer(canvas, size, cameraX);
    _drawVignette(canvas, size);
    _drawSunFlare(canvas, size);
    canvas.restore();
  }

  void _drawSpeedTrail(Canvas canvas, double cameraX, Size size) {
    if (playerTrail.isEmpty) return;
    double visualOffset = size.height - 348;
    for (int i = 0; i < playerTrail.length; i++) {
      double alpha = (i / playerTrail.length) * 0.2;
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
      double tx = playerTrail[i].dx - cameraX;
      double ty = playerTrail[i].dy + visualOffset;
      
      canvas.drawCircle(Offset(tx, ty - 35), 8, paint);
      canvas.drawRect(Rect.fromLTWH(tx - 6, ty - 27, 12, 18), paint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    double intensity = 0;
    if (currentStage == 2) intensity = 0.2;
    if (currentStage == 3) intensity = 0.4;
    if (intensity == 0) return;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: intensity)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawSunFlare(Canvas canvas, Size size) {
    if (currentStage != 5) return;
    double progress = (playerX / 5400).clamp(0.0, 1.0);
    double sunAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    double sunY = size.height * 0.7 - (sunAlpha * size.height * 0.6);
    Offset sunPos = Offset(size.width * 0.8, sunY);
    
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(sunPos, 150, paint);
    
    // Lens flare elements
    for (int i = 0; i < 3; i++) {
      double dist = 100.0 * (i + 1);
      canvas.drawCircle(
        Offset(sunPos.dx - dist * 0.5, sunPos.dy + dist * 0.5), 
        30 - (i * 5), 
        Paint()..color = Colors.orangeAccent.withValues(alpha: 0.03)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      );
    }
  }

  void _drawParallaxLayer(Canvas canvas, Size size, double cameraX, double speed, Color color, double heightOffset) {
    final paint = Paint()..color = color;
    final path = Path();
    double offset = -(cameraX * speed) % 800;
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width + 800; x += 100) {
      double dx = x + offset;
      double h = (sin(x / 200) * 40) + heightOffset + (size.height * 0.4);
      path.lineTo(dx, size.height - h);
    }
    path.lineTo(size.width + 800, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawOrganicGround(Canvas canvas, Size size, double cameraX) {
    final groundPaint = Paint()..color = const Color(0xFF1B2E1D);
    final grassPaint = Paint()..color = const Color(0xFF2D4F3C)..strokeWidth = 2;
    final path = Path();
    double visualOffset = size.height - 348;
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 5) {
      double worldX = x + cameraX;
      double baseSlopeY = _getSlopeY(worldX);
      double noise = sin(worldX * 0.05) * 3 + cos(worldX * 0.02) * 2;
      path.lineTo(x, baseSlopeY + visualOffset + noise);

      // Interactive & Swaying Grass
      if (Random(worldX.toInt()).nextDouble() > 0.96) {
        double distToPlayer = (worldX - playerX).abs();
        double tilt = sin(worldX * 0.1 + animValue * pi * 2) * 4;
        if (distToPlayer < 40) {
          double push = (40 - distToPlayer) / 40 * 15;
          tilt += (worldX > playerX) ? push : -push;
        }
        canvas.drawLine(
          Offset(x, baseSlopeY + visualOffset + noise),
          Offset(x + tilt, baseSlopeY + visualOffset + noise - 12),
          grassPaint,
        );
      }
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, groundPaint);
  }

  double _getSlopeY(double x) {
    for (var seg in segments) {
      if (x >= seg.startX && x <= seg.endX) {
        double t = (x - seg.startX) / (seg.endX - seg.startX);
        return lerpDouble(seg.startY, seg.endY, t)!;
      }
    }
    return 348;
  }

  void _drawMistCrystals(Canvas canvas, double cameraX, Size size) {
    final paint = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.8);
    final glow = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    double visualOffset = size.height - 348;
    for (int i = 0; i < mistCrystals.length; i++) {
      if (collectedCrystals.contains(i)) continue;
      double dx = mistCrystals[i].dx - cameraX;
      if (dx < -50 || dx > size.width + 50) continue;
      double hover = sin(animValue * pi * 2 + i) * 5;
      Offset pos = Offset(dx, mistCrystals[i].dy + visualOffset + hover);
      canvas.drawCircle(pos, 8, glow); canvas.drawCircle(pos, 4, paint);
    }
  }

  void _drawParticles(Canvas canvas, double cameraX, Size size) {
    final paint = Paint();
    double visualOffset = size.height - 348;
    for (var p in particles) {
      double dx = p.x - cameraX;
      if (dx < -10 || dx > size.width + 10) continue;
      paint.color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, p.y + visualOffset), 3 * p.life, paint);
    }
  }

  void _drawLandmarks(Canvas canvas, Size size, double cameraX) {
    double visualOffset = size.height - 348;
    if (cameraX < 2000 && cameraX + size.width > 1200) {
      double x = 1500 - cameraX;
      double y = _getSlopeY(1500) + visualOffset;
      _drawWaterfall(canvas, x, y);
    }
    if (cameraX < 3500 && cameraX + size.width > 2500) {
      double x = 2800 - cameraX;
      double y = _getSlopeY(2800) + visualOffset;
      _drawBaleteTree(canvas, x, y);
    }
  }

  void _drawWaterfall(Canvas canvas, double x, double y) {
    final paint = Paint()..color = Colors.lightBlueAccent.withValues(alpha: 0.4);
    final streamPaint = Paint()..color = Colors.white.withValues(alpha: 0.3)..strokeWidth = 2;
    final mistPaint = Paint()..color = Colors.white.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawRect(Rect.fromLTWH(x - 30, y, 60, 400), paint);
    
    // Animated streams
    for (int i = 0; i < 3; i++) {
      double sx = x - 20 + (i * 20);
      double offset = (animValue * 400 + i * 130) % 400;
      canvas.drawLine(Offset(sx, y + offset), Offset(sx, y + offset + 30), streamPaint);
    }

    // Mist at bottom
    for (int i = 0; i < 5; i++) {
      double mx = x - 30 + (i * 15) + sin(animValue * pi * 2 + i) * 5;
      double my = y + 380 + cos(animValue * pi + i) * 5;
      canvas.drawCircle(Offset(mx, my), 20, mistPaint);
    }
  }

  void _drawBaleteTree(Canvas canvas, double x, double y) {
    final trunkPaint = Paint()..color = const Color(0xFF2A1A0A);
    final leafPaint = Paint()..color = const Color(0xFF14241A);
    canvas.drawRect(Rect.fromLTWH(x - 20, y - 150, 40, 150), trunkPaint);
    canvas.drawCircle(Offset(x, y - 180), 80, leafPaint);

    // Birds flying away when approached
    double treeWorldX = 2800;
    double dist = (playerX - treeWorldX).abs();
    if (dist < 400) {
      double t = (400 - dist) / 400; 
      final birdPaint = Paint()..color = Colors.black.withValues(alpha: (1.0 - t).clamp(0.2, 0.8))..style = PaintingStyle.stroke..strokeWidth = 1.2;
      for (int i = 0; i < 4; i++) {
        double bx = x + (i * 40) - (t * 500);
        double by = y - 200 - (t * 300) + sin(animValue * pi * 10 + i) * 15;
        Path birdPath = Path();
        birdPath.moveTo(bx - 6, by);
        birdPath.quadraticBezierTo(bx, by - 6, bx + 6, by);
        canvas.drawPath(birdPath, birdPaint);
      }
    }
  }

  void _drawShrine(Canvas canvas, double x, bool cleared, double worldX, Size size) {
    final paint = Paint()..color = cleared ? AppColors.gold500 : Colors.blueGrey;
    double visualOffset = size.height - 348;
    double y = _getSlopeY(worldX) + visualOffset;
    canvas.drawRect(Rect.fromLTWH(x - 25, y - 50, 50, 50), paint);
    if (cleared) {
      double hover = sin(animValue * pi * 2) * 5;
      canvas.drawCircle(Offset(x, y - 70 + hover), 8, paint..color = Colors.white);
    }
  }

  void _drawPlayer(Canvas canvas, Size size, double cameraX) {
    double drawX = playerX - cameraX;
    double drawY = playerY + (size.height - 348);
    final paint = Paint()..color = Colors.white;

    // Dynamic Scarf/Cape
    final scarfPaint = Paint()
      ..color = AppColors.gold500
      ..style = PaintingStyle.fill;
    
    final scarfPath = Path();
    double neckX = drawX;
    double neckY = drawY - 27;
    
    // Wind & Movement Physics for Scarf
    double windFactor = (currentStage == 4) ? -25 : 0;
    double moveFactor = -velocityX * 0.15;
    double sway = sin(animValue * pi * 4) * 4;
    
    scarfPath.moveTo(neckX, neckY);
    // Control point for the curve
    double cpX = neckX + moveFactor + windFactor;
    double cpY = neckY + sway;
    // End point of the scarf
    double endX = neckX + (moveFactor * 1.8) + (windFactor * 1.5);
    double endY = neckY + 12 + sway;

    scarfPath.quadraticBezierTo(cpX, cpY, endX, endY);
    scarfPath.lineTo(endX, endY + 8);
    scarfPath.quadraticBezierTo(cpX, cpY + 5, neckX, neckY + 5);
    scarfPath.close();
    
    canvas.drawPath(scarfPath, scarfPaint);

    // Character Head and Body
    canvas.drawCircle(Offset(drawX, drawY - 35), 8, paint);
    canvas.drawRect(Rect.fromLTWH(drawX - 6, drawY - 27, 12, 18), paint);
  }

  void _drawFireflies(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..color = Colors.greenAccent.withValues(alpha: 0.4);
    for (int i = 0; i < 30; i++) {
      double x = (random.nextDouble() * size.width + animValue * 100) % size.width;
      double y = (random.nextDouble() * size.height + sin(animValue * pi * 2 + i) * 20) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  void _drawMist(Canvas canvas, Size size, bool back) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    for (int i = 0; i < 3; i++) {
      double xOffset = (animValue * size.width * 0.5 + i * 200) % size.width;
      canvas.drawOval(Rect.fromLTWH(xOffset - 200, size.height * 0.3 + i * 100, size.width * 0.8, 150), paint);
    }
  }

  void _drawWind(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 1;
    final rand = Random(99);
    for (int i = 0; i < 15; i++) {
      double x = (rand.nextDouble() * size.width - animValue * size.width) % size.width;
      double y = rand.nextDouble() * size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 50, y - 5), paint);
    }
  }

  void _drawSummitGlow(Canvas canvas, Size size) {
    final paint = Paint()..shader = RadialGradient(colors: [const Color(0xFFFFC200).withValues(alpha: 0.2), Colors.transparent]).createShader(Rect.fromLTWH(size.width - 200, -100, 400, 400));
    canvas.drawCircle(Offset(size.width - 50, 50), 300 + sin(animValue * pi * 2) * 20, paint);
  }

  void _drawCelestialBodies(Canvas canvas, Size size) {
    double progress = (playerX / 5400).clamp(0.0, 1.0);
    
    // Fading Moon/Stars
    if (progress < 0.6) {
      double alpha = (1.0 - (progress / 0.6)).clamp(0.0, 1.0);
      final moonPaint = Paint()..color = Colors.white.withValues(alpha: alpha * 0.5);
      canvas.drawCircle(Offset(size.width * 0.2, 100 + progress * 150), 25, moonPaint);
    }
    
    // Rising Sun
    if (progress > 0.4) {
      double sunAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      double sunY = size.height * 0.7 - (sunAlpha * size.height * 0.6);
      final sunGlow = Paint()..color = const Color(0xFFFFC200).withValues(alpha: sunAlpha * 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(size.width * 0.8, sunY), 50, sunGlow);
      canvas.drawCircle(Offset(size.width * 0.8, sunY), 25, Paint()..color = Colors.white.withValues(alpha: sunAlpha * 0.8));
    }
  }

  @override
  bool shouldRepaint(covariant SakaPainter oldDelegate) => true;
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

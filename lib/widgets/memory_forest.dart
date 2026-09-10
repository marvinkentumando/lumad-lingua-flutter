import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/srs_models.dart';
import '../theme/app_colors.dart';

class MemoryForest extends StatefulWidget {
  final List<SRSProgress> progress;
  final double height;

  const MemoryForest({
    super.key,
    required this.progress,
    this.height = 300,
  });

  @override
  State<MemoryForest> createState() => _MemoryForestState();
}

class _MemoryForestState extends State<MemoryForest> with SingleTickerProviderStateMixin {
  late AnimationController _windController;

  @override
  void initState() {
    super.initState();
    _windController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _windController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _windController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: ForestPainter(
            progress: widget.progress,
            windProgress: _windController.value,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        );
      },
    );
  }
}

class ForestPainter extends CustomPainter {
  final List<SRSProgress> progress;
  final double windProgress;
  final bool isDark;

  ForestPainter({
    required this.progress,
    required this.windProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // 1. Draw Ground
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        isDark ? AppColors.forest800 : AppColors.forest500.withValues(alpha: 0.2),
        isDark ? AppColors.forest900 : AppColors.forest600.withValues(alpha: 0.4),
      ],
    );
    paint.shader = groundGradient.createShader(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2));
    canvas.drawRRect(
      RRect.fromLTRBR(0, size.height * 0.8, size.width, size.height, const Radius.circular(24)),
      paint,
    );
    paint.shader = null;

    if (progress.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // 2. Sort progress to draw back-to-front (simple depth)
    final sortedProgress = List<SRSProgress>.from(progress)
      ..sort((a, b) => a.wordId.hashCode.compareTo(b.wordId.hashCode));

    for (var i = 0; i < sortedProgress.length; i++) {
      final item = sortedProgress[i];
      final itemRandom = math.Random(item.wordId.hashCode);
      
      // Calculate position
      final double x = 40 + itemRandom.nextDouble() * (size.width - 80);
      final double y = size.height * 0.85 + (itemRandom.nextDouble() * 20 - 10);
      
      _drawPlant(canvas, Offset(x, y), item, itemRandom);
    }
  }

  void _drawPlant(Canvas canvas, Offset base, SRSProgress item, math.Random rand) {
    final now = DateTime.now();
    final bool isOverdue = item.nextReview.isBefore(now);
    final double health = isOverdue ? 0.6 : 1.0;
    
    final level = item.level;
    final double windShift = math.sin(windProgress * math.pi * 2 + rand.nextDouble()) * 5;

    if (level <= 2) {
      _drawSprout(canvas, base, health, windShift, rand);
    } else if (level <= 4) {
      _drawShrub(canvas, base, health, windShift, rand);
    } else {
      _drawTree(canvas, base, health, windShift, rand);
    }
  }

  void _drawSprout(Canvas canvas, Offset base, double health, double wind, math.Random rand) {
    final paint = Paint()
      ..color = _getPlantColor(health, AppColors.semanticGreen, rand)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + wind, base.dy - 15,
        base.dx + wind * 1.5, base.dy - 30,
      );
    
    canvas.drawPath(path, paint);
    
    // Leaves
    paint.style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx + wind * 1.5 - 4, base.dy - 30),
        width: 8,
        height: 12,
      ),
      paint,
    );
  }

  void _drawShrub(Canvas canvas, Offset base, double health, double wind, math.Random rand) {
    final trunkPaint = Paint()
      ..color = _getTrunkColor(health, isDark)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final height = 40.0 + rand.nextDouble() * 20;
    
    // Main Stems
    for (int i = 0; i < 3; i++) {
      final angle = (i - 1) * 0.4 + (rand.nextDouble() - 0.5) * 0.2;
      final endPoint = Offset(
        base.dx + math.sin(angle) * height + wind,
        base.dy - math.cos(angle) * height,
      );
      
      canvas.drawLine(base, endPoint, trunkPaint);
      
      // Foliage clusters
      final leafPaint = Paint()
        ..color = _getPlantColor(health, AppColors.forest300, rand)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(endPoint, 10 + rand.nextDouble() * 5, leafPaint);
    }
  }

  void _drawTree(Canvas canvas, Offset base, double health, double wind, math.Random rand) {
    final trunkHeight = 60.0 + rand.nextDouble() * 30;
    final trunkWidth = 8.0;
    
    final trunkPaint = Paint()
      ..color = _getTrunkColor(health, isDark)
      ..style = PaintingStyle.fill;

    // Trunk
    final trunkPath = Path()
      ..moveTo(base.dx - trunkWidth / 2, base.dy)
      ..lineTo(base.dx + trunkWidth / 2, base.dy)
      ..quadraticBezierTo(
        base.dx + wind * 0.5, base.dy - trunkHeight * 0.5,
        base.dx + wind, base.dy - trunkHeight,
      )
      ..lineTo(base.dx + wind - trunkWidth / 3, base.dy - trunkHeight)
      ..close();
    
    canvas.drawPath(trunkPath, trunkPaint);

    // Canopy (Fractal-ish circles)
    final leafPaint = Paint()
      ..color = _getPlantColor(health, AppColors.forest500, rand)
      ..style = PaintingStyle.fill;

    final canopyCenter = Offset(base.dx + wind, base.dy - trunkHeight);
    
    for (int i = 0; i < 6; i++) {
      final offset = Offset(
        (rand.nextDouble() - 0.5) * 40,
        (rand.nextDouble() - 0.5) * 40 - 10,
      );
      canvas.drawCircle(canopyCenter + offset, 15 + rand.nextDouble() * 15, leafPaint);
      
      // Highlight/Gold accents for high mastery
      if (rand.nextDouble() > 0.7) {
        canvas.drawCircle(
          canopyCenter + offset, 
          5, 
          Paint()..color = AppColors.gold500.withValues(alpha: 0.3 * health),
        );
      }
    }
  }

  Color _getPlantColor(double health, Color baseColor, math.Random rand) {
    if (health < 0.8) {
      // Overdue/Wilted colors
      return Color.lerp(baseColor, Colors.brown.shade700, 1.0 - health)!;
    }
    // Healthy colors with slight variations
    return Color.lerp(baseColor, AppColors.forest200, rand.nextDouble() * 0.2)!;
  }

  Color _getTrunkColor(double health, bool isDark) {
    final base = isDark ? const Color(0xFF3E2723) : const Color(0xFF5D4037);
    if (health < 0.8) return Color.lerp(base, Colors.grey.shade800, 0.4)!;
    return base;
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Plant your first seeds by learning new words',
        style: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.8);
    
    textPainter.paint(
      canvas, 
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ForestPainter oldDelegate) => 
    oldDelegate.windProgress != windProgress || 
    oldDelegate.progress.length != progress.length;
}

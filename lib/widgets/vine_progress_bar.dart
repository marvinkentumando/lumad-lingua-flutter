import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VineProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? color;

  const VineProgressBar({
    super.key,
    required this.value,
    this.height = 16,
    this.color,
  });

  @override
  State<VineProgressBar> createState() => _VineProgressBarState();
}

class _VineProgressBarState extends State<VineProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(VineProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vineColor =
        widget.color ?? (isDark ? AppColors.gold500 : AppColors.forest500);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: widget.height + 12, // Extra space for flowers/leaves
          child: CustomPaint(
            painter: _ProceduralVinePainter(
              progress: _animation.value,
              color: vineColor,
              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              accentColor: isDark ? AppColors.terracotta : AppColors.semanticRed,
            ),
          ),
        );
      },
    );
  }
}

class _ProceduralVinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final Color accentColor;

  _ProceduralVinePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double padding = size.height * 0.5;
    final double availableWidth = size.width - (padding * 2);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final vinePaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // 1. Draw Background "Trench"
    final bgPath = Path();
    bgPath.moveTo(padding, centerY);
    _addOrganicLineToPath(bgPath, padding, centerY, availableWidth, 1.0);
    canvas.drawPath(bgPath, bgPaint);

    if (progress <= 0) return;

    // 2. Draw Growing Vine
    final vinePath = Path();
    vinePath.moveTo(padding, centerY);
    _addOrganicLineToPath(vinePath, padding, centerY, availableWidth * progress, progress);
    canvas.drawPath(vinePath, vinePaint);

    // 3. Draw Procedural Leaves and Flowers
    _drawGrowthElements(canvas, padding, centerY, availableWidth, progress);
  }

  void _addOrganicLineToPath(Path path, double startX, double centerY, double length, double p) {
    const int segments = 20;
    final double step = length / segments;
    
    for (int i = 1; i <= segments; i++) {
      final double x = startX + (i * step);
      // Subtle sine wave for "organic" feel
      final double y = centerY + math.sin(x * 0.05) * 2.0;
      path.lineTo(x, y);
    }
  }

  void _drawGrowthElements(Canvas canvas, double startX, double centerY, double totalWidth, double p) {
    final rand = math.Random(42); // Stable seed
    final int elementCount = 12;
    final double spacing = totalWidth / elementCount;

    for (int i = 0; i < elementCount; i++) {
      final double relativePos = i / elementCount;
      // Only draw if progress has reached this point
      if (p < relativePos) continue;

      // Calculate how "mature" this element is (0.0 to 1.0)
      // It starts growing when the vine reaches it and matures over the next 10% of progress
      final double growthMaturity = ((p - relativePos) / 0.1).clamp(0.0, 1.0);
      
      final double x = startX + (i * spacing) + (rand.nextDouble() * 10 - 5);
      final double y = centerY + math.sin(x * 0.05) * 2.0;
      
      // Alternate between left and right growth
      final bool side = rand.nextBool();
      final double angle = (side ? -0.5 : 0.5) + (rand.nextDouble() * 0.4 - 0.2);
      
      if (i % 4 == 0 && i > 0) {
        _drawFlower(canvas, Offset(x, y), angle, growthMaturity, rand);
      } else {
        _drawLeaf(canvas, Offset(x, y), angle, growthMaturity, rand);
      }
    }
  }

  void _drawLeaf(Canvas canvas, Offset origin, double angle, double maturity, math.Random rand) {
    final leafPaint = Paint()
      ..color = color.withValues(alpha: 0.8 * maturity)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    
    final double scale = (0.6 + rand.nextDouble() * 0.4) * maturity;
    canvas.scale(scale);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(8, -12, 16, 0)
      ..quadraticBezierTo(8, 12, 0, 0)
      ..close();

    canvas.drawPath(path, leafPaint);
    
    // Draw leaf vein
    final veinPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1 * maturity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, 0), const Offset(12, 0), veinPaint);
    
    canvas.restore();
  }

  void _drawFlower(Canvas canvas, Offset origin, double angle, double maturity, math.Random rand) {
    if (maturity < 0.3) {
      // Draw as a bud
      final budPaint = Paint()..color = color;
      canvas.drawCircle(origin, 3 * maturity, budPaint);
      return;
    }

    final petalPaint = Paint()..color = accentColor.withValues(alpha: 0.9 * maturity);
    final centerPaint = Paint()..color = AppColors.gold500.withValues(alpha: maturity);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    
    final double scale = (0.5 + rand.nextDouble() * 0.3) * maturity;
    canvas.scale(scale);

    // Draw 5 petals
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * (2 * math.pi / 5));
      canvas.drawOval(Rect.fromLTWH(0, -3, 10, 6), petalPaint);
      canvas.restore();
    }

    // Center of flower
    canvas.drawCircle(Offset.zero, 3, centerPaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProceduralVinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

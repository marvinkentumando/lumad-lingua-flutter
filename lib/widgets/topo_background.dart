import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class TopoBackground extends StatefulWidget {
  final Color baseColor;
  final double opacity;
  final double scrollOffset;

  const TopoBackground({
    super.key,
    required this.baseColor,
    this.opacity = 0.05,
    this.scrollOffset = 0.0,
  });

  @override
  State<TopoBackground> createState() => _TopoBackgroundState();
}

class _TopoBackgroundState extends State<TopoBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: _TopoPainter(
              lineColor: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  .withValues(alpha: widget.opacity),
              animValue: _controller.value,
              scrollOffset: widget.scrollOffset,
            ),
          ),
        );
      },
    );
  }
}

class _TopoPainter extends CustomPainter {
  final Color lineColor;
  final double animValue;
  final double scrollOffset;

  _TopoPainter({required this.lineColor, required this.animValue, required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    void drawContour(Offset center, double radius, int points, double noiseOffset) {
      final path = ui.Path();
      for (int i = 0; i <= points; i++) {
        final angle = (i * 360 / points) * 3.14 / 180;
        final timeOffset = animValue * 2 * math.pi;
        final noise = math.sin(angle * 3 + timeOffset + noiseOffset) * 0.1;
        
        final r = radius + (radius * noise);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Parallax shifting
    final centers = [
      Offset(size.width * 0.1, size.height * 0.2 - scrollOffset * 0.2),
      Offset(size.width * 0.8, size.height * 0.5 - scrollOffset * 0.4),
      Offset(size.width * 0.3, size.height * 0.9 - scrollOffset * 0.1),
      Offset(size.width * 0.9, size.height * 0.1 - scrollOffset * 0.3),
    ];

    for (int i = 0; i < centers.length; i++) {
      final center = centers[i];
      for (int r = 40; r < 300; r += 30) {
        drawContour(center, r.toDouble(), 40, i + r * 0.01);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TopoPainter oldDelegate) {
    return oldDelegate.animValue != animValue || oldDelegate.scrollOffset != scrollOffset || oldDelegate.lineColor != lineColor;
  }
}




import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class TopoBackground extends StatelessWidget {
  final Color baseColor;
  final double opacity;

  const TopoBackground({
    super.key,
    required this.baseColor,
    this.opacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _TopoPainter(
          lineColor:
              (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  .withOpacity(opacity),
        ),
      ),
    );
  }
}

class _TopoPainter extends CustomPainter {
  final Color lineColor;

  _TopoPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw some organic topographical concentric shapes
    void drawContour(Offset center, double radius, int points) {
      final path = ui.Path();
      for (int i = 0; i <= points; i++) {
        final angle = (i * 360 / points) * 3.14 / 180;
        // Add noise to radius based on angle
        final r = radius + (radius * 0.1 * (i % 3 == 0 ? 1 : -0.5));
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

    // Scatter some centers
    final centers = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.9),
      Offset(size.width * 0.9, size.height * 0.1),
    ];

    for (final center in centers) {
      for (int r = 40; r < 300; r += 30) {
        drawContour(center, r.toDouble(), 12);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TopoPainter oldDelegate) => false;
}



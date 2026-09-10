import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GenerativeDagmayBackground extends StatefulWidget {
  final Widget child;
  final bool reactiveToTouch;
  final Color? patternColor;

  const GenerativeDagmayBackground({
    super.key,
    required this.child,
    this.reactiveToTouch = true,
    this.patternColor,
  });

  @override
  State<GenerativeDagmayBackground> createState() => _GenerativeDagmayBackgroundState();
}

class _GenerativeDagmayBackgroundState extends State<GenerativeDagmayBackground> {
  Offset _touchPosition = Offset.zero;
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          setState(() {
            _scrollOffset = notification.metrics.pixels;
          });
        }
        return false;
      },
      child: MouseRegion(
        onHover: widget.reactiveToTouch
            ? (event) => setState(() => _touchPosition = event.localPosition)
            : null,
        child: GestureDetector(
          onPanUpdate: widget.reactiveToTouch
              ? (details) => setState(() => _touchPosition = details.localPosition)
              : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: DagmayPatternPainter(
                    scrollOffset: _scrollOffset,
                    touchPosition: _touchPosition,
                    patternColor: widget.patternColor ?? AppColors.gold500.withValues(alpha: 0.05),
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}

class DagmayPatternPainter extends CustomPainter {
  final double scrollOffset;
  final Offset touchPosition;
  final Color patternColor;
  final bool isDark;

  DagmayPatternPainter({
    required this.scrollOffset,
    required this.touchPosition,
    required this.patternColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = patternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double tileSize = 80.0;
    final int rows = (size.height / tileSize).ceil() + 2;
    final int cols = (size.width / tileSize).ceil() + 2;

    // Shift pattern based on scroll
    canvas.save();
    canvas.translate(0, -(scrollOffset % tileSize));

    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        final double x = c * tileSize;
        final double y = r * tileSize;
        
        // Add subtle generative offset based on coordinates
        final double genX = math.sin(r * 0.5 + c * 0.3) * 5;
        final double genY = math.cos(c * 0.8 + r * 0.2) * 5;
        
        final center = Offset(x + tileSize / 2 + genX, y + tileSize / 2 + genY);

        // Reactivity calculation
        final double distanceToTouch = (center - touchPosition.translate(0, scrollOffset % tileSize)).distance;
        final double reactionScale = math.max(0.0, 1.0 - (distanceToTouch / 300.0));
        
        _drawMansakaMotif(canvas, center, tileSize * 0.8, paint, reactionScale, r, c);
      }
    }
    canvas.restore();
  }

  void _drawMansakaMotif(Canvas canvas, Offset center, double size, Paint paint, double reaction, int r, int c) {
    final double half = size / 2;
    
    // Adjust paint based on reaction
    final effectivePaint = Paint()
      ..color = paint.color.withValues(alpha: paint.color.a + (reaction * 0.15))
      ..style = paint.style
      ..strokeWidth = paint.strokeWidth + (reaction * 1.5);

    // Variation based on grid position (Generative)
    final bool hasInner = (r + c) % 3 == 0;
    final bool hasZigzag = (r * c) % 4 == 0;

    // 1. Primary Diamond (The "Soul" of the weave)
    final path = Path()
      ..moveTo(center.dx, center.dy - half) // Top
      ..lineTo(center.dx + half, center.dy) // Right
      ..lineTo(center.dx, center.dy + half) // Bottom
      ..lineTo(center.dx - half, center.dy) // Left
      ..close();
    
    canvas.drawPath(path, effectivePaint);

    // 2. Generative Details
    if (hasInner || reaction > 0.3) {
      final innerHalf = half * 0.4;
      canvas.drawRect(
        Rect.fromCenter(center: center, width: innerHalf, height: innerHalf),
        effectivePaint,
      );
    }

    if (hasZigzag) {
      final zigzagPath = Path()
        ..moveTo(center.dx - half, center.dy)
        ..lineTo(center.dx - half * 0.5, center.dy - half * 0.2)
        ..lineTo(center.dx, center.dy)
        ..lineTo(center.dx + half * 0.5, center.dy + half * 0.2)
        ..lineTo(center.dx + half, center.dy);
      canvas.drawPath(zigzagPath, effectivePaint);
    }

    // 3. Reaction-based "Glow"
    if (reaction > 0.5) {
      canvas.drawCircle(center, half * reaction, effectivePaint..style = PaintingStyle.fill..color = effectivePaint.color.withValues(alpha: 0.02));
    }
  }

  @override
  bool shouldRepaint(covariant DagmayPatternPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
           oldDelegate.touchPosition != touchPosition;
  }
}

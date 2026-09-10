import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WisdomPortal extends StatefulWidget {
  final bool isUnlocked;
  final double size;

  const WisdomPortal({
    super.key,
    required this.isUnlocked,
    this.size = 180,
  });

  @override
  State<WisdomPortal> createState() => _WisdomPortalState();
}

class _WisdomPortalState extends State<WisdomPortal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_PortalParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Initial particles
    if (widget.isUnlocked) {
      for (int i = 0; i < 30; i++) {
        _particles.add(_generateParticle(true));
      }
    }
  }

  _PortalParticle _generateParticle(bool randomProgress) {
    return _PortalParticle(
      angle: _random.nextDouble() * 2 * math.pi,
      radius: 10 + _random.nextDouble() * 40,
      size: 2 + _random.nextDouble() * 6,
      speed: 0.5 + _random.nextDouble() * 1.5,
      color: [
        AppColors.gold500,
        Colors.white,
        AppColors.terracotta,
      ][_random.nextInt(3)],
      progress: randomProgress ? _random.nextDouble() : 0.0,
    );
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
        if (widget.isUnlocked) {
          // Update particles
          for (int i = 0; i < _particles.length; i++) {
            _particles[i].progress += 0.01 * _particles[i].speed;
            if (_particles[i].progress >= 1.0) {
              _particles[i] = _generateParticle(false);
            }
          }
        }

        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PortalPainter(
            isUnlocked: widget.isUnlocked,
            particles: _particles,
            rotation: _controller.value * 2 * math.pi,
          ),
        );
      },
    );
  }
}

class _PortalParticle {
  double angle;
  double radius;
  double size;
  double speed;
  Color color;
  double progress;

  _PortalParticle({
    required this.angle,
    required this.radius,
    required this.size,
    required this.speed,
    required this.color,
    required this.progress,
  });
}

class _PortalPainter extends CustomPainter {
  final bool isUnlocked;
  final List<_PortalParticle> particles;
  final double rotation;

  _PortalPainter({
    required this.isUnlocked,
    required this.particles,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    if (!isUnlocked) {
      _drawLockedPortal(canvas, center, size.width * 0.4);
      return;
    }

    // 1. Draw Core Glow
    final coreGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold500.withValues(alpha: 0.5),
          AppColors.gold500.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2.5));
    canvas.drawCircle(center, size.width / 2.5, coreGlow);

    // 2. Draw Shimmering Rings (Sacred Geometry feel)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.gold500.withValues(alpha: 0.15);

    for (int i = 1; i <= 5; i++) {
      final pulse = math.sin(rotation + (i * 0.8)) * 4;
      final r = (size.width * 0.15) + (i * 12) + pulse;
      canvas.drawCircle(center, r, ringPaint);
      
      // Draw small "star" nodes on the rings
      final nodeAngle = rotation * (i.isEven ? 1 : -1) + (i * 0.5);
      final nodePos = center + Offset(math.cos(nodeAngle) * r, math.sin(nodeAngle) * r);
      canvas.drawCircle(nodePos, 2, Paint()..color = AppColors.gold500.withValues(alpha: 0.4));
    }

    // 3. Draw Particles (Spirit Wisps)
    for (final p in particles) {
      final opacity = math.sin(p.progress * math.pi);
      // Spiral inward/outward motion
      final currentRadius = p.radius + (math.sin(p.progress * math.pi) * 20);
      final currentAngle = p.angle + (p.progress * math.pi * 0.5);
      
      final x = center.dx + math.cos(currentAngle) * currentRadius;
      final y = center.dy + math.sin(currentAngle) * currentRadius;

      paint.color = p.color.withValues(alpha: opacity * 0.8);
      
      final pGlow = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), p.size * 2, pGlow);
      
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }

    // 4. Draw Central "Ancestral Sun"
    final corePaint = Paint()
      ..color = AppColors.gold500
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, 25, corePaint);
    
    // Core detail
    canvas.drawCircle(center, 12, Paint()..color = Colors.white.withValues(alpha: 0.8));
    
    // Draw radiant beams
    final beamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < 8; i++) {
      final angle = rotation + (i * math.pi / 4);
      final beamLen = 35.0 + math.sin(rotation * 2 + i) * 10;
      canvas.drawLine(
        center + Offset(math.cos(angle) * 15, math.sin(angle) * 15),
        center + Offset(math.cos(angle) * beamLen, math.sin(angle) * beamLen),
        beamPaint,
      );
    }
  }

  void _drawLockedPortal(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, paint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.lock_outline_rounded.codePoint),
        style: TextStyle(
          fontSize: 32,
          fontFamily: Icons.lock_outline_rounded.fontFamily,
          package: Icons.lock_outline_rounded.fontPackage,
          color: Colors.white24,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(canvas, center - Offset(iconPainter.width / 2, iconPainter.height / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

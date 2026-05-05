import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A custom "Soul/Spirit" particle system that replaces basic confetti
/// for high-impact celebrations — artifact unlocks, level-ups, milestones.
///
/// Renders animated particles with ethereal glow, drift, and fade-out.
class SpiritParticleOverlay extends StatefulWidget {
  /// Duration the particle effect runs before auto-dismissing.
  final Duration duration;

  /// Color palette for the particles. Defaults to cultural gold/cyan/violet.
  final List<Color> colors;

  /// Number of particles to spawn.
  final int particleCount;

  /// Called when the animation finishes.
  final VoidCallback? onComplete;

  const SpiritParticleOverlay({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.colors = const [
      AppColors.gold500,
      Colors.cyanAccent,
      Colors.purpleAccent,
      Colors.white,
      Colors.amber,
    ],
    this.particleCount = 40,
    this.onComplete,
  });

  @override
  State<SpiritParticleOverlay> createState() => _SpiritParticleOverlayState();
}

class _SpiritParticleOverlayState extends State<SpiritParticleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SpiritParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _particles = List.generate(widget.particleCount, (_) => _generateParticle());

    _controller.addListener(() => setState(() {}));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  _SpiritParticle _generateParticle() {
    return _SpiritParticle(
      // Random starting position across the screen
      startX: _random.nextDouble(),
      startY: 0.3 + _random.nextDouble() * 0.5, // middle-to-bottom region
      // Drift direction
      driftX: (_random.nextDouble() - 0.5) * 0.4,
      driftY: -0.2 - _random.nextDouble() * 0.6, // float upward
      // Visual properties
      size: 4 + _random.nextDouble() * 10,
      color: widget.colors[_random.nextInt(widget.colors.length)],
      // Timing
      delay: _random.nextDouble() * 0.3,
      speed: 0.5 + _random.nextDouble() * 0.5,
      // Glow intensity
      glowRadius: 8 + _random.nextDouble() * 16,
      // Rotation for non-circular particles
      rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      // Shape type
      shapeType: _random.nextInt(3), // 0=circle, 1=diamond, 2=flame
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SpiritPainter(
          particles: _particles,
          progress: _controller.value,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SpiritParticle {
  final double startX;
  final double startY;
  final double driftX;
  final double driftY;
  final double size;
  final Color color;
  final double delay;
  final double speed;
  final double glowRadius;
  final double rotationSpeed;
  final int shapeType;

  _SpiritParticle({
    required this.startX,
    required this.startY,
    required this.driftX,
    required this.driftY,
    required this.size,
    required this.color,
    required this.delay,
    required this.speed,
    required this.glowRadius,
    required this.rotationSpeed,
    required this.shapeType,
  });
}

class _SpiritPainter extends CustomPainter {
  final List<_SpiritParticle> particles;
  final double progress;

  _SpiritPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate particle-local progress (accounting for delay)
      final localProgress = ((progress - particle.delay) / particle.speed)
          .clamp(0.0, 1.0);

      if (localProgress <= 0) continue;

      // Position
      final x = (particle.startX + particle.driftX * localProgress) * size.width;
      final y = (particle.startY + particle.driftY * localProgress) * size.height;

      // Opacity: fade in quickly, hold, then fade out
      double opacity;
      if (localProgress < 0.15) {
        opacity = localProgress / 0.15;
      } else if (localProgress > 0.7) {
        opacity = (1.0 - localProgress) / 0.3;
      } else {
        opacity = 1.0;
      }
      opacity = opacity.clamp(0.0, 1.0);

      // Scale: start small, grow slightly, then shrink
      final scale = 0.5 + 0.5 * sin(localProgress * pi);

      final actualSize = particle.size * scale;
      final color = particle.color.withValues(alpha: opacity * 0.85);

      // Draw glow
      final glowPaint = Paint()
        ..color = particle.color.withValues(alpha: opacity * 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.glowRadius * scale);
      canvas.drawCircle(Offset(x, y), actualSize * 1.5, glowPaint);

      // Draw particle shape
      final paint = Paint()..color = color;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotationSpeed * localProgress * pi);

      switch (particle.shapeType) {
        case 0: // Circle (spirit orb)
          canvas.drawCircle(Offset.zero, actualSize, paint);
          break;
        case 1: // Diamond (crystal shard)
          final path = Path()
            ..moveTo(0, -actualSize)
            ..lineTo(actualSize * 0.6, 0)
            ..lineTo(0, actualSize)
            ..lineTo(-actualSize * 0.6, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case 2: // Flame (soul wisp)
          final path = Path()
            ..moveTo(0, -actualSize)
            ..quadraticBezierTo(actualSize * 0.8, actualSize * 0.2, 0, actualSize)
            ..quadraticBezierTo(-actualSize * 0.8, actualSize * 0.2, 0, -actualSize)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SpiritPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Helper to show the spirit particle overlay in a stack.
/// Usage: Call from a StatefulWidget and add/remove from overlay.
void showSpiritParticles(BuildContext context, {Duration? duration}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => SpiritParticleOverlay(
      duration: duration ?? const Duration(seconds: 3),
      onComplete: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

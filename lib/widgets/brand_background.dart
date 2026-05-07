import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../services/cultural_theme_service.dart';
import '../theme/cultural_patterns.dart';

class BrandBackground extends ConsumerStatefulWidget {
  final Widget child;
  const BrandBackground({super.key, required this.child});

  @override
  ConsumerState<BrandBackground> createState() => _BrandBackgroundState();
}

class _BrandBackgroundState extends ConsumerState<BrandBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final culturalTheme = ref.watch(culturalThemeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Dynamic Background
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          color: isDark ? AppColors.forest900 : AppColors.creamBg,
        ),

        // Ambient "Mist" or "Sun Rays" Layer (Phase 7)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: AmbientEnvironmentPainter(
                  progress: _controller.value,
                  isDark: isDark,
                  primaryColor: culturalTheme.primaryColor,
                ),
              );
            },
          ),
        ),

        // Cultural Pattern Layer
        Positioned.fill(
          child: CustomPaint(
            painter: CulturalPatternPainter(
              color: isDark
                  ? culturalTheme.accentColor.withValues(alpha: 0.1)
                  : culturalTheme.primaryColor.withValues(alpha: 0.05),
              patternType: culturalTheme.patternType,
              scale: 1.5,
            ),
          ),
        ),

        // Animated Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                _buildOrb(
                  color: culturalTheme.primaryColor.withValues(alpha: 0.12),
                  size: 600,
                  offset: Offset(
                    math.sin(_controller.value * 2 * math.pi) * 100 + 50,
                    math.cos(_controller.value * 2 * math.pi) * 150 + 200,
                  ),
                ),
                _buildOrb(
                  color: culturalTheme.accentColor.withValues(alpha: 0.08),
                  size: 450,
                  offset: Offset(
                    math.cos(_controller.value * 2 * math.pi + math.pi) * 150 + 250,
                    math.sin(_controller.value * 2 * math.pi + math.pi) * 100 + 450,
                  ),
                ),
              ],
            );
          },
        ),

        // Grain Overlay
        Opacity(
          opacity: 0.02,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                ),
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
        ),

        widget.child,
      ],
    );
  }

  Widget _buildOrb({
    required Color color,
    required double size,
    required Offset offset,
  }) {
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

class AmbientEnvironmentPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color primaryColor;

  AmbientEnvironmentPainter({
    required this.progress,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintMist(canvas, size);
    } else {
      _paintSunRays(canvas, size);
    }
  }

  void _paintMist(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    for (int i = 0; i < 3; i++) {
      final t = (progress + (i * 0.33)) % 1.0;
      final x = math.sin(t * 2 * math.pi) * 50 + (size.width * i / 3);
      final y = size.height * 0.7 + math.cos(t * math.pi) * 30;
      
      paint.color = Colors.white.withValues(alpha: 0.03 + (0.02 * math.sin(t * math.pi)));
      
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 400 + (100 * math.sin(t * math.pi)),
          height: 150,
        ),
        paint,
      );
    }
  }

  void _paintSunRays(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.08),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    final center = Offset(size.width * 0.2, -50);
    const rayCount = 5;
    
    for (int i = 0; i < rayCount; i++) {
      final angleProgress = (progress + (i / rayCount)) % 1.0;
      final angle = (math.pi * 0.1) + (math.pi * 0.3 * angleProgress);
      
      final path = Path();
      path.moveTo(center.dx, center.dy);
      
      final length = size.height;
      
      path.lineTo(
        center.dx + math.cos(angle - 0.05) * length,
        center.dy + math.sin(angle - 0.05) * length,
      );
      path.lineTo(
        center.dx + math.cos(angle + 0.05) * length,
        center.dy + math.sin(angle + 0.05) * length,
      );
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AmbientEnvironmentPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}



import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class CrystalBurstAnimation extends StatelessWidget {
  final VoidCallback onComplete;
  final int particleCount;
  final List<String> symbols;

  const CrystalBurstAnimation({
    super.key,
    required this.onComplete,
    this.particleCount = 20,
    this.symbols = const ['✨', '💎', '🌟', '⚡', '✨'],
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: List.generate(particleCount, (index) {
            final random = math.Random(index * 42);
            final angle = (index / particleCount) * 2 * math.pi + (random.nextDouble() * 0.2);
            final distance = 90.0 + random.nextDouble() * 90;
            final duration = 650 + random.nextInt(450);
            final symbol = symbols[index % symbols.length];

            return Text(
              symbol,
              style: TextStyle(
                fontSize: 18 + random.nextDouble() * 12,
                shadows: [
                  Shadow(
                    color: Colors.amber.withValues(alpha: 0.8),
                    blurRadius: 10,
                  ),
                ],
              ),
            )
                .animate(
                  onComplete: (_) {
                    if (index == particleCount - 1) onComplete();
                  },
                )
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1.6, 1.6),
                  duration: 250.ms,
                  curve: Curves.easeOutBack,
                )
                .move(
                  begin: Offset.zero,
                  end: Offset(
                    math.cos(angle) * distance,
                    math.sin(angle) * distance,
                  ),
                  duration: duration.ms,
                  curve: Curves.easeOutCubic,
                )
                .then()
                .fadeOut(duration: 350.ms);
          }),
        ),
      ),
    );
  }
}

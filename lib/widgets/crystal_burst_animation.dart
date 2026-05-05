import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class CrystalBurstAnimation extends StatelessWidget {
  final VoidCallback onComplete;

  const CrystalBurstAnimation({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(15, (index) {
        final random = math.Random();
        final angle = (index / 15) * 2 * math.pi;
        final distance = 100.0 + random.nextDouble() * 50;
        final duration = 600 + random.nextInt(400);

        return Positioned(
          left: MediaQuery.of(context).size.width / 2,
          top: MediaQuery.of(context).size.height / 2,
          child: const Text('âœ¨', style: TextStyle(fontSize: 24))
              .animate(
                onComplete: (_) {
                  if (index == 14) onComplete();
                },
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
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1.5, 1.5),
                duration: 200.ms,
              )
              .then()
              .fadeOut(duration: 400.ms),
        );
      }),
    );
  }
}



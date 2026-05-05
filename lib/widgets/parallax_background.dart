import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ParallaxBackground extends StatefulWidget {
  final Widget child;
  final String backgroundImage;
  final double intensity;

  const ParallaxBackground({
    super.key,
    required this.child,
    required this.backgroundImage,
    this.intensity = 20.0,
  });

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  double _offsetX = 0;
  double _offsetY = 0;
  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!mounted) return;
      setState(() {
        // Map accelerometer values to offsets
        // Accelerometer gives values roughly -10 to 10
        _offsetX = event.x * widget.intensity / 10;
        _offsetY = event.y * widget.intensity / 10;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Parallax Layer
        AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          left: -widget.intensity + _offsetX,
          top: -widget.intensity + _offsetY,
          right: -widget.intensity - _offsetX,
          bottom: -widget.intensity - _offsetY,
          child: Image.asset(
            widget.backgroundImage,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.2),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        // Content Layer
        widget.child,
      ],
    );
  }
}



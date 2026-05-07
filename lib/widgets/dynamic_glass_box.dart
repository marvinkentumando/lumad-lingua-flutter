import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DynamicGlassBox extends StatefulWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? color;
  final Border? border;

  const DynamicGlassBox({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.05,
    this.borderRadius = 24,
    this.color,
    this.border,
  });

  @override
  State<DynamicGlassBox> createState() => _DynamicGlassBoxState();
}

class _DynamicGlassBoxState extends State<DynamicGlassBox> {
  double _tiltX = 0;
  double _tiltY = 0;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (mounted) {
        setState(() {
          // Normalize and limit the tilt
          _tiltX = (event.x / 10).clamp(-1.0, 1.0);
          _tiltY = (event.y / 10).clamp(-1.0, 1.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: Container(
          decoration: BoxDecoration(
            color:
                widget.color ??
                (isDark
                    ? Colors.white.withValues(alpha: widget.opacity)
                    : Colors.black.withValues(alpha: widget.opacity)),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border:
                widget.border ??
                Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1,
                  ),
                  width: 1.5,
                ),
            gradient: LinearGradient(
              begin: Alignment(_tiltX - 0.5, _tiltY - 0.5),
              end: Alignment(_tiltX + 0.5, _tiltY + 0.5),
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.08 : 0.15),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}





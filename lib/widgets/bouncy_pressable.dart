import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// A spring-scale pressable wrapper that provides tactile, responsive bounce feedback.
class BouncyPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;
  final bool enableHaptics;

  const BouncyPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.enableHaptics = true,
  });

  @override
  State<BouncyPressable> createState() => _BouncyPressableState();
}

class _BouncyPressableState extends State<BouncyPressable> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.enableHaptics) {
      HapticService.light();
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap!();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

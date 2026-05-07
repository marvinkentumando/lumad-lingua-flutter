import 'package:flutter/material.dart';

class TactileWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleOnTap;
  final Duration duration;
  final bool enableHaptics;

  const TactileWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.scaleOnTap = 0.96,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptics = true,
  });

  @override
  State<TactileWrapper> createState() => _TactileWrapperState();
}

class _TactileWrapperState extends State<TactileWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnTap,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

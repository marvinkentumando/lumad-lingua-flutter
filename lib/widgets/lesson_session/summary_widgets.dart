import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/haptic_service.dart';

class SummaryStatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const SummaryStatRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedSummaryStatRow extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int endValue;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Duration delay;

  const AnimatedSummaryStatRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.endValue,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1400),
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedSummaryStatRow> createState() => _AnimatedSummaryStatRowState();
}

class _AnimatedSummaryStatRowState extends State<AnimatedSummaryStatRow> {
  int _lastTick = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.iconColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.iconColor.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: widget.iconColor.withValues(alpha: 0.4)),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: widget.endValue),
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              if (value > 0 && (value % ((widget.endValue / 4).clamp(1, 10).toInt()) == 0) && value != _lastTick) {
                _lastTick = value;
                HapticService.selection();
              }
              return Text(
                '${widget.prefix}$value${widget.suffix}',
                style: TextStyle(
                  color: widget.iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: widget.delay).slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
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

class SrsMasteryBadgeWidget extends StatelessWidget {
  final int stars;
  final int accuracy;

  const SrsMasteryBadgeWidget({
    super.key,
    required this.stars,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final String masteryStage = stars == 3
        ? "MASTERED (SRS LEVEL 5)"
        : (stars == 2 ? "REVIEWING (SRS LEVEL 3)" : "LEARNING (SRS LEVEL 1)");

    final Color badgeColor = stars == 3
        ? AppColors.gold500
        : (stars == 2 ? Colors.cyanAccent : Colors.orangeAccent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: badgeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "LEITNER SRS MASTERY",
                      style: AppTypography.label.copyWith(
                        color: badgeColor,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.auto_awesome,
                      color: badgeColor,
                      size: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  masteryStage,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "+$accuracy% SRS",
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutCubic);
  }
}

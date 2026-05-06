import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VineProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? color;

  const VineProgressBar({
    super.key,
    required this.value,
    this.height = 14,
    this.color,
  });

  @override
  State<VineProgressBar> createState() => _VineProgressBarState();
}

class _VineProgressBarState extends State<VineProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward();
  }

  @override
  void didUpdateWidget(VineProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
          );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vineColor =
        widget.color ?? (isDark ? AppColors.gold500 : AppColors.forest500);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: widget.height,
          child: CustomPaint(
            painter: _VinePainter(
              progress: _animation.value,
              color: vineColor,
              backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            ),
          ),
        );
      },
    );
  }
}

class _VinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _VinePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.6;

    final progressPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.6;

    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw background track (carved wood feel)
    canvas.drawLine(
      Offset(size.height / 2, size.height / 2),
      Offset(size.width - size.height / 2, size.height / 2),
      bgPaint,
    );

    if (progress <= 0) return;

    // Draw progress vine (now a straight branch)
    final startX = size.height / 2;
    final endX = (size.width - size.height) * progress + size.height / 2;

    canvas.drawLine(
      Offset(startX, size.height / 2),
      Offset(endX, size.height / 2),
      progressPaint,
    );

    // Draw leaves along the straight branch
    final leafCount = (progress * 8).floor();
    for (int i = 0; i <= leafCount; i++) {
      double leafX;
      if (leafCount == 0) {
        leafX = startX;
      } else {
        leafX = startX + (endX - startX) * (i / leafCount);
      }

      final leafY = size.height / 2;

      canvas.save();
      canvas.translate(leafX, leafY);
      canvas.rotate(0.2 * (i % 2 == 0 ? 1 : -1)); // Slight alternate tilt

      // Draw alternate leaves up/down
      final factor = i % 2 == 0 ? 1.0 : -1.0;
      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(4, 4 * factor, 8, 0)
        ..quadraticBezierTo(4, -4 * factor, 0, 0);

      canvas.drawPath(leafPath, leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _VinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}



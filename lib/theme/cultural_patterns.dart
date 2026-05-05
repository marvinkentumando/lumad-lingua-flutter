import 'package:flutter/material.dart';

class CulturalPatternPainter extends CustomPainter {
  final Color color;
  final String patternType; // 'dagmay', 'inabal', 'tnalak'
  final double scale;

  CulturalPatternPainter({
    required this.color,
    required this.patternType,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (patternType) {
      case 'dagmay':
        _drawDagmay(canvas, size, paint);
        break;
      case 'inabal':
        _drawInabal(canvas, size, paint);
        break;
      default:
        _drawGeneric(canvas, size, paint);
    }
  }

  void _drawDagmay(Canvas canvas, Size size, Paint paint) {
    final double step = 20 * scale;
    for (double i = -step; i < size.width + step; i += step) {
      for (double j = -step; j < size.height + step; j += step) {
        final path = Path()
          ..moveTo(i, j)
          ..lineTo(i + step / 2, j + step / 2)
          ..lineTo(i + step, j)
          ..lineTo(i + step / 2, j - step / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawInabal(Canvas canvas, Size size, Paint paint) {
    final double step = 30 * scale;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i + step, size.height), paint);
      canvas.drawLine(Offset(i + step, 0), Offset(i, size.height), paint);
    }
  }

  void _drawGeneric(Canvas canvas, Size size, Paint paint) {
    final double step = 15 * scale;
    for (double i = 0; i < size.width; i += step) {
      for (double j = 0; j < size.height; j += step) {
        if ((i / step).floor() % 2 == (j / step).floor() % 2) {
          canvas.drawRect(Rect.fromLTWH(i, j, step / 2, step / 2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



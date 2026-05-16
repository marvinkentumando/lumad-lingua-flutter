import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SakaSegment {
  final double startX, endX, startY, endY;
  SakaSegment({required this.startX, required this.endX, required this.startY, required this.endY});
}

class SakaParticle {
  double x, y, vx, vy, life;
  Color color;
  SakaParticle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.life});
  void update(double dt) { x += vx * dt; y += vy * dt; vy += 500 * dt; life -= dt; }
}

class SakaEnvParticle {
  double x, y, vx, vy, life;
  final SakaEnvType type;
  SakaEnvParticle({required this.x, required this.y, required this.vx, required this.vy, required this.type, required this.life});
  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    if (type == SakaEnvType.leaf) {
      vx += sin(life * 5) * 2; // Sways
    }
    life -= dt;
  }
}

enum SakaEnvType { leaf, snow }

class SakaPainter extends CustomPainter {
  final double playerX, playerY, velocityX, velocityY, animValue, cameraShake, zoomLevel;
  final bool isJumping;
  final int currentStage;
  final List<double> shrines;
  final Set<int> clearedShrines;
  final List<SakaParticle> particles;
  final List<Offset> mistCrystals;
  final Set<int> collectedCrystals;
  final List<SakaSegment> segments;
  final List<Offset> playerTrail;

  SakaPainter({
    required this.playerX, required this.playerY, required this.velocityX, required this.velocityY, required this.isJumping,
    required this.currentStage, required this.shrines, required this.clearedShrines,
    required this.animValue, required this.particles, required this.mistCrystals,
    required this.collectedCrystals, required this.cameraShake, required this.zoomLevel,
    required this.segments, required this.playerTrail,
    required this.landingSquash, required this.mistTransition,
    required this.envParticles, required this.isVictory,
    required this.speedBoost,
  });

  final double landingSquash, mistTransition, speedBoost;
  final List<SakaEnvParticle> envParticles;
  final bool isVictory;

  @override
  void paint(Canvas canvas, Size size) {
    double cameraX = playerX - (size.width / 3);
    if (isVictory) {
      cameraX = lerpDouble(cameraX, playerX - (size.width / 2), 0.1)!;
    }
    if (cameraX < 0) cameraX = 0;
    canvas.save();
    if (cameraShake > 0) {
      final rand = Random();
      canvas.translate((rand.nextDouble() - 0.5) * cameraShake, (rand.nextDouble() - 0.5) * cameraShake);
    }

    _drawCelestialBodies(canvas, size);

    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoomLevel);
    canvas.translate(-size.width / 2, -size.height / 2);
    _drawParallaxLayer(canvas, size, cameraX, 0.1, const Color(0xFF080712), 150);
    _drawParallaxLayer(canvas, size, cameraX, 0.3, const Color(0xFF0F1424), 100);
    _drawParallaxLayer(canvas, size, cameraX, 0.5, const Color(0xFF141B2D), 50);
    if (currentStage == 3) _drawMist(canvas, size, true);
    _drawOrganicGround(canvas, size, cameraX);
    _drawLandmarks(canvas, size, cameraX);
    _drawMistCrystals(canvas, cameraX, size);
    for (int i = 0; i < shrines.length; i++) {
      double sx = shrines[i] - cameraX;
      if (sx > -200 && sx < size.width + 200) _drawShrine(canvas, sx, clearedShrines.contains(i), shrines[i], size);
    }
    _drawSpeedTrail(canvas, cameraX, size);
    _drawParticles(canvas, cameraX, size);
    if (currentStage == 1) _drawFireflies(canvas, size);
    if (currentStage == 4) _drawWind(canvas, size);
    if (currentStage == 5) _drawSummitGlow(canvas, size);
    _drawPlayer(canvas, size, cameraX);
    _drawSpeedBuffVFX(canvas, size);
    _drawEnvParticles(canvas, size);
    _drawMistSweep(canvas, size);
    _drawVignette(canvas, size);
    _drawSunFlare(canvas, size);
    canvas.restore();
  }

  void _drawSpeedBuffVFX(Canvas canvas, Size size) {
    if (speedBoost <= 0) return;
    
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: (speedBoost / 150) * 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    for (int i = 0; i < 15; i++) {
      double speed = 800 + (i * 50);
      double x = size.width - ((animValue * speed + i * 200) % (size.width + 200));
      double y = (i * size.height / 15);
      double length = 50 + (i * 10);
      canvas.drawLine(Offset(x, y), Offset(x + length, y), paint);
    }
  }

  void _drawMistSweep(Canvas canvas, Size size) {
    if (mistTransition <= 0) return;
    
    final paint = Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    double t = 1.0 - mistTransition; 
    
    for (int i = 0; i < 15; i++) {
      double x = (size.width * 1.5 * t) - 400 + (i * 30);
      double y = (i * size.height / 15) + sin(t * pi * 4 + i) * 50;
      double radius = 100 + sin(i.toDouble()) * 50;
      canvas.drawCircle(Offset(x, y), radius, paint..color = Colors.white.withValues(alpha: (mistTransition * 0.8).clamp(0.0, 0.8)));
    }
  }

  void _drawEnvParticles(Canvas canvas, Size size) {
    for (var p in envParticles) {
      if (p.type == SakaEnvType.leaf) {
        final paint = Paint()..color = Colors.brown.withValues(alpha: 0.6);
        canvas.save();
        canvas.translate(p.x, p.y);
        canvas.rotate(p.life);
        canvas.drawOval(const Rect.fromLTWH(-4, -2, 8, 4), paint);
        canvas.restore();
      } else {
        final paint = Paint()..color = Colors.white.withValues(alpha: 0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(p.x, p.y), 2, paint);
      }
    }
  }

  void _drawSpeedTrail(Canvas canvas, double cameraX, Size size) {
    if (playerTrail.isEmpty) return;
    double visualOffset = size.height - 348;
    for (int i = 0; i < playerTrail.length; i++) {
      double alpha = (i / playerTrail.length) * 0.2;
      final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
      double tx = playerTrail[i].dx - cameraX;
      double ty = playerTrail[i].dy + visualOffset;
      
      canvas.drawCircle(Offset(tx, ty - 35), 8, paint);
      canvas.drawRect(Rect.fromLTWH(tx - 6, ty - 27, 12, 18), paint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    double intensity = 0;
    if (currentStage == 2) intensity = 0.2;
    if (currentStage == 3) intensity = 0.4;
    if (intensity == 0) return;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: intensity)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawSunFlare(Canvas canvas, Size size) {
    if (currentStage != 5) return;
    double progress = (playerX / 5400).clamp(0.0, 1.0);
    double sunAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    double sunY = size.height * 0.7 - (sunAlpha * size.height * 0.6);
    Offset sunPos = Offset(size.width * 0.8, sunY);
    
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(sunPos, 150, paint);
    
    for (int i = 0; i < 3; i++) {
      double dist = 100.0 * (i + 1);
      canvas.drawCircle(
        Offset(sunPos.dx - dist * 0.5, sunPos.dy + dist * 0.5), 
        30 - (i * 5), 
        Paint()..color = Colors.orangeAccent.withValues(alpha: 0.03)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      );
    }
  }

  void _drawParallaxLayer(Canvas canvas, Size size, double cameraX, double speed, Color color, double heightOffset) {
    final paint = Paint()..color = color;
    final path = Path();
    double offset = -(cameraX * speed) % 800;
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width + 800; x += 100) {
      double dx = x + offset;
      double h = (sin(x / 200) * 40) + heightOffset + (size.height * 0.4);
      path.lineTo(dx, size.height - h);
    }
    path.lineTo(size.width + 800, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawOrganicGround(Canvas canvas, Size size, double cameraX) {
    final groundPaint = Paint()..color = const Color(0xFF1B2E1D);
    final grassPaint = Paint()..color = const Color(0xFF2D4F3C)..strokeWidth = 2;
    final path = Path();
    double visualOffset = size.height - 348;
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 5) {
      double worldX = x + cameraX;
      double baseSlopeY = _getSlopeY(worldX);
      double noise = sin(worldX * 0.05) * 3 + cos(worldX * 0.02) * 2;
      path.lineTo(x, baseSlopeY + visualOffset + noise);

      if (Random(worldX.toInt()).nextDouble() > 0.96) {
        double distToPlayer = (worldX - playerX).abs();
        double tilt = sin(worldX * 0.1 + animValue * pi * 2) * 4;
        if (distToPlayer < 40) {
          double push = (40 - distToPlayer) / 40 * 15;
          tilt += (worldX > playerX) ? push : -push;
        }
        canvas.drawLine(
          Offset(x, baseSlopeY + visualOffset + noise),
          Offset(x + tilt, baseSlopeY + visualOffset + noise - 12),
          grassPaint,
        );
      }
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, groundPaint);
  }

  double _getSlopeY(double x) {
    for (var seg in segments) {
      if (x >= seg.startX && x <= seg.endX) {
        double t = (x - seg.startX) / (seg.endX - seg.startX);
        return lerpDouble(seg.startY, seg.endY, t)!;
      }
    }
    return 348;
  }

  void _drawMistCrystals(Canvas canvas, double cameraX, Size size) {
    final paint = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.8);
    final glow = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    double visualOffset = size.height - 348;
    for (int i = 0; i < mistCrystals.length; i++) {
      if (collectedCrystals.contains(i)) continue;
      double dx = mistCrystals[i].dx - cameraX;
      if (dx < -50 || dx > size.width + 50) continue;
      double hover = sin(animValue * pi * 2 + i) * 5;
      Offset pos = Offset(dx, mistCrystals[i].dy + visualOffset + hover);
      canvas.drawCircle(pos, 8, glow); canvas.drawCircle(pos, 4, paint);
    }
  }

  void _drawParticles(Canvas canvas, double cameraX, Size size) {
    final paint = Paint();
    double visualOffset = size.height - 348;
    for (var p in particles) {
      double dx = p.x - cameraX;
      if (dx < -10 || dx > size.width + 10) continue;
      paint.color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(dx, p.y + visualOffset), 3 * p.life, paint);
    }
  }

  void _drawLandmarks(Canvas canvas, Size size, double cameraX) {
    double visualOffset = size.height - 348;
    if (cameraX < 2000 && cameraX + size.width > 1200) {
      double x = 1500 - cameraX;
      double y = _getSlopeY(1500) + visualOffset;
      _drawWaterfall(canvas, x, y);
    }
    if (cameraX < 3500 && cameraX + size.width > 2500) {
      double x = 2800 - cameraX;
      double y = _getSlopeY(2800) + visualOffset;
      _drawBaleteTree(canvas, x, y);
    }
    if (cameraX < 4000 && cameraX + size.width > 3000) {
      double x = 3500 - cameraX;
      double y = _getSlopeY(3500) + visualOffset;
      _drawTotem(canvas, x, y);
    }
  }

  void _drawTotem(Canvas canvas, double x, double y) {
    final woodPaint = Paint()..color = const Color(0xFF4E342E);
    final detailPaint = Paint()..color = AppColors.gold500.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 2;
    
    canvas.drawRect(Rect.fromLTWH(x - 15, y - 100, 30, 100), woodPaint);
    
    double pulse = sin(animValue * pi * 4) * 0.5 + 0.5;
    final glowPaint = Paint()..color = AppColors.gold500.withValues(alpha: pulse * 0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    for (int i = 0; i < 3; i++) {
      double runeY = y - 80 + (i * 25);
      canvas.drawCircle(Offset(x, runeY), 4, glowPaint);
      canvas.drawLine(Offset(x - 8, runeY - 4), Offset(x + 8, runeY + 4), detailPaint);
      canvas.drawLine(Offset(x + 8, runeY - 4), Offset(x - 8, runeY + 4), detailPaint);
    }
  }

  void _drawWaterfall(Canvas canvas, double x, double y) {
    final paint = Paint()..color = Colors.lightBlueAccent.withValues(alpha: 0.4);
    final streamPaint = Paint()..color = Colors.white.withValues(alpha: 0.3)..strokeWidth = 2;
    final mistPaint = Paint()..color = Colors.white.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawRect(Rect.fromLTWH(x - 30, y, 60, 400), paint);
    
    for (int i = 0; i < 3; i++) {
      double sx = x - 20 + (i * 20);
      double offset = (animValue * 400 + i * 130) % 400;
      canvas.drawLine(Offset(sx, y + offset), Offset(sx, y + offset + 30), streamPaint);
    }

    for (int i = 0; i < 5; i++) {
      double mx = x - 30 + (i * 15) + sin(animValue * pi * 2 + i) * 5;
      double my = y + 380 + cos(animValue * pi + i) * 5;
      canvas.drawCircle(Offset(mx, my), 20, mistPaint);
    }
  }

  void _drawBaleteTree(Canvas canvas, double x, double y) {
    final trunkPaint = Paint()..color = const Color(0xFF2A1A0A);
    final leafPaint = Paint()..color = const Color(0xFF14241A);
    canvas.drawRect(Rect.fromLTWH(x - 20, y - 150, 40, 150), trunkPaint);
    canvas.drawCircle(Offset(x, y - 180), 80, leafPaint);

    double treeWorldX = 2800;
    double dist = (playerX - treeWorldX).abs();
    if (dist < 400) {
      double t = (400 - dist) / 400; 
      final birdPaint = Paint()..color = Colors.black.withValues(alpha: (1.0 - t).clamp(0.2, 0.8))..style = PaintingStyle.stroke..strokeWidth = 1.2;
      for (int i = 0; i < 4; i++) {
        double bx = x + (i * 40) - (t * 500);
        double by = y - 200 - (t * 300) + sin(animValue * pi * 10 + i) * 15;
        Path birdPath = Path();
        birdPath.moveTo(bx - 6, by);
        birdPath.quadraticBezierTo(bx, by - 6, bx + 6, by);
        canvas.drawPath(birdPath, birdPaint);
      }
    }
  }

  void _drawShrine(Canvas canvas, double x, bool cleared, double worldX, Size size) {
    final paint = Paint()..color = cleared ? AppColors.gold500 : Colors.blueGrey;
    double visualOffset = size.height - 348;
    double y = _getSlopeY(worldX) + visualOffset;
    canvas.drawRect(Rect.fromLTWH(x - 25, y - 50, 50, 50), paint);
    if (cleared) {
      double hover = sin(animValue * pi * 2) * 5;
      canvas.drawCircle(Offset(x, y - 70 + hover), 8, paint..color = Colors.white);
    }
  }

  void _drawPlayer(Canvas canvas, Size size, double cameraX) {
    double drawX = playerX - cameraX;
    double drawY = playerY + (size.height - 348);
    final paint = Paint()..color = Colors.white;

    canvas.save();
    canvas.translate(drawX, drawY);

    double stretch = 0.0;
    double squash = landingSquash;

    if (isJumping) {
      stretch = (velocityY.abs() * 0.0005).clamp(0.0, 0.25);
    } else {
      squash += sin(animValue * pi * 2) * 0.02;
    }

    double lean = (velocityX * 0.0004).clamp(-0.15, 0.15);

    canvas.rotate(lean);
    canvas.scale(1.0 - stretch + squash, 1.0 + stretch - squash);

    final scarfPaint = Paint()
      ..color = AppColors.gold500
      ..style = PaintingStyle.fill;
    
    final scarfPath = Path();
    double neckX = 0;
    double neckY = -27;
    
    double windFactor = (currentStage == 4) ? -25 : 0;
    double moveFactor = -velocityX * 0.15;
    double sway = sin(animValue * pi * 4) * 4;
    
    scarfPath.moveTo(neckX, neckY);
    double cpX = neckX + (moveFactor * 0.5) + windFactor;
    double cpY = neckY + sway;
    double endX = neckX + moveFactor + (windFactor * 1.5);
    double endY = neckY + 12 + sway;

    scarfPath.quadraticBezierTo(cpX, cpY, endX, endY);
    scarfPath.lineTo(endX, endY + 8);
    scarfPath.quadraticBezierTo(cpX, cpY + 5, neckX, neckY + 5);
    scarfPath.close();
    
    canvas.drawPath(scarfPath, scarfPaint);

    canvas.drawCircle(const Offset(0, -35), 8, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-6, -27, 12, 18),
        const Radius.circular(4),
      ),
      paint,
    );
    
    final eyePaint = Paint()..color = const Color(0xFF1B2E1D);
    double eyeX = (velocityX > 0) ? 2 : (velocityX < 0 ? -2 : 0);
    canvas.drawCircle(Offset(eyeX - 2.5, -37), 1.2, eyePaint);
    canvas.drawCircle(Offset(eyeX + 2.5, -37), 1.2, eyePaint);

    canvas.restore();
  }

  void _drawFireflies(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..color = Colors.greenAccent.withValues(alpha: 0.4);
    for (int i = 0; i < 30; i++) {
      double x = (random.nextDouble() * size.width + animValue * 100) % size.width;
      double y = (random.nextDouble() * size.height + sin(animValue * pi * 2 + i) * 20) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  void _drawMist(Canvas canvas, Size size, bool back) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    for (int i = 0; i < 3; i++) {
      double xOffset = (animValue * size.width * 0.5 + i * 200) % size.width;
      canvas.drawOval(Rect.fromLTWH(xOffset - 200, size.height * 0.3 + i * 100, size.width * 0.8, 150), paint);
    }
  }

  void _drawWind(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15)..strokeWidth = 1;
    final rand = Random(99);
    for (int i = 0; i < 15; i++) {
      double x = (rand.nextDouble() * size.width - animValue * size.width) % size.width;
      double y = rand.nextDouble() * size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 50, y - 5), paint);
    }
  }

  void _drawSummitGlow(Canvas canvas, Size size) {
    final paint = Paint()..shader = RadialGradient(colors: [const Color(0xFFFFC200).withValues(alpha: 0.2), Colors.transparent]).createShader(Rect.fromLTWH(size.width - 200, -100, 400, 400));
    canvas.drawCircle(Offset(size.width - 50, 50), 300 + sin(animValue * pi * 2) * 20, paint);
  }

  void _drawCelestialBodies(Canvas canvas, Size size) {
    double progress = (playerX / 5400).clamp(0.0, 1.0);
    
    if (progress < 0.6) {
      double alpha = (1.0 - (progress / 0.6)).clamp(0.0, 1.0);
      final moonPaint = Paint()..color = Colors.white.withValues(alpha: alpha * 0.5);
      canvas.drawCircle(Offset(size.width * 0.2, 100 + progress * 150), 25, moonPaint);
    }
    
    if (progress > 0.4) {
      double sunAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      double sunY = size.height * 0.7 - (sunAlpha * size.height * 0.6);
      final sunGlow = Paint()..color = const Color(0xFFFFC200).withValues(alpha: sunAlpha * 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(size.width * 0.8, sunY), 50, sunGlow);
      canvas.drawCircle(Offset(size.width * 0.8, sunY), 25, Paint()..color = Colors.white.withValues(alpha: sunAlpha * 0.8));
    }
  }

  @override
  bool shouldRepaint(covariant SakaPainter oldDelegate) => true;
}

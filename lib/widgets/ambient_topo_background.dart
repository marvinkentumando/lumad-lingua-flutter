import 'package:flutter/material.dart';
import 'topo_background.dart';

class AmbientTopoBackground extends StatelessWidget {
  final Widget child;
  final double scrollOffset;

  const AmbientTopoBackground({
    super.key,
    required this.child,
    this.scrollOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    Color ambientColor;
    
    if (hour >= 5 && hour < 11) {
      ambientColor = const Color(0xFF2D4F3C); // Morning Dew
    } else if (hour >= 11 && hour < 17) {
      ambientColor = const Color(0xFF1B3022); // Deep Forest
    } else if (hour >= 17 && hour < 20) {
      ambientColor = const Color(0xFF4F3422); // Golden Hour
    } else {
      ambientColor = const Color(0xFF0F1711); // Midnight Moss
    }

    return Stack(
      children: [
        // Solid background color
        Container(color: ambientColor),
        
        // Dynamic Topo Background
        TopoBackground(baseColor: ambientColor, opacity: 0.08, scrollOffset: scrollOffset),
        
        // Content
        child,
      ],
    );
  }
}


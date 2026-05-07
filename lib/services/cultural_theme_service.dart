import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

class CulturalTheme {
  final Color primaryColor;
  final Color accentColor;
  final String patternType;
  final String name;

  CulturalTheme({
    required this.primaryColor,
    required this.accentColor,
    required this.patternType,
    required this.name,
  });
}

class CulturalThemeNotifier extends Notifier<CulturalTheme> {
  static final CulturalTheme _defaultTheme = CulturalTheme(
    primaryColor: AppColors.forest500,
    accentColor: AppColors.gold500,
    patternType: 'generic',
    name: 'Default',
  );

  static final Map<String, CulturalTheme> _themes = {
    'Mansaka': CulturalTheme(
      primaryColor: const Color(0xFF8B4513), // Saddle Brown
      accentColor: const Color(0xFFD2691E), // Chocolate
      patternType: 'dagmay',
      name: 'Mansaka',
    ),
    'Bagobo': CulturalTheme(
      primaryColor: const Color(0xFF4B0082), // Indigo
      accentColor: const Color(0xFF9400D3), // Dark Violet
      patternType: 'inabal',
      name: 'Bagobo',
    ),
    'Tboli': CulturalTheme(
      primaryColor: const Color(0xFFB22222), // Firebrick
      accentColor: const Color(0xFFFF4500), // Orange Red
      patternType: 'tnalak',
      name: 'T\'boli',
    ),
  };

  @override
  CulturalTheme build() {
    return _defaultTheme;
  }

  void setThemeByLanguage(String language) {
    state = _themes[language] ?? _defaultTheme;
  }
}

final culturalThemeProvider =
    NotifierProvider<CulturalThemeNotifier, CulturalTheme>(() {
      return CulturalThemeNotifier();
    });




import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.creamBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forest500,
        secondary: AppColors.terracotta,
        tertiary: AppColors.gold500,
        surface: AppColors.creamBg,
        surfaceContainerHighest: Colors.white,
        error: AppColors.semanticRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.black,
        onSurface: AppColors.creamText,
        onSurfaceVariant: AppColors.creamText2,
        outline: AppColors.creamBorder,
        outlineVariant: Color(0xFFE5D5B5),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.creamBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.forest500),
        iconTheme: const IconThemeData(color: AppColors.forest500, size: 24),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.creamBg,
        modalBackgroundColor: AppColors.creamBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.creamBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.forest500),
      textTheme: _buildTextTheme(Brightness.light),
      inputDecorationTheme: _buildInputTheme(Brightness.light),
      dividerTheme: DividerThemeData(
        color: AppColors.creamBorder.withValues(alpha: 0.5),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.forest900,
      colorScheme: ColorScheme.dark(
        primary: AppColors.gold500,
        secondary: AppColors.forest400,
        tertiary: AppColors.semanticBlue,
        surface: AppColors.forest900,
        surfaceContainerHighest: AppColors.forestDarkCard,
        error: AppColors.semanticRed,
        onPrimary: AppColors.creamText,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        outline: Colors.white24,
        outlineVariant: Colors.white10,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forest900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.gold500),
        iconTheme: const IconThemeData(color: AppColors.gold500, size: 24),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.forest900,
        modalBackgroundColor: AppColors.forest900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.forestDarkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.forest900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.gold500),
      textTheme: _buildTextTheme(Brightness.dark),
      inputDecorationTheme: _buildInputTheme(Brightness.dark),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? AppColors.creamText
        : Colors.white;
    final secondaryColor = brightness == Brightness.light
        ? AppColors.creamText2
        : Colors.white70;

    return TextTheme(
      displayLarge: AppTypography.display.copyWith(color: color),
      headlineLarge: AppTypography.h1.copyWith(color: color),
      headlineMedium: AppTypography.h2.copyWith(color: color),
      headlineSmall: AppTypography.h3.copyWith(color: color),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: color),
      bodyMedium: AppTypography.body.copyWith(color: secondaryColor),
      labelSmall: AppTypography.label.copyWith(color: secondaryColor),
    );
  }

  static InputDecorationTheme _buildInputTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.3);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);
    final focusedColor = isDark ? AppColors.gold500 : AppColors.forest500;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: AppTypography.body.copyWith(color: hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedColor, width: 1.5),
      ),
    );
  }
}

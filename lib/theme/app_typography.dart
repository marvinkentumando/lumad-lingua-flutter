import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static final TextStyle display = GoogleFonts.fredoka(
    fontSize: 48,
    fontWeight: FontWeight.w600,
    color: AppColors.creamText,
    height: 1.1,
  );

  static final TextStyle displayBold = GoogleFonts.fredoka(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.creamText,
    height: 1.1,
  );

  static final TextStyle h1ExtraBold = GoogleFonts.fredoka(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.creamText,
    height: 1.15,
  );

  static final TextStyle h2ExtraBold = GoogleFonts.fredoka(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.creamText,
    height: 1.2,
  );

  static final TextStyle h1 = GoogleFonts.fredoka(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.creamText,
    height: 1.15,
  );

  static final TextStyle h2 = GoogleFonts.fredoka(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.creamText,
    height: 1.2,
  );

  static final TextStyle h3 = GoogleFonts.fredoka(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.creamText,
    height: 1.25,
  );

  static final TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF3A2810),
    height: 1.6,
  );

  static final TextStyle body = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF3A2810),
    height: 1.6,
  );

  static final TextStyle label = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.creamText3,
    letterSpacing: 1.5,
  );

  static final TextStyle mono = GoogleFonts.dmMono(
    fontSize: 13,
    color: AppColors.forest500,
  );
}



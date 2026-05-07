import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../brand_button.dart';

class ConfigurationPreview extends StatelessWidget {
  final String title;
  final String description;
  final String difficulty;
  final String dialect;

  const ConfigurationPreview({
    super.key,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.dialect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.menu_book_rounded, size: 64, color: AppColors.gold500),
        const SizedBox(height: 24),
        Text(
          title.isEmpty ? 'Lesson Title' : title,
          style: AppTypography.h2.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$difficulty • $dialect',
          style: AppTypography.label.copyWith(color: AppColors.gold500),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            description.isEmpty ? 'Description will appear here.' : description,
            style: AppTypography.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 40),
        BrandButton(text: 'START', onTap: () {}, type: BrandButtonType.primary),
      ],
    );
  }
}




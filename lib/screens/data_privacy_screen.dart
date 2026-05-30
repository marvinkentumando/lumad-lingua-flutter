import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/ambient_topo_background.dart';
import '../widgets/brand_button.dart';

class DataPrivacyScreen extends ConsumerWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientTopoBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('ACCOUNT SECURITY'),
                      const SizedBox(height: 16),
                      _buildSecurityCard(context),
                      const SizedBox(height: 32),
                      _sectionLabel('DATA MANAGEMENT'),
                      const SizedBox(height: 16),
                      _buildManagementTile(
                        context,
                        Icons.download_rounded,
                        'Export My Data',
                        'Download a copy of your contributions and activity history',
                        onTap: () => _showComingSoon(context, 'Data Export'),
                      ),
                      const SizedBox(height: 12),
                      _buildManagementTile(
                        context,
                        Icons.history_rounded,
                        'Activity Logs',
                        'Review your recent sign-in and security activity',
                        onTap: () => _showComingSoon(context, 'Activity Logs'),
                      ),
                      const SizedBox(height: 32),
                      _sectionLabel('PRIVACY CONTROLS'),
                      const SizedBox(height: 16),
                      _buildPrivacyToggle(
                        context,
                        'Public Profile',
                        'Allow other tribe members to see your achievements and rank',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildPrivacyToggle(
                        context,
                        'Usage Analytics',
                        'Share anonymous data to help improve the platform',
                        false,
                      ),
                      const SizedBox(height: 40),
                      _buildDangerZone(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.gold500,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Data & Privacy',
            style: AppTypography.h2ExtraBold.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.forest900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: AppTypography.label.copyWith(
          color: AppColors.gold500,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      );

  Widget _buildSecurityCard(BuildContext context) {
    return BrandCard(
      theme: BrandCardTheme.gold,
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.black),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Protected',
                      style: AppTypography.h3.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Your sacred data is encrypted with village protocols.',
                      style: AppTypography.body.copyWith(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          BrandButton(
            text: 'UPDATE PASSWORD',
            type: BrandButtonType.secondary,
            onTap: () => _showComingSoon(context, 'Password Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementTile(
    BuildContext context,
    IconData icon,
    String title,
    String sub, {
    VoidCallback? onTap,
  }) {

    return BrandCard(
      onTap: onTap,
      theme: BrandCardTheme.vibrant,
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold500, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  sub,
                  style: AppTypography.body.copyWith(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(
    BuildContext context,
    String title,
    String sub,
    bool initialValue,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: isDark ? Colors.white : AppColors.forest900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  sub,
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white38 : AppColors.creamText3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: (v) => _showComingSoon(context, 'Privacy Toggles'),
            activeThumbColor: AppColors.gold500,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.semanticRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.semanticRed.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DANGER ZONE',
            style: AppTypography.label.copyWith(
              color: AppColors.semanticRed,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your account and all associated ancestral contributions.',
            style: AppTypography.body.copyWith(
              color: AppColors.semanticRed.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDeleteConfirmation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.semanticRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'DELETE ACCOUNT',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is being prepared by the village elders.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: const Text('Sacrifice Account?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action is irreversible. All your progress, XP, and contributions will be lost to the shadows. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Account Deletion');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_button.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class DataPrivacyScreen extends ConsumerWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: profileAsync.when(
                  data: (profile) => _buildContent(context, ref, profile),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold500)),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic>? profile) {
    final bool isPublic = profile?['isPublicProfile'] ?? true;
    final bool shareAnalytics = profile?['shareAnalytics'] ?? false;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('ACCOUNT SECURITY'),
          const SizedBox(height: 16),
          _buildSecurityCard(context, ref),
          const SizedBox(height: 32),
          _sectionLabel('DATA MANAGEMENT'),
          const SizedBox(height: 16),
          _buildManagementTile(
            context,
            Icons.download_rounded,
            'Export My Data',
            'Copy a JSON version of your contributions and activity',
            onTap: () => _exportData(context, ref),
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
            ref,
            'Public Profile',
            'Allow other tribe members to see your achievements and rank',
            isPublic,
            (v) => _togglePrivacy(ref, isPublic: v),
          ),
          const SizedBox(height: 12),
          _buildPrivacyToggle(
            context,
            ref,
            'Usage Analytics',
            'Share anonymous data to help improve the platform',
            shareAnalytics,
            (v) => _togglePrivacy(ref, shareAnalytics: v),
          ),
          const SizedBox(height: 40),
          _buildDangerZone(context, ref),
          const SizedBox(height: 40),
        ],
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

  Widget _buildSecurityCard(BuildContext context, WidgetRef ref) {
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
            onTap: () => _showUpdatePasswordDialog(context, ref),
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
    WidgetRef ref,
    String title,
    String sub,
    bool value,
    Function(bool) onChanged,
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
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold500,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
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
              onPressed: () => _showDeleteConfirmation(context, ref),
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

  void _togglePrivacy(WidgetRef ref, {bool? isPublic, bool? shareAnalytics}) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await ref.read(firebaseServiceProvider).updatePrivacySettings(
        user.uid,
        isPublic: isPublic,
        shareAnalytics: shareAnalytics,
      );
    }
  }

  void _exportData(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final data = await ref.read(firebaseServiceProvider).exportUserData(user.uid);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      
      await Clipboard.setData(ClipboardData(text: jsonStr));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported and copied to clipboard!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showUpdatePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: Text('Update Password', style: AppTypography.h3.copyWith(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final verified = await ref.read(authServiceProvider).verifyPassword(oldPasswordController.text);
                if (verified) {
                  await ref.read(authServiceProvider).updatePassword(newPasswordController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully!')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect current password.'), backgroundColor: AppColors.semanticRed),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.semanticRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
            child: const Text('UPDATE', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: const Text('Sacrifice Account?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is irreversible. All your progress, XP, and contributions will be lost. Please enter your password to confirm.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final verified = await ref.read(authServiceProvider).verifyPassword(passwordController.text);
                if (verified) {
                  await ref.read(authServiceProvider).deleteUserAccount();
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    // Auth state change will handle navigation to login
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect password.'), backgroundColor: AppColors.semanticRed),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deletion failed: $e'), backgroundColor: AppColors.semanticRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

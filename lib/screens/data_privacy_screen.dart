import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_button.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_localization.dart';

class DataPrivacyScreen extends ConsumerWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: profileAsync.when(
                  data: (profile) => _buildContent(context, ref, profile, l10n),
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

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic>? profile, AppLocalization l10n) {
    final bool isPublic = profile?['isPublicProfile'] ?? true;
    final bool shareAnalytics = profile?['shareAnalytics'] ?? false;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(l10n.translate('account_security')),
          const SizedBox(height: 16),
          _buildSecurityCard(context, ref, l10n),
          const SizedBox(height: 32),
          _sectionLabel(l10n.translate('data_management')),
          const SizedBox(height: 16),
          _buildManagementTile(
            context,
            Icons.download_rounded,
            l10n.translate('export_data'),
            l10n.translate('export_data_desc'),
            onTap: () => _exportData(context, ref, l10n),
          ),
          const SizedBox(height: 12),
          _buildManagementTile(
            context,
            Icons.history_rounded,
            l10n.translate('activity_logs'),
            l10n.translate('review_security'),
            onTap: () => _showComingSoon(context, l10n.translate('activity_logs'), l10n),
          ),
          const SizedBox(height: 32),
          _sectionLabel(l10n.translate('privacy_controls')),
          const SizedBox(height: 16),
          _buildPrivacyToggle(
            context,
            ref,
            l10n.translate('public_profile'),
            l10n.translate('public_profile_desc'),
            isPublic,
            (v) => _togglePrivacy(ref, isPublic: v),
          ),
          const SizedBox(height: 12),
          _buildPrivacyToggle(
            context,
            ref,
            l10n.translate('usage_analytics'),
            l10n.translate('share_anonymous_desc'),
            shareAnalytics,
            (v) => _togglePrivacy(ref, shareAnalytics: v),
          ),
          const SizedBox(height: 40),
          _buildDangerZone(context, ref, l10n),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalization l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
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
            l10n.translate('data_privacy'),
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

  Widget _buildSecurityCard(BuildContext context, WidgetRef ref, AppLocalization l10n) {
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
                      l10n.translate('account_protected'),
                      style: AppTypography.h3.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      l10n.translate('data_encryption_desc'),
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
            text: l10n.translate('update_password'),
            type: BrandButtonType.secondary,
            onTap: () => _showUpdatePasswordDialog(context, ref, l10n),
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
                    color: Colors.white60,
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
                    color: isDark ? Colors.white60 : AppColors.creamText3,
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

  Widget _buildDangerZone(BuildContext context, WidgetRef ref, AppLocalization l10n) {
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
            l10n.translate('danger_zone'),
            style: AppTypography.label.copyWith(
              color: AppColors.semanticRed,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('delete_account_desc'),
            style: AppTypography.body.copyWith(
              color: AppColors.semanticRed.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDeleteConfirmation(context, ref, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.semanticRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.translate('delete_account_btn'),
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature, AppLocalization l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature ${l10n.translate('prepared_by_elders')}'),
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

  void _exportData(BuildContext context, WidgetRef ref, AppLocalization l10n) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final data = await ref.read(firebaseServiceProvider).exportUserData(user.uid);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/lumad_lingua_export_${user.uid.substring(0, 5)}.json');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Lumad Lingua Data Export',
            text: 'Here is your exported data from Lumad Lingua.',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.translate('export_failed')} $e")),
        );
      }
    }
  }

  void _showUpdatePasswordDialog(BuildContext context, WidgetRef ref, AppLocalization l10n) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: Text(l10n.translate('update_password'), style: AppTypography.h3.copyWith(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.translate('current_password'),
                labelStyle: const TextStyle(color: Colors.white60),
              ),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.translate('new_password'),
                labelStyle: const TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.translate('cancel').toUpperCase()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final verified = await ref.read(authServiceProvider).verifyPassword(oldPasswordController.text);
                if (verified) {
                  await ref.read(authServiceProvider).updatePassword(newPasswordController.text);
                  if (context.mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('password_updated'))),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('incorrect_current_pass')), backgroundColor: AppColors.semanticRed),
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
            child: Text(l10n.translate('save'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, AppLocalization l10n) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.forest800,
        title: Text(l10n.translate('sacrifice_account'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.translate('irreversible_desc'),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.translate('password'),
                labelStyle: const TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.translate('cancel').toUpperCase()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final verified = await ref.read(authServiceProvider).verifyPassword(passwordController.text);
                if (verified) {
                  await ref.read(authServiceProvider).deleteUserAccount();
                  if (context.mounted) {
                    context.pop(); // Close dialog
                    // Auth state change will handle navigation to login
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('incorrect_pass')), backgroundColor: AppColors.semanticRed),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${l10n.translate('deletion_failed')} $e"), backgroundColor: AppColors.semanticRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.semanticRed),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );
  }
}

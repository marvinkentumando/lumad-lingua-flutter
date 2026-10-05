import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_background.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_text_field.dart';
import '../widgets/password_strength_meter.dart';
import '../utils/password_validator.dart';
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
          _buildDangerZone(context, ref, l10n, profile),
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

  String _getProviderName(User? user) {
    if (user == null || user.providerData.isEmpty) return 'Identity Provider';
    final providerId = user.providerData.first.providerId;
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'phone':
        return 'Phone';
      case 'facebook.com':
        return 'Facebook';
      default:
        return 'Identity Provider';
    }
  }

  Widget _buildSecurityCard(BuildContext context, WidgetRef ref, AppLocalization l10n) {
    final user = ref.watch(authServiceProvider).currentUser;
    final bool isPassword = user != null && user.providerData.any((info) => info.providerId == 'password');
    final providerName = _getProviderName(user);

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
                      isPassword
                          ? l10n.translate('data_encryption_desc')
                          : 'Signed in via $providerName. Password & security settings are managed through $providerName.',
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
          if (isPassword)
            BrandButton(
              text: l10n.translate('update_password'),
              type: BrandButtonType.secondary,
              onTap: () => _showUpdatePasswordDialog(context, ref, l10n),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_person_rounded, size: 20, color: Colors.black87),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Password Managed by $providerName',
                      style: AppTypography.label.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildDangerZone(
    BuildContext context,
    WidgetRef ref,
    AppLocalization l10n,
    Map<String, dynamic>? profile,
  ) {
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
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.semanticRed, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.translate('danger_zone'),
                style: AppTypography.label.copyWith(
                  color: AppColors.semanticRed,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDangerActionItem(
            title: 'Reset Learning Progress',
            description: 'Reset your XP, day streak, and lesson completion history to restart learning from level 1. Your account profile remains active.',
            buttonText: 'RESET PROGRESS',
            isOutline: true,
            onPressed: () => _showResetProgressConfirmation(context, ref, l10n),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 20),
          _buildDangerActionItem(
            title: l10n.translate('sacrifice_account'),
            description: l10n.translate('delete_account_desc'),
            buttonText: l10n.translate('delete_account_btn'),
            isOutline: false,
            onPressed: () => _showDeleteConfirmation(context, ref, l10n, profile),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerActionItem({
    required String title,
    required String description,
    required String buttonText,
    required bool isOutline,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTypography.body.copyWith(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutline ? Colors.transparent : AppColors.semanticRed,
              foregroundColor: isOutline ? AppColors.semanticRed : Colors.white,
              side: isOutline ? const BorderSide(color: AppColors.semanticRed, width: 1.5) : null,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
        ),
      ],
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
    final user = ref.read(authServiceProvider).currentUser;
    final bool isPassword = user != null && user.providerData.any((info) => info.providerId == 'password');

    if (!isPassword) {
      final providerName = _getProviderName(user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password changes for $providerName accounts are managed directly through $providerName settings.'),
          backgroundColor: AppColors.forest800,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdatePasswordDialog(ref: ref, l10n: l10n),
    );
  }

  void _showResetProgressConfirmation(BuildContext context, WidgetRef ref, AppLocalization l10n) {
    showDialog(
      context: context,
      builder: (context) => _ResetProgressDialog(ref: ref, l10n: l10n),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, AppLocalization l10n, Map<String, dynamic>? profile) {
    final username = profile?['username'] ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteAccountDialog(
        ref: ref,
        l10n: l10n,
        username: username,
      ),
    );
  }
}

class _UpdatePasswordDialog extends StatefulWidget {
  final WidgetRef ref;
  final AppLocalization l10n;

  const _UpdatePasswordDialog({
    required this.ref,
    required this.l10n,
  });

  @override
  State<_UpdatePasswordDialog> createState() => _UpdatePasswordDialogState();
}

class _UpdatePasswordDialogState extends State<_UpdatePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordValid {
    final newPwd = _newPasswordController.text;
    final validation = PasswordValidator.validate(newPwd);
    return validation.isStrong;
  }

  bool get _doPasswordsMatch {
    return _newPasswordController.text == _confirmPasswordController.text;
  }

  bool get _canSubmit {
    return !_isLoading &&
        _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _isPasswordValid &&
        _doPasswordsMatch;
  }

  Future<void> _handleSave() async {
    if (!_canSubmit) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final verified = await widget.ref
          .read(authServiceProvider)
          .verifyPassword(_currentPasswordController.text);

      if (!verified) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = widget.l10n.translate('incorrect_current_pass');
          });
        }
        return;
      }

      await widget.ref
          .read(authServiceProvider)
          .updatePassword(_newPasswordController.text);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.translate('password_updated')),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final pwdValidation = PasswordValidator.validate(_newPasswordController.text);
    final isConfirmMismatch = _confirmPasswordController.text.isNotEmpty && !_doPasswordsMatch;

    return AlertDialog(
      backgroundColor: AppColors.forest800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        l10n.translate('update_password'),
        style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandTextField(
              controller: _currentPasswordController,
              labelText: l10n.translate('current_password'),
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              onChanged: (_) => setState(() {
                _errorMessage = null;
              }),
            ),
            const SizedBox(height: 16),
            BrandTextField(
              controller: _newPasswordController,
              labelText: l10n.translate('new_password'),
              prefixIcon: Icons.lock_reset_rounded,
              isPassword: true,
              showValidation: true,
              isValid: pwdValidation.isStrong,
              errorText: _newPasswordController.text.isNotEmpty && !pwdValidation.isStrong
                  ? l10n.translate('password_not_strong')
                  : null,
              onChanged: (_) => setState(() {
                _errorMessage = null;
              }),
            ),
            PasswordStrengthMeter(
              password: _newPasswordController.text,
              l10n: l10n,
            ),
            const SizedBox(height: 12),
            BrandTextField(
              controller: _confirmPasswordController,
              labelText: l10n.translate('confirm_password'),
              prefixIcon: Icons.lock_clock_outlined,
              isPassword: true,
              showValidation: true,
              isValid: _confirmPasswordController.text.isNotEmpty && _doPasswordsMatch,
              errorText: isConfirmMismatch ? l10n.translate('passwords_dont_match') : null,
              onChanged: (_) => setState(() {
                _errorMessage = null;
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.semanticRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.semanticRed.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.semanticRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.label.copyWith(
                          color: AppColors.semanticRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.translate('cancel').toUpperCase(),
            style: TextStyle(
              color: _isLoading ? Colors.white24 : Colors.white60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _canSubmit ? _handleSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold500,
            disabledBackgroundColor: AppColors.gold500.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.forest900,
                  ),
                )
              : Text(
                  l10n.translate('save'),
                  style: TextStyle(
                    color: _canSubmit ? AppColors.forest900 : Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ResetProgressDialog extends StatefulWidget {
  final WidgetRef ref;
  final AppLocalization l10n;

  const _ResetProgressDialog({
    required this.ref,
    required this.l10n,
  });

  @override
  State<_ResetProgressDialog> createState() => _ResetProgressDialogState();
}

class _ResetProgressDialogState extends State<_ResetProgressDialog> {
  bool _isLoading = false;

  Future<void> _handleReset() async {
    final user = widget.ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await widget.ref
          .read(firebaseServiceProvider)
          .resetUserLearningProgress(user.uid);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Learning progress, XP, and streak have been reset.'),
            backgroundColor: AppColors.gold500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting progress: $e'),
            backgroundColor: AppColors.semanticRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.forest800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.restart_alt_rounded, color: AppColors.gold500),
          const SizedBox(width: 10),
          Text(
            'Reset Progress?',
            style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to reset your learning progress? Your XP, streak, crystals, and completed lesson history will be set to 0. Your account will remain active.',
        style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            widget.l10n.translate('cancel').toUpperCase(),
            style: TextStyle(
              color: _isLoading ? Colors.white24 : Colors.white60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.semanticRed,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'CONFIRM RESET',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final WidgetRef ref;
  final AppLocalization l10n;
  final String username;

  const _DeleteAccountDialog({
    required this.ref,
    required this.l10n,
    required this.username,
  });

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  final _confirmationTextController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationTextController.dispose();
    super.dispose();
  }

  bool get _isPasswordUser {
    final user = widget.ref.read(authServiceProvider).currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  String get _providerName {
    final user = widget.ref.read(authServiceProvider).currentUser;
    if (user == null || user.providerData.isEmpty) return 'Identity Provider';
    final providerId = user.providerData.first.providerId;
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'phone':
        return 'Phone';
      case 'facebook.com':
        return 'Facebook';
      default:
        return 'Identity Provider';
    }
  }

  bool get _isConfirmationValid {
    final input = _confirmationTextController.text.trim();
    if (input.toUpperCase() == 'DELETE') return true;
    if (widget.username.isNotEmpty && input.toLowerCase() == widget.username.toLowerCase()) {
      return true;
    }
    return false;
  }

  bool get _canDelete {
    if (_isLoading) return false;
    if (!_isConfirmationValid) return false;
    if (_isPasswordUser && _passwordController.text.isEmpty) return false;
    return true;
  }

  Future<void> _handleDelete() async {
    if (!_canDelete) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = widget.ref.read(authServiceProvider);

      if (_isPasswordUser) {
        final verified = await authService.verifyPassword(_passwordController.text);
        if (!verified) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = widget.l10n.translate('incorrect_pass');
            });
          }
          return;
        }
      } else {
        // OAuth user (Google, Apple, etc.) re-authentication
        final reauthed = await authService.reauthenticateGoogle();
        if (!reauthed) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Re-authentication via $_providerName was cancelled or failed.';
            });
          }
          return;
        }
      }

      await authService.deleteUserAccount();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "${widget.l10n.translate('deletion_failed')} ${e.toString().replaceAll('Exception: ', '')}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final expectedWord = widget.username.isNotEmpty ? '"DELETE" or "${widget.username}"' : '"DELETE"';

    return AlertDialog(
      backgroundColor: AppColors.forest800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.semanticRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.translate('sacrifice_account'),
              style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('irreversible_desc'),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Grace Period Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.gold500, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '30-Day Grace Period: Permanent data removal occurs 30 days after deletion request.',
                      style: AppTypography.body.copyWith(color: AppColors.gold500, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isPasswordUser) ...[
              BrandTextField(
                controller: _passwordController,
                labelText: l10n.translate('password'),
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Re-authenticating via $_providerName upon confirmation.',
                        style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'To confirm, type $expectedWord below:',
              style: AppTypography.label.copyWith(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            BrandTextField(
              controller: _confirmationTextController,
              labelText: 'Type DELETE to confirm',
              prefixIcon: Icons.edit_note_rounded,
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.semanticRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.semanticRed.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.label.copyWith(
                    color: AppColors.semanticRed,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.translate('cancel').toUpperCase(),
            style: TextStyle(
              color: _isLoading ? Colors.white24 : Colors.white60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _canDelete ? _handleDelete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.semanticRed,
            disabledBackgroundColor: AppColors.semanticRed.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n.translate('delete'),
                  style: TextStyle(
                    color: _canDelete ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

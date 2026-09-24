import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../widgets/parallax_background.dart';
import '../utils/app_localization.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _statusMessage;
  bool _isSuccessMessage = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 30]) {
    setState(() {
      _cooldownSeconds = seconds;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _cooldownSeconds = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cooldownSeconds--;
          });
        }
      }
    });
  }

  Future<void> _checkVerification() async {
    HapticService.selection();
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    final l10n = ref.read(localizationProvider);

    try {
      final isVerified = await ref.read(authServiceProvider).reloadUser();
      if (!mounted) return;

      setState(() => _isChecking = false);

      if (isVerified) {
        HapticService.heavy();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('email_verified_success')),
            backgroundColor: AppColors.semanticGreen,
          ),
        );
        context.go('/');
      } else {
        HapticService.error();
        setState(() {
          _isSuccessMessage = false;
          _statusMessage = l10n.translate('email_not_verified_yet');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _isSuccessMessage = false;
        _statusMessage = l10n.getAuthErrorMessage(e);
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    HapticService.selection();
    setState(() {
      _isResending = true;
      _statusMessage = null;
    });

    final l10n = ref.read(localizationProvider);

    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) return;

      setState(() {
        _isResending = false;
        _isSuccessMessage = true;
        _statusMessage = l10n.translate('verification_email_sent');
      });
      _startCooldown(30);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _isSuccessMessage = false;
        _statusMessage = l10n.getAuthErrorMessage(e);
      });
    }
  }

  Future<void> _handleSignOut() async {
    HapticService.selection();
    await ref.read(authServiceProvider).signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);
    final user = ref.watch(authServiceProvider).currentUser;
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ParallaxBackground(
        backgroundImage: 'assets/images/onboarding_bg.png',
        intensity: 15,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 1.0 : 0.3,
                child: Image.asset(
                  'assets/images/onboarding_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.8),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          size: 64,
                          color: AppColors.gold500,
                        ),
                      ).animate().scale().fadeIn(),
                      const SizedBox(height: 20),
                      Text(
                        l10n.translate('verify_your_email'),
                        style: AppTypography.display.copyWith(
                          color: AppColors.gold500,
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),
                      BrandCard(
                        theme: BrandCardTheme.cream,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.translate('verification_instructions'),
                              style: AppTypography.body.copyWith(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.forest900.withValues(alpha: 0.85),
                                fontSize: 14,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.forest900.withValues(alpha: 0.6)
                                    : AppColors.creamBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.gold500.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    size: 18,
                                    color: AppColors.gold500,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      userEmail,
                                      style: AppTypography.label.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.gold500
                                            : AppColors.gold700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_statusMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: _isSuccessMessage
                                      ? AppColors.semanticGreen.withValues(alpha: 0.1)
                                      : AppColors.semanticRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isSuccessMessage
                                        ? AppColors.semanticGreen.withValues(alpha: 0.3)
                                        : AppColors.semanticRed.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  _statusMessage!,
                                  style: AppTypography.label.copyWith(
                                    color: _isSuccessMessage
                                        ? AppColors.semanticGreen
                                        : AppColors.semanticRed,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ).animate().shake(),
                            ],
                            BrandButton(
                              text: _isChecking
                                  ? l10n.translate('checking')
                                  : l10n.translate('ive_verified'),
                              type: BrandButtonType.primary,
                              onTap: _isChecking ? null : _checkVerification,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: (_cooldownSeconds > 0 || _isResending)
                                  ? null
                                  : _resendVerificationEmail,
                              icon: _isResending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.gold500,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      size: 16,
                                      color: AppColors.gold500,
                                    ),
                              label: Text(
                                _cooldownSeconds > 0
                                    ? l10n.translate(
                                        'resend_in_seconds',
                                        params: {'seconds': _cooldownSeconds.toString()},
                                      )
                                    : l10n.translate('resend_verification_email'),
                                style: TextStyle(
                                  color: (_cooldownSeconds > 0 || _isResending)
                                      ? (isDark ? Colors.white38 : Colors.black38)
                                      : AppColors.gold500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: (_cooldownSeconds > 0 || _isResending)
                                      ? Colors.black12
                                      : AppColors.gold500.withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _handleSignOut,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppColors.gold500,
                        ),
                        label: Text(
                          l10n.translate('sign_out_or_change_account'),
                          style: AppTypography.body.copyWith(
                            color: AppColors.gold500,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

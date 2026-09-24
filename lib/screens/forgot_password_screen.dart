import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_text_field.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../widgets/parallax_background.dart';
import '../utils/app_localization.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    final l10n = ref.read(localizationProvider);
    final email = _emailController.text.trim();

    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      HapticService.error();
      setState(() {
        _errorMessage = l10n.translate('invalid_email_format');
      });
      return;
    }

    HapticService.selection();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        HapticService.heavy();
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.getAuthErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            HapticService.selection();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
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
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 56,
                          color: AppColors.gold500,
                        ),
                      ).animate().scale().fadeIn(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translate('reset_password_title'),
                        style: AppTypography.display.copyWith(
                          color: AppColors.gold500,
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),
                      BrandCard(
                        theme: BrandCardTheme.cream,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_emailSent) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.semanticGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.semanticGreen.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 40,
                                        color: AppColors.semanticGreen,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.translate('reset_email_sent'),
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.semanticGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.translate('check_email_instructions'),
                                        style: AppTypography.body.copyWith(
                                          color: isDark
                                              ? Colors.white70
                                              : AppColors.forest900.withValues(alpha: 0.8),
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(),
                                const SizedBox(height: 20),
                                BrandButton(
                                  text: l10n.translate('back_to_sign_in'),
                                  type: BrandButtonType.primary,
                                  onTap: () => context.go('/login'),
                                ),
                              ] else ...[
                                Text(
                                  l10n.translate('reset_password_desc'),
                                  style: AppTypography.body.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.forest900.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.semanticRed.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.semanticRed.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTypography.label.copyWith(
                                        color: AppColors.semanticRed,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ).animate().shake(),
                                ],
                                BrandTextField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  labelText: l10n.translate('email_address'),
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!_isLoading) _handleSendResetLink();
                                  },
                                ),
                                const SizedBox(height: 20),
                                BrandButton(
                                  text: _isLoading
                                      ? l10n.translate('waiting')
                                      : l10n.translate('send_reset_link'),
                                  type: BrandButtonType.primary,
                                  onTap: _isLoading ? null : _handleSendResetLink,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      if (!_emailSent)
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            l10n.translate('back_to_sign_in'),
                            style: AppTypography.body.copyWith(
                              color: AppColors.gold500,
                              fontWeight: FontWeight.bold,
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

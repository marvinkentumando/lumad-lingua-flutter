import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _submitted = false;

  bool _isLoading = false;
  String? _errorMessage;

  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && !_emailTouched) {
        setState(() => _emailTouched = true);
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && !_passwordTouched) {
        setState(() => _passwordTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _getEmailError(AppLocalization l10n) {
    final text = _emailController.text.trim();
    if ((_emailTouched || _submitted) && text.isNotEmpty) {
      if (!_emailRegex.hasMatch(text)) {
        return l10n.translate('invalid_email_format');
      }
    } else if (_submitted && text.isEmpty) {
      return l10n.translate('invalid_email_format');
    }
    return null;
  }

  String? _getPasswordError(AppLocalization l10n) {
    final text = _passwordController.text.trim();
    if ((_passwordTouched || _submitted) && text.isNotEmpty) {
      if (text.length < 6) {
        return l10n.translate('password_too_short');
      }
    } else if (_submitted && text.isEmpty) {
      return l10n.translate('password_too_short');
    }
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() => _submitted = true);

    final l10n = ref.read(localizationProvider);
    if (_getEmailError(l10n) != null || _getPasswordError(l10n) != null) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        setState(() => _isLoading = false);
        TextInput.finishAutofillContext();
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final l10n = ref.read(localizationProvider);
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.getAuthErrorMessage(e);
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      if (credential != null && mounted) {
        context.go('/');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        final l10n = ref.read(localizationProvider);
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
                      const Text(
                        "🌿",
                        style: TextStyle(fontSize: 64),
                      ).animate().fadeIn().scale(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translate('app_name'),
                        style: AppTypography.display.copyWith(
                          color: AppColors.gold500,
                          fontSize: 32,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 32),
                      BrandCard(
                        theme: BrandCardTheme.cream,
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_errorMessage != null) _buildError(),
                                BrandTextField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  labelText: l10n.translate('email_address'),
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email, AutofillHints.username],
                                  errorText: _getEmailError(l10n),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                BrandTextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  labelText: l10n.translate('password'),
                                  prefixIcon: Icons.lock_outline,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  errorText: _getPasswordError(l10n),
                                  onChanged: (_) => setState(() {}),
                                  onFieldSubmitted: (_) {
                                    if (!_isLoading) _handleLogin();
                                  },
                                ),
                                const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading ? null : () => _showForgotPasswordDialog(context, l10n),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    l10n.translate('forgot_password'),
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.gold500,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              BrandButton(
                                text: _isLoading ? l10n.translate('signing_in') : l10n.translate('sign_in'),
                                type: BrandButtonType.primary,
                                onTap: _isLoading ? null : _handleLogin,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: Colors.black12)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      l10n.translate('or'),
                                      style: AppTypography.label.copyWith(color: Colors.black38, fontSize: 10),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: Colors.black12)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildGoogleButton(l10n),
                            ],
                          ),
                        ),
                      ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      _buildFooter(isDark, l10n),
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


  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.semanticRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.semanticRed.withValues(alpha: 0.3)),
      ),
      child: Text(
        _errorMessage!,
        style: AppTypography.label.copyWith(color: AppColors.semanticRed),
        textAlign: TextAlign.center,
      ),
    ).animate().shake();
  }

  Widget _buildGoogleButton(AppLocalization l10n) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      icon: Image.asset(
        'assets/images/google_logo.png',
        height: 20,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle_outlined, color: Colors.blue),
      ),
      label: Text(
        l10n.translate('sign_in_google'),
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFooter(bool isDark, AppLocalization l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.translate('dont_have_account'),
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticService.selection();
            context.push('/signup');
          },
          child: Text(
            l10n.translate('sign_up'),
            style: AppTypography.body.copyWith(
              color: AppColors.gold500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  void _showForgotPasswordDialog(BuildContext context, AppLocalization l10n) {
    HapticService.selection();
    context.push('/forgot-password');
  }
}





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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
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
        context.go('/');
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
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        "Lumad Lingua",
                        style: AppTypography.display.copyWith(
                          color: AppColors.gold500,
                          fontSize: 32,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 32),
                      BrandCard(
                        theme: BrandCardTheme.cream,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_errorMessage != null) _buildError(),
                              BrandTextField(
                                controller: _emailController,
                                labelText: "Email Address",
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                errorText: _emailController.text.isNotEmpty && !_emailController.text.contains('@')
                                    ? "Invalid email format"
                                    : null,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              BrandTextField(
                                controller: _passwordController,
                                labelText: "Password",
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                errorText: _passwordController.text.isNotEmpty && _passwordController.text.length < 6
                                    ? "Password too short"
                                    : null,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 24),
                              BrandButton(
                                text: _isLoading ? "Signing In..." : "Sign In",
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
                                      "OR",
                                      style: AppTypography.label.copyWith(color: Colors.black38, fontSize: 10),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: Colors.black12)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildGoogleButton(),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      _buildFooter(isDark),
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

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      icon: Image.network(
        'https://img.icons8.com/color/48/000000/google-logo.png',
        height: 20,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle_outlined, color: Colors.blue),
      ),
      label: const Text(
        "Sign in with Google",
        style: TextStyle(
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

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
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
            "Sign Up",
            style: AppTypography.body.copyWith(
              color: AppColors.gold500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}




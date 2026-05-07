import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_card.dart';
import '../widgets/brand_button.dart';
import '../widgets/brand_text_field.dart';
import '../services/auth_service.dart';
import '../widgets/parallax_background.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 0: Identity
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 1: Roots
  final _usernameController = TextEditingController();
  final _locationController = TextEditingController();
  final _tribeController = TextEditingController();

  // Step 2: Path
  final _nativeLanguageController = TextEditingController();
  String _selectedAvatar = "🦅";
  String _learningGoal = "Culture";
  final List<String> _totems = ["🦅", "🏆", "🐢", "🛶", "🌿", "⛰️", "🏹", "🔥"];
  final List<String> _goals = [
    "Culture",
    "Travel",
    "Ancestry",
    "Community",
    "Research",
  ];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    _tribeController.dispose();
    _nativeLanguageController.dispose();
    super.dispose();
  }

  bool _validateStep() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return false;
    }

    if (_currentStep == 0) {
      return _emailController.text.contains('@') &&
          _passwordController.text.length >= 6 &&
          _passwordController.text == _confirmPasswordController.text;
    } else if (_currentStep == 1) {
      return _usernameController.text.length >= 3 &&
          _locationController.text.isNotEmpty &&
          _tribeController.text.isNotEmpty;
    } else if (_currentStep == 2) {
      return _nativeLanguageController.text.isNotEmpty;
    }
    return true;
  }

  void _nextStep() {
    if (_validateStep()) {
      setState(() {
        _currentStep++;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = "Please fill all fields correctly");
    }
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
      _errorMessage = null;
    });
  }

  Future<void> _handleSignup() async {
    if (!_validateStep()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _usernameController.text.trim(),
            location: _locationController.text.trim(),
            tribe: _tribeController.text.trim(),
            avatar: _selectedAvatar,
            nativeLanguage: _nativeLanguageController.text.trim(),
            learningGoal: _learningGoal,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppColors.forest700,
          ),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: ParallaxBackground(
        backgroundImage: 'assets/images/onboarding_bg.png',
        intensity: 20,
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
                          ? AppColors.forest900.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.8),
                      isDark ? AppColors.forest900 : AppColors.creamBg,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 48.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildStepIndicator(),
                      const SizedBox(height: 24),
                      BrandCard(
                            theme: BrandCardTheme.cream,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_errorMessage != null) _buildError(),
                                  _buildStepContent(),
                                  const SizedBox(height: 32),
                                  _buildNavigationButtons(),
                                ],
                              ),
                            ),
                          )
                          .animate(target: _validateStep() ? 1 : 0)
                          .custom(
                            builder: (context, value, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.semanticGreen.withValues(alpha: 0.1 * value,
                                      ),
                                      blurRadius: 20 * value,
                                      spreadRadius: 5 * value,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                          )
                          .shimmer(
                            color: AppColors.semanticGreen.withValues(alpha: 0.1,
                            ),
                            duration: 2.seconds,
                          ),
                      const SizedBox(height: 24),
                      if (_currentStep == 0) _buildFooter(isDark),
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

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_9czpyznt.json',
            fit: BoxFit.contain,
            animate: true,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Step ${_currentStep + 1}: ${_getStepTitle()}",
          style: AppTypography.display.copyWith(
            color: AppColors.gold500,
            fontSize: 24,
          ),
        ).animate(key: ValueKey(_currentStep)).fadeIn().slideY(begin: 0.2),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return "Identity";
      case 1:
        return "Roots";
      case 2:
        return "Path";
      default:
        return "";
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: 300.ms,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: index == _currentStep ? 30 : 12,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold500
                : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIdentityStep();
      case 1:
        return _buildRootsStep();
      case 2:
        return _buildPathStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdentityStep() {
    return Column(
      children: [
        BrandTextField(
          controller: _emailController,
          labelText: "Email Address",
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          showValidation: true,
          isValid: _emailController.text.contains('@'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        BrandTextField(
          controller: _passwordController,
          labelText: "Password",
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          showValidation: true,
          isValid: _passwordController.text.length >= 6,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        BrandTextField(
          controller: _confirmPasswordController,
          labelText: "Confirm Password",
          prefixIcon: Icons.lock_clock_outlined,
          isPassword: true,
          showValidation: true,
          isValid:
              _confirmPasswordController.text.isNotEmpty &&
              _confirmPasswordController.text == _passwordController.text,
          onChanged: (_) => setState(() {}),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildRootsStep() {
    return Column(
      children: [
        BrandTextField(
          controller: _usernameController,
          labelText: "Display Name",
          prefixIcon: Icons.person_outline,
          showValidation: true,
          isValid: _usernameController.text.length >= 3,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        BrandTextField(
          controller: _locationController,
          labelText: "Location",
          prefixIcon: Icons.location_on_outlined,
          showValidation: true,
          isValid: _locationController.text.isNotEmpty,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        BrandTextField(
          controller: _tribeController,
          labelText: "Tribe Interest",
          prefixIcon: Icons.people_outline,
          showValidation: true,
          isValid: _tribeController.text.isNotEmpty,
          onChanged: (_) => setState(() {}),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildPathStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandTextField(
          controller: _nativeLanguageController,
          labelText: "Native Language",
          prefixIcon: Icons.translate,
          showValidation: true,
          isValid: _nativeLanguageController.text.isNotEmpty,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Text(
          "Learning Goal",
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.white : AppColors.forest700,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _goals.map((goal) {
            final isSelected = _learningGoal == goal;
            return ChoiceChip(
              label: Text(goal),
              selected: isSelected,
              onSelected: (val) => setState(() => _learningGoal = goal),
              selectedColor: AppColors.gold500,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.forest900
                    : (isDark ? Colors.white : AppColors.forest500),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          "Tribal Totem",
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.white : AppColors.forest700,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTotemGrid(),
      ],
    ).animate().fadeIn();
  }

  Widget _buildTotemGrid() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _totems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, index) {
          final totem = _totems[index];
          final isSelected = _selectedAvatar == totem;
          return GestureDetector(
            onTap: () => setState(() => _selectedAvatar = totem),
            child: AnimatedContainer(
              duration: 200.ms,
              width: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold500
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.gold600 : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold500.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(totem, style: const TextStyle(fontSize: 28)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: BrandButton(
                text: "Back",
                type: BrandButtonType.secondary,
                onTap: _prevStep,
              ),
            ),
          ),
        Expanded(
          child: BrandButton(
            text: _currentStep < 2
                ? "Continue"
                : (_isLoading ? "Creating..." : "Finish"),
            type: BrandButtonType.primary,
            onTap: _currentStep < 2
                ? _nextStep
                : (_isLoading ? null : _handleSignup),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.creamText2 : AppColors.creamText3,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/login'),
          child: Text(
            "Sign In",
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




import 'dart:async';
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
import '../services/haptic_service.dart';
import '../widgets/parallax_background.dart';

import '../widgets/assessment_overlay.dart';
import '../models/assessment.dart';
import '../utils/app_localization.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  Map<String, dynamic> _assessmentAnswers = {};

  List<AssessmentQuestion> _getPreTestQuestions(AppLocalization l10n) => [
    AssessmentQuestion(
      id: 'heritage',
      text: l10n.translate('connection_lumad'),
      options: [
        l10n.translate('heritage_learner'),
        l10n.translate('l2_learner'),
        l10n.translate('researcher_educator'),
        l10n.translate('curious_culture')
      ],
    ),
    AssessmentQuestion(
      id: 'exposure',
      text: l10n.translate('exposure_question'),
      options: [
        l10n.translate('daily'),
        l10n.translate('occasionally'),
        l10n.translate('rarely'),
        l10n.translate('never')
      ],
    ),
    AssessmentQuestion(
      id: 'goal',
      text: l10n.translate('goal_question'),
      options: [
        l10n.translate('fluent_goal'),
        l10n.translate('elders_goal'),
        l10n.translate('preserve_goal'),
        l10n.translate('assessment_goal')
      ],
    ),
  ];

  // Step 0: Identity
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 1: Roots
  final _usernameController = TextEditingController();
  final _villageCodeController = TextEditingController();
  String? _selectedProvince;
  String? _selectedMunicipality;

  final Map<String, List<String>> _regionData = {
    'Davao del Sur': [
      'Davao City',
      'Digos City',
      'Santa Cruz',
      'Bansalan',
      'Hagonoy',
      'Magsaysay',
      'Matanao',
      'Padada',
      'Santa Maria',
      'Sulop',
    ],
    'Davao del Norte': [
      'Tagum City',
      'Panabo City',
      'Island Garden City of Samal',
      'Carmen',
      'Kapalong',
      'New Corella',
      'Santo Tomas',
      'Talaingod',
    ],
    'Davao de Oro': [
      'Nabunturan',
      'Compostela',
      'Laak',
      'Mabini',
      'Maco',
      'Maragusan',
      'Mawab',
      'Monkayo',
      'Montevista',
      'Pantukan',
    ],
    'Davao Oriental': [
      'Mati City',
      'Baganga',
      'Banaybanay',
      'Boston',
      'Caraga',
      'Cateel',
      'Lupon',
      'Manay',
      'San Isidro',
      'Tarragona',
    ],
    'Davao Occidental': [
      'Malita',
      'Don Marcelino',
      'Jose Abad Santos',
      'Sarangani',
      'Santa Maria',
    ],
  };

  // Step 2: Path
  String? _selectedNativeLanguage;
  final List<String> _nativeLanguages = [
    'Mansaka',
    'Other'
  ];

  String _learningGoal = "Culture";
  final List<String> _goals = [
    "Culture",
    "Travel",
    "Ancestry",
    "Community",
    "Research",
  ];

  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _detectedInvite;
  Timer? _debounceTimer;

  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final _emailFocusNode = FocusNode();
  bool _emailTouched = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && !_emailTouched) {
        setState(() => _emailTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailFocusNode.dispose();
    _usernameController.dispose();
    _villageCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    _debounceTimer?.cancel();
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      if (_detectedInvite != null) {
        setState(() => _detectedInvite = null);
      }
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkForInvitation();
    });
  }

  Future<void> _checkForInvitation() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      if (_detectedInvite != null) setState(() => _detectedInvite = null);
      return;
    }

    try {
      final snap = await ref
          .read(authServiceProvider)
          .firestore
          .collection('invitations')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        if (_detectedInvite == null || _detectedInvite!['role'] != data['role']) {
          setState(() => _detectedInvite = data);
        }
      } else {
        if (_detectedInvite != null) setState(() => _detectedInvite = null);
      }
    } catch (e) {
      // Silent fail for background check
    }
  }

  bool get _isValidatorInvite => _detectedInvite?['role'] == 'validator';

  int get _totalSteps => _isValidatorInvite ? 3 : 4;
  int get _assessmentStepIndex => _isValidatorInvite ? 2 : 3;

  bool _validateStep() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return false;
    }

    if (_currentStep == 0) {
      return _emailRegex.hasMatch(_emailController.text.trim()) &&
          _passwordController.text.length >= 6 &&
          _passwordController.text == _confirmPasswordController.text;
    } else if (_currentStep == 1) {
      final baseValid = _usernameController.text.length >= 3 &&
          _selectedProvince != null &&
          _selectedMunicipality != null;
      if (_isValidatorInvite) {
        return baseValid && _acceptedTerms;
      }
      return baseValid;
    } else if (_currentStep == 2 && !_isValidatorInvite) {
      return _selectedNativeLanguage != null && _acceptedTerms;
    }
    return true;
  }

  Future<void> _nextStep() async {
    if (_validateStep()) {
      if (_currentStep == 0) {
        _debounceTimer?.cancel();
        await _checkForInvitation();
      }
      HapticService.navigation();
      if (mounted) {
        setState(() {
          _currentStep++;
          _errorMessage = null;
        });
      }
    } else {
      HapticService.error();
      setState(() => _errorMessage = "Please fill all fields correctly");
    }
  }

  void _prevStep() {
    HapticService.navigation();
    setState(() {
      _currentStep--;
      _errorMessage = null;
    });
  }

  Future<void> _handleSignup() async {
    if (!_validateStep()) {
      setState(() => _errorMessage = "Please complete all fields and accept the Terms");
      return;
    }

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
            location: "$_selectedMunicipality, $_selectedProvince",
            tribe: "Learner", // Defaulting since tribe interest was removed
            avatar: "👤", // Defaulting since totem was removed
            nativeLanguage: _selectedNativeLanguage ?? "Unknown",
            learningGoal: _learningGoal,
            assessment: _assessmentAnswers,
            villageCode: _villageCodeController.text.trim(),
          );
      if (mounted) {
        setState(() => _isLoading = false);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 48.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      _buildHeader(l10n),
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
                                  _buildStepContent(l10n),
                                  const SizedBox(height: 32),
                                  _buildNavigationButtons(l10n),
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
                      if (_currentStep == 0) _buildFooter(isDark, l10n),
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

  Widget _buildHeader(AppLocalization l10n) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Lottie.network(
            'https://lottie.host/80164c01-70e6-4914-8742-df2a16d55283/jOn7mB2J9T.json',
            fit: BoxFit.contain,
            animate: true,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.fingerprint_rounded,
              size: 80,
              color: AppColors.gold500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "${l10n.translate('step')} ${_currentStep + 1}: ${_getStepTitle(l10n)}",
          style: AppTypography.display.copyWith(
            color: AppColors.gold500,
            fontSize: 24,
          ),
        ).animate(key: ValueKey(_currentStep)).fadeIn().slideY(begin: 0.2),
      ],
    );
  }

  String _getStepTitle(AppLocalization l10n) {
    if (_currentStep == _assessmentStepIndex) return l10n.translate('ritual');
    switch (_currentStep) {
      case 0:
        return l10n.translate('identity');
      case 1:
        return l10n.translate('roots');
      case 2:
        return l10n.translate('path');
      default:
        return "";
    }
  }

  Widget _buildStepIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        final isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: 300.ms,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: index == _currentStep ? 30 : 12,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold500
                : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1)),
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

  Widget _buildStepContent(AppLocalization l10n) {
    if (_currentStep == _assessmentStepIndex) return _buildAssessmentStep(l10n);
    switch (_currentStep) {
      case 0:
        return _buildIdentityStep(l10n);
      case 1:
        return _buildRootsStep(l10n);
      case 2:
        return _buildPathStep(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAssessmentStep(AppLocalization l10n) {
    return Column(
      children: [
        AssessmentOverlay(
          type: AssessmentType.preTest,
          questions: _getPreTestQuestions(l10n),
          onComplete: (answers) {
            setState(() {
              _assessmentAnswers = answers;
            });
            _handleSignup();
          },
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildIdentityStep(AppLocalization l10n) {
    return AutofillGroup(
      child: Column(
        children: [
          BrandTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            labelText: l10n.translate('email_address'),
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            showValidation: true,
            isValid: _emailRegex.hasMatch(_emailController.text.trim()),
            errorText: _emailTouched && _emailController.text.isNotEmpty && !_emailRegex.hasMatch(_emailController.text.trim())
                ? l10n.translate('valid_email')
                : null,
            onChanged: (_) => setState(() {}),
          ),
          if (_detectedInvite != null) _buildInviteBanner(l10n),
          const SizedBox(height: 16),
          BrandTextField(
            controller: _passwordController,
            labelText: l10n.translate('password'),
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            showValidation: true,
            isValid: _passwordController.text.length >= 6,
            errorText: _passwordController.text.isNotEmpty && _passwordController.text.length < 6
                ? l10n.translate('password_length')
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          BrandTextField(
            controller: _confirmPasswordController,
            labelText: l10n.translate('confirm_password'),
            prefixIcon: Icons.lock_clock_outlined,
            isPassword: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            showValidation: true,
            isValid:
                _confirmPasswordController.text.isNotEmpty &&
                _confirmPasswordController.text == _passwordController.text,
            errorText: _confirmPasswordController.text.isNotEmpty &&
                    _confirmPasswordController.text != _passwordController.text
                ? l10n.translate('passwords_dont_match')
                : null,
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _nextStep(),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.translate('or'),
                style: AppTypography.label.copyWith(color: Colors.black26, fontSize: 10),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            icon: Image.asset(
              'assets/images/google_logo.png',
              height: 20,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.account_circle_outlined, color: Colors.blue),
            ),
            label: Text(
              l10n.translate('quick_join_google'),
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
          ),
        ),
      ],
    ),
    ).animate().fadeIn();
  }

  Widget _buildInviteBanner(AppLocalization l10n) {
    final roleKey = _detectedInvite!['role'] == 'validator' ? 'researcher_staff' : 'tribe_member';
    final roleLabel = l10n.translate(roleKey).toUpperCase();
    final group = _detectedInvite!['indigenousGroup'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.semanticBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.semanticBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.semanticBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('welcome_guest'),
                  style: AppTypography.label.copyWith(
                    color: AppColors.semanticBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
                Text(
                  "${l10n.translate('invited_as')} $roleLabel${group != null ? ' ${l10n.translate('for')} $group' : ''}.",
                  style: AppTypography.body.copyWith(
                    color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildRootsStep(AppLocalization l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandTextField(
          controller: _usernameController,
          labelText: l10n.translate('display_name'),
          prefixIcon: Icons.person_outline,
          showValidation: true,
          isValid: _usernameController.text.length >= 3,
          errorText: _usernameController.text.isNotEmpty && _usernameController.text.length < 3
              ? l10n.translate('tribe_name_length')
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.translate('province'),
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedProvince,
          hint: l10n.translate('select_province'),
          items: _regionData.keys.toList(),
          onChanged: (val) {
            setState(() {
              _selectedProvince = val;
              _selectedMunicipality = null;
            });
          },
        ),
        const SizedBox(height: 16),
        Text(
          l10n.translate('municipality'),
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedMunicipality,
          hint: l10n.translate('select_municipality'),
          items: _selectedProvince != null ? _regionData[_selectedProvince]! : [],
          onChanged: (val) {
            setState(() {
              _selectedMunicipality = val;
            });
          },
        ),
        const SizedBox(height: 24),
        BrandTextField(
          controller: _villageCodeController,
          labelText: l10n.translate('village_code_optional'),
          prefixIcon: Icons.fort_rounded,
          onChanged: (_) => setState(() {}),
        ),
        Text(
          l10n.translate('village_code_hint'),
          style: AppTypography.label.copyWith(
            color: isDark ? Colors.white24 : AppColors.forest900.withValues(alpha: 0.3),
            fontSize: 9,
          ),
        ),
        if (_isValidatorInvite) ...[
          const SizedBox(height: 24),
          _buildTermsCheckbox(l10n),
        ],
      ],
    ).animate().fadeIn();
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
              fontSize: 14,
            ),
          ),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.gold500,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPathStep(AppLocalization l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Native Language",
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedNativeLanguage,
          hint: "Select Native Language",
          items: _nativeLanguages,
          onChanged: (val) {
            setState(() {
              _selectedNativeLanguage = val;
            });
          },
        ),
        const SizedBox(height: 24),
        Text(
          l10n.translate('learning_goal'),
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
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
              label: Text(l10n.translate(goal.toLowerCase())),
              selected: isSelected,
              onSelected: (val) {
            HapticService.selection();
            setState(() => _learningGoal = goal);
          },
              selectedColor: AppColors.gold500,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.forest900
                    : Theme.of(context).colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildTermsCheckbox(l10n),
      ],
    ).animate().fadeIn();
  }

  Widget _buildTermsCheckbox(AppLocalization l10n) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (val) {
            HapticService.selection();
            setState(() => _acceptedTerms = val ?? false);
          },
            activeColor: AppColors.gold500,
            checkColor: AppColors.forest900,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: "${l10n.translate('agree_to')} ",
              style: AppTypography.body.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => _showLegalDialog(
                      l10n.translate('terms_conditions'),
                      l10n.translate('legal_mansaka'),
                      l10n,
                    ),
                    child: Text(
                      l10n.translate('terms'),
                      style: const TextStyle(
                        color: AppColors.gold500,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: " ${l10n.translate('and')} "),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => _showLegalDialog(
                      l10n.translate('privacy_policy'),
                      l10n.translate('legal_privacy'),
                      l10n,
                    ),
                    child: Text(
                      l10n.translate('privacy_policy'),
                      style: const TextStyle(
                        color: AppColors.gold500,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLegalDialog(String title, String content, AppLocalization l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.forest900 : AppColors.creamBg,
        title: Text(
          title,
          style: AppTypography.display.copyWith(
            color: isDark ? AppColors.gold500 : AppColors.gold700,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white70 : AppColors.forest900.withValues(alpha: 0.7),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              l10n.translate('close'),
              style: TextStyle(color: isDark ? AppColors.gold500 : AppColors.gold700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AppLocalization l10n) {
    final isFormLastStep = _isValidatorInvite ? _currentStep == 1 : _currentStep == 2;
    final isAssessmentStep = _currentStep == _assessmentStepIndex;

    if (isAssessmentStep) return const SizedBox.shrink();

    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: BrandButton(
                text: l10n.translate('back'),
                type: BrandButtonType.secondary,
                onTap: _prevStep,
              ),
            ),
          ),
        Expanded(
          child: BrandButton(
            text: _isLoading
                ? l10n.translate('waiting')
                : (!isFormLastStep ? l10n.translate('continue') : l10n.translate('next_ritual')),
            type: BrandButtonType.primary,
            onTap: _isLoading ? null : _nextStep,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark, AppLocalization l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.translate('already_have_account'),
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticService.selection();
            context.push('/login');
          },
          child: Text(
            l10n.translate('sign_in'),
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

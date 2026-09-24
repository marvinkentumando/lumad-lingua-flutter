enum PasswordStrength {
  weak,
  fair,
  strong,
}

class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  bool get isStrong =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialChar;

  int get metCriteriaCount {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigit) count++;
    if (hasSpecialChar) count++;
    return count;
  }

  PasswordStrength get strength {
    final count = metCriteriaCount;
    if (count == 5) {
      return PasswordStrength.strong;
    } else if (count >= 3) {
      return PasswordStrength.fair;
    } else {
      return PasswordStrength.weak;
    }
  }
}

class PasswordValidator {
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/]');

  static PasswordValidationResult validate(String password) {
    return PasswordValidationResult(
      hasMinLength: password.length >= 8,
      hasUppercase: _uppercaseRegex.hasMatch(password),
      hasLowercase: _lowercaseRegex.hasMatch(password),
      hasDigit: _digitRegex.hasMatch(password),
      hasSpecialChar: _specialCharRegex.hasMatch(password),
    );
  }
}

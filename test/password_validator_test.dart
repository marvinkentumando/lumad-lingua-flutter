import 'package:flutter_test/flutter_test.dart';
import 'package:lumad_lingua/utils/password_validator.dart';

void main() {
  group('PasswordValidator Tests', () {
    test('Empty password should be weak and invalid', () {
      final result = PasswordValidator.validate('');
      expect(result.hasMinLength, false);
      expect(result.hasUppercase, false);
      expect(result.hasLowercase, false);
      expect(result.hasDigit, false);
      expect(result.hasSpecialChar, false);
      expect(result.isStrong, false);
      expect(result.strength, PasswordStrength.weak);
    });

    test('Password failing min length requirement', () {
      final result = PasswordValidator.validate('A1#a');
      expect(result.hasMinLength, false);
      expect(result.hasUppercase, true);
      expect(result.hasLowercase, true);
      expect(result.hasDigit, true);
      expect(result.hasSpecialChar, true);
      expect(result.isStrong, false);
      expect(result.strength, PasswordStrength.fair);
    });

    test('Password missing uppercase', () {
      final result = PasswordValidator.validate('abc12345!');
      expect(result.hasUppercase, false);
      expect(result.hasLowercase, true);
      expect(result.hasDigit, true);
      expect(result.hasSpecialChar, true);
      expect(result.hasMinLength, true);
      expect(result.isStrong, false);
    });

    test('Password missing special character', () {
      final result = PasswordValidator.validate('Abc12345');
      expect(result.hasSpecialChar, false);
      expect(result.isStrong, false);
    });

    test('Valid strong password satisfying all 5 criteria', () {
      final result = PasswordValidator.validate('LumadLingua2025!');
      expect(result.hasMinLength, true);
      expect(result.hasUppercase, true);
      expect(result.hasLowercase, true);
      expect(result.hasDigit, true);
      expect(result.hasSpecialChar, true);
      expect(result.isStrong, true);
      expect(result.strength, PasswordStrength.strong);
    });
  });
}

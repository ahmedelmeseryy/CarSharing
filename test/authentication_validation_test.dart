import 'package:flutter_test/flutter_test.dart';
import 'package:email_validator/email_validator.dart';

void main() {
  group('Email Validation', () {
    test('valid email addresses', () {
      expect(EmailValidator.validate('test@example.com'), true);
      expect(EmailValidator.validate('user.name@domain.co.uk'), true);
      expect(EmailValidator.validate('user+tag@example.com'), true);
    });

    test('invalid email addresses', () {
      expect(EmailValidator.validate('test@'), false);
      expect(EmailValidator.validate('test@example'), false);
      expect(EmailValidator.validate('test.example.com'), false);
      expect(EmailValidator.validate(''), false);
    });
  });

  group('Password Validation', () {
    test('matching passwords', () {
      const password = 'Test123!@#';
      const repeatPassword = 'Test123!@#';
      expect(password == repeatPassword, true);
    });

    test('non-matching passwords', () {
      const password = 'Test123!@#';
      const repeatPassword = 'Test123!@#different';
      expect(password == repeatPassword, false);
    });
  });
} 
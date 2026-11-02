import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/core/utils/security_utils.dart';
import 'package:academy_management/core/utils/validators.dart';

void main() {
  group('Production Login & Credential Rules Verification', () {
    test('Roll number validator enforces strict 6-digit roll numbers', () {
      // 6 digits (production standard format)
      expect(Validators.rollNumber('100001'), isNull);
      expect(Validators.rollNumber('999999'), isNull);
      expect(Validators.rollNumber('200005'), isNull);

      // Non-6-digit roll numbers
      expect(Validators.rollNumber(''), isNotNull);
      expect(Validators.rollNumber('10001'), 'Roll number must be 6 digits');
      expect(Validators.rollNumber('123'), 'Roll number must be 6 digits');
      expect(Validators.rollNumber('1234'), 'Roll number must be 6 digits');
      expect(Validators.rollNumber('1234567'), 'Roll number must be 6 digits');
      expect(Validators.rollNumber('ABC123'), 'Roll number must contain digits only');
    });

    test('Staff password hashing and verification', () {
      const plainPassword = 'StaffPass@2026';
      final hashed = SecurityUtils.hashPassword(plainPassword);

      expect(hashed, isNotEmpty);
      expect(hashed, isNot(equals(plainPassword)));

      // Verifies correct password
      expect(SecurityUtils.verifyPassword(plainPassword, hashed), isTrue);

      // Verifies wrong password fails
      expect(SecurityUtils.verifyPassword('WrongPass', hashed), isFalse);
      expect(SecurityUtils.verifyPassword('', hashed), isFalse);
    });

    test('Student PIN hashing and verification', () {
      const plainPin = '1234';
      final hashed = SecurityUtils.hashPin(plainPin);

      expect(hashed, isNotEmpty);
      expect(hashed, isNot(equals(plainPin)));

      // Verifies correct PIN
      expect(SecurityUtils.verifyPin(plainPin, hashed), isTrue);

      // Verifies wrong PIN fails
      expect(SecurityUtils.verifyPin('0000', hashed), isFalse);
      expect(SecurityUtils.verifyPin('4321', hashed), isFalse);
      expect(SecurityUtils.verifyPin('', hashed), isFalse);
    });
  });
}

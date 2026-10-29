import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/core/utils/currency.dart';
import 'package:academy_management/core/utils/validators.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats PKR integer amounts', () {
      expect(CurrencyFormatter.pkr(25000), 'Rs. 25,000');
      expect(CurrencyFormatter.pkr(0), 'Rs. 0');
    });

    test('formats PKR decimal amounts', () {
      expect(CurrencyFormatter.pkrDecimal(25000), 'Rs. 25,000.00');
      expect(CurrencyFormatter.pkrDecimal(1234.5), 'Rs. 1,234.50');
    });
  });

  group('Validators', () {
    test('rejects invalid emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('admin@academy.com'), isNull);
    });

    test('validates six digit roll numbers', () {
      expect(Validators.rollNumber('100001'), isNull);
      expect(Validators.rollNumber('12345'), isNotNull);
      expect(Validators.rollNumber('12A456'), isNotNull);
    });

    test('validates four digit PINs', () {
      expect(Validators.pin('4829'), isNull);
      expect(Validators.pin('123'), isNotNull);
      expect(Validators.pin('12345'), isNotNull);
    });
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/core/domain/attendance_calculator.dart';
import 'package:academy_management/core/domain/fee_calculator.dart';
import 'package:academy_management/core/domain/result_calculator.dart';
import 'package:academy_management/core/utils/id_generators.dart';

void main() {
  group('IdGenerators', () {
    test('roll numbers start at 100001 and increment', () {
      expect(IdGenerators.nextRollNumber(0), 100001);
      expect(IdGenerators.nextRollNumber(100001), 100002);
      expect(IdGenerators.nextRollNumber(999999), 999999);
    });

    test('roll number validation accepts six digits in range', () {
      expect(IdGenerators.isValidRollNumber('100001'), isTrue);
      expect(IdGenerators.isValidRollNumber('999999'), isTrue);
      expect(IdGenerators.isValidRollNumber('100000'), isFalse);
      expect(IdGenerators.isValidRollNumber('12345'), isFalse);
      expect(IdGenerators.isValidRollNumber('12A456'), isFalse);
    });

    test('PINs are always four digits', () {
      final pin = IdGenerators.generatePin(Random(42));
      expect(pin, hasLength(4));
      expect(int.tryParse(pin), isNotNull);
    });

    test('academy codes follow the expected format', () {
      final code = IdGenerators.generateAcademyCode(Random(1));
      expect(code, startsWith('ACD-'));
      expect(code.length, 9);
    });
  });

  group('FeeCalculator', () {
    test('computes invoice total with fine, discount and scholarship', () {
      expect(
        FeeCalculator.invoiceTotal(
          baseAmount: 5000,
          fine: 200,
          discount: 100,
          scholarship: 300,
        ),
        4800,
      );
    });

    test('clamps totals at zero', () {
      expect(FeeCalculator.invoiceTotal(baseAmount: 100, discount: 500), 0);
    });

    test('computes outstanding and settlement', () {
      expect(FeeCalculator.outstanding(5000, 2000), 3000);
      expect(FeeCalculator.isSettled(5000, 5000), isTrue);
      expect(FeeCalculator.isSettled(5000, 4999.5), isFalse);
    });
  });

  group('ResultCalculator', () {
    test('computes percentage', () {
      expect(ResultCalculator.percentage(45, 50), 90);
      expect(ResultCalculator.percentage(0, 0), 0);
    });

    test('assigns grades from the default scale', () {
      expect(ResultCalculator.gradeFor(85).label, 'A+');
      expect(ResultCalculator.gradeFor(75).label, 'A');
      expect(ResultCalculator.gradeFor(35).label, 'F');
      expect(ResultCalculator.gradeFor(35).passed, isFalse);
      expect(ResultCalculator.gradeFor(60).passed, isTrue);
    });
  });

  group('AttendanceCalculator', () {
    test('computes attendance percentage', () {
      expect(
        AttendanceCalculator.percentage(presentDays: 18, totalDays: 20),
        90,
      );
      expect(AttendanceCalculator.percentage(presentDays: 0, totalDays: 0), 0);
    });

    test('counts statuses', () {
      final counts = AttendanceCalculator.count([
        AttendanceStatus.present,
        AttendanceStatus.absent,
        AttendanceStatus.late,
        AttendanceStatus.present,
      ]);
      expect(counts[AttendanceStatus.present], 2);
      expect(counts[AttendanceStatus.absent], 1);
      expect(counts[AttendanceStatus.late], 1);
      expect(counts[AttendanceStatus.leave], 0);
    });
  });
}

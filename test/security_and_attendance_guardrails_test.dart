import 'package:academy_management/core/domain/attendance_calculator.dart';
import 'package:academy_management/core/utils/security_utils.dart';
import 'package:academy_management/features/attendance/data/firestore_attendance_repository.dart';
import 'package:academy_management/features/attendance/domain/attendance_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: subtype_of_sealed_class
class _FakeCollectionReference implements CollectionReference<Map<String, dynamic>> {
  final Map<String, Map<String, dynamic>> docs = {};

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return _FakeDocumentReference(path ?? 'auto_id', this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.id, this.fakeCollection);
  @override
  final String id;
  final _FakeCollectionReference fakeCollection;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    fakeCollection.docs[id] = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirestore implements FirebaseFirestore {
  final Map<String, _FakeCollectionReference> collections = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return collections.putIfAbsent(path, () => _FakeCollectionReference());
  }

  @override
  WriteBatch batch() => _FakeWriteBatch();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWriteBatch implements WriteBatch {
  final List<void Function()> operations = [];

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    operations.add(() {
      (document as _FakeDocumentReference).set(data as Map<String, dynamic>, options);
    });
  }

  @override
  Future<void> commit() async {
    for (final op in operations) {
      op();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Security Guardrails - Password & PIN Hashing Tests', () {
    test('1. SecurityUtils.hashPassword hashes plain text into a non-plain-text salted SHA-256 string', () {
      const plainPassword = 'Staff@Password123';
      final hash = SecurityUtils.hashPassword(plainPassword);

      expect(hash, isNotEmpty);
      expect(hash, isNot(equals(plainPassword)));
      // SHA-256 hex string is 64 characters
      expect(hash.length, equals(64));
      // Same input produces consistent hash
      expect(SecurityUtils.hashPassword(plainPassword), equals(hash));
    });

    test('2. SecurityUtils.verifyPassword correctly verifies valid and invalid passwords', () {
      const plainPassword = 'Staff@Password123';
      final hash = SecurityUtils.hashPassword(plainPassword);

      expect(SecurityUtils.verifyPassword(plainPassword, hash), isTrue);
      expect(SecurityUtils.verifyPassword('WrongPassword', hash), isFalse);
      expect(SecurityUtils.verifyPassword('', hash), isFalse);
    });

    test('3. SecurityUtils.verifyPassword backward compatibility with legacy plain-text records', () {
      const legacyPlainStored = 'Staff@Legacy2024';

      expect(SecurityUtils.verifyPassword('Staff@Legacy2024', legacyPlainStored), isTrue);
      expect(SecurityUtils.verifyPassword('Incorrect', legacyPlainStored), isFalse);
    });

    test('4. SecurityUtils.hashPin and verifyPin correctly hashes 4-digit student PINs', () {
      const plainPin = '1234';
      final hash = SecurityUtils.hashPin(plainPin);

      expect(hash, isNotEmpty);
      expect(hash, isNot(equals(plainPin)));
      expect(hash.length, equals(64));
      expect(SecurityUtils.verifyPin('1234', hash), isTrue);
      expect(SecurityUtils.verifyPin('9999', hash), isFalse);
    });

    test('5. SecurityUtils.verifyPin backward compatibility with legacy plain-text student PINs', () {
      expect(SecurityUtils.verifyPin('1234', '1234'), isTrue);
      expect(SecurityUtils.verifyPin('0000', '1234'), isFalse);
    });
  });

  group('Attendance Advance Guardrail Tests', () {
    late _FakeFirestore fakeFirestore;
    late FirestoreAttendanceRepository attendanceRepo;

    setUp(() {
      fakeFirestore = _FakeFirestore();
      attendanceRepo = FirestoreAttendanceRepository(fakeFirestore);
    });

    test('1. markAttendance for past or current date succeeds', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final recordToday = AttendanceRecord(
        id: 'rec_today',
        academyId: 'acad_1',
        studentId: 'stu_1',
        courseId: 'crs_1',
        date: today,
        status: AttendanceStatus.present,
      );

      final recordYesterday = AttendanceRecord(
        id: 'rec_yesterday',
        academyId: 'acad_1',
        studentId: 'stu_2',
        courseId: 'crs_1',
        date: yesterday,
        status: AttendanceStatus.late,
      );

      await expectLater(attendanceRepo.markAttendance(recordToday), completes);
      await expectLater(attendanceRepo.markAttendance(recordYesterday), completes);
    });

    test('2. markAttendance for tomorrow or future date throws ArgumentError', () async {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      final nextWeek = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));

      final recordTomorrow = AttendanceRecord(
        id: 'rec_tomorrow',
        academyId: 'acad_1',
        studentId: 'stu_1',
        courseId: 'crs_1',
        date: tomorrow,
        status: AttendanceStatus.present,
      );

      final recordNextWeek = AttendanceRecord(
        id: 'rec_next_week',
        academyId: 'acad_1',
        studentId: 'stu_2',
        courseId: 'crs_1',
        date: nextWeek,
        status: AttendanceStatus.present,
      );

      expect(
        () => attendanceRepo.markAttendance(recordTomorrow),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Attendance cannot be recorded in advance for future dates'),
        )),
      );

      expect(
        () => attendanceRepo.markAttendance(recordNextWeek),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Attendance cannot be recorded in advance for future dates'),
        )),
      );
    });

    test('3. markBatchAttendance throws ArgumentError if any record has a future date', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final records = [
        AttendanceRecord(
          id: 'rec_1',
          academyId: 'acad_1',
          studentId: 'stu_1',
          date: today,
          status: AttendanceStatus.present,
        ),
        AttendanceRecord(
          id: 'rec_2',
          academyId: 'acad_1',
          studentId: 'stu_2',
          date: tomorrow,
          status: AttendanceStatus.present,
        ),
      ];

      expect(
        () => attendanceRepo.markBatchAttendance(records),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

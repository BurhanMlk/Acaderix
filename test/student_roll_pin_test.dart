import 'package:academy_management/core/utils/id_generators.dart';
import 'package:academy_management/features/academy_admin/application/academy_access_provider.dart';
import 'package:academy_management/features/academy_admin/application/academy_admin_providers.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_models.dart';
import 'package:academy_management/features/admissions/application/student_repository_provider.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/admissions/domain/student_repository.dart';
import 'package:academy_management/features/admissions/presentation/screens/add_student_screen.dart';
import 'package:academy_management/features/admissions/presentation/widgets/reset_student_pin_dialog.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/shared/current_academy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestStudentRepo implements StudentRepository {
  final List<Student> students = [
    const Student(
      id: 'stu_1',
      academyId: 'acad_1',
      fullName: 'Existing Student',
      rollNumber: '100001',
      status: 'active',
    ),
  ];

  String? lastResetStudentId;
  String? lastResetPin;

  @override
  Stream<List<Student>> watchAll(String academyId) => Stream.value(students);

  @override
  Future<Student?> getById(String academyId, String studentId) async =>
      students.where((s) => s.id == studentId).firstOrNull;

  @override
  Future<String> allocateRollNumber(String academyId) async => '100002';

  @override
  Future<bool> isRollNumberTaken(String academyId, String rollNumber) async =>
      students.any((s) => s.rollNumber.trim() == rollNumber.trim());

  @override
  Future<void> resetPin(
    String academyId,
    String studentId,
    String newPin,
  ) async {
    lastResetStudentId = studentId;
    lastResetPin = newPin;
  }

  @override
  Future<void> create(Student student) async {
    if (await isRollNumberTaken(student.academyId, student.rollNumber)) {
      throw StateError(
        'Roll number "${student.rollNumber}" is already assigned to another student.',
      );
    }
    students.add(student);
  }

  @override
  Future<void> update(Student student) async {}

  @override
  Future<void> delete(String academyId, String studentId) async {}
}

void main() {
  testWidgets(
    'AddStudentScreen requires explicit roll number & PIN, supports PIN generator, and rejects duplicate roll numbers',
    (tester) async {
      final repo = _TestStudentRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue('acad_1'),
            studentRepositoryProvider.overrideWithValue(repo),
            studentsStreamProvider('acad_1').overrideWith(
              (ref) => Stream.value(repo.students),
            ),
            branchesStreamProvider('acad_1').overrideWith(
              (ref) => Stream.value(const <Branch>[]),
            ),
            academyAccessProvider.overrideWith(
              (ref) => Stream.value(
                const AcademyAccessInfo(
                  state: AcademyAccessState.active,
                  academyId: 'acad_1',
                  maxStudents: 200,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: AddStudentScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Roll number and Login PIN fields + Generate Random PIN chip exist
      expect(find.text('Roll number (6 digits)'), findsOneWidget);
      expect(find.text('Login PIN (4 digits)'), findsOneWidget);
      expect(find.text('Generate Random PIN'), findsOneWidget);

      // Tap Generate Random PIN and verify a 4-digit PIN is populated
      await tester.tap(find.text('Generate Random PIN'));
      await tester.pump();

      final pinField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Login PIN (4 digits)'),
      );
      final generatedPin = pinField.controller!.text;
      expect(RegExp(r'^\d{4}$').hasMatch(generatedPin), isTrue);

      // Fill required fields with duplicate roll number '100001'
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'),
        'New Student',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Roll number (6 digits)'),
        '100001',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, "Father's name"),
        'Father Name',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Guardian phone'),
        '03001234567',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Academic session'),
        '2026-2027',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Class'),
        'Class 10',
      );

      await tester.scrollUntilVisible(
        find.text('Admit Student'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Admit Student'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Duplicate roll number should be rejected
      expect(repo.students.length, 1);
      expect(
        find.textContaining('already assigned'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Roll number (6 digits)'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );

      // Enter unique roll number '100002' and submit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Roll number (6 digits)'),
        '100002',
      );
      await tester.scrollUntilVisible(
        find.text('Admit Student'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Admit Student'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.students.length, 2);
      expect(repo.students.last.rollNumber, '100002');
      expect(repo.lastResetStudentId, repo.students.last.id);
      expect(repo.lastResetPin, generatedPin);
      expect(find.text('Student Credentials'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('showResetStudentPinDialog resets student PIN', (tester) async {
    final repo = _TestStudentRepo();
    final student = repo.students.first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentRepositoryProvider.overrideWithValue(repo),
          studentsStreamProvider('acad_1').overrideWith(
            (ref) => Stream.value(repo.students),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showResetStudentPinDialog(context, ref, student),
                child: const Text('Open Reset'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Student PIN'), findsOneWidget);
    expect(find.text('Generate Random PIN'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'New PIN (4 digits)'),
      '4321',
    );
    await tester.tap(find.text('Save & View Slip'));
    await tester.pumpAndSettle();

    expect(repo.lastResetStudentId, student.id);
    expect(repo.lastResetPin, '4321');
    expect(find.text('PIN Reset Successful'), findsOneWidget);
    expect(find.text('4321'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  });

  test('IdGenerators.generatePin produces 4-digit PINs', () {
    for (var i = 0; i < 20; i++) {
      final pin = IdGenerators.generatePin();
      expect(RegExp(r'^\d{4}$').hasMatch(pin), isTrue);
    }
  });
}

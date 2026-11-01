import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/core/domain/attendance_calculator.dart';
import 'package:academy_management/features/academy_admin/application/academy_access_provider.dart';
import 'package:academy_management/features/academy_admin/application/academy_admin_providers.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_models.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_repository.dart';
import 'package:academy_management/features/academy_admin/presentation/screens/academy_admin_dashboard.dart';
import 'package:academy_management/features/admissions/application/student_repository_provider.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/admissions/domain/student_repository.dart';
import 'package:academy_management/features/admissions/presentation/screens/add_student_screen.dart';
import 'package:academy_management/features/admissions/presentation/screens/edit_student_screen.dart';
import 'package:academy_management/features/admissions/presentation/screens/students_list_screen.dart';
import 'package:academy_management/features/attendance/application/attendance_repository_provider.dart';
import 'package:academy_management/features/attendance/domain/attendance_record.dart';
import 'package:academy_management/features/attendance/domain/attendance_repository.dart';
import 'package:academy_management/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/exams/application/exam_repository_provider.dart';
import 'package:academy_management/features/exams/domain/exam.dart';
import 'package:academy_management/features/exams/domain/exam_result.dart';
import 'package:academy_management/features/exams/domain/exam_repository.dart';
import 'package:academy_management/features/exams/presentation/screens/results_screen.dart';
import 'package:academy_management/features/fees/application/fee_repository_provider.dart';
import 'package:academy_management/features/fees/domain/fee_invoice.dart';
import 'package:academy_management/features/fees/domain/fee_payment.dart';
import 'package:academy_management/features/fees/domain/fee_repository.dart';
import 'package:academy_management/features/fees/presentation/screens/fees_screen.dart';
import 'package:academy_management/features/staff/application/staff_repository_provider.dart';
import 'package:academy_management/features/staff/domain/staff.dart';
import 'package:academy_management/features/staff/domain/staff_repository.dart';
import 'package:academy_management/features/staff/presentation/screens/add_staff_screen.dart';
import 'package:academy_management/features/staff/presentation/screens/edit_staff_screen.dart';
import 'package:academy_management/features/staff/presentation/screens/staff_list_screen.dart';
import 'package:academy_management/features/auth/presentation/screens/staff_login_screen.dart';
import 'package:academy_management/features/branches/application/branch_repository_provider.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/branches/domain/branch_repository.dart';
import 'package:academy_management/features/branches/presentation/screens/add_branch_screen.dart';
import 'package:academy_management/features/branches/presentation/screens/edit_branch_screen.dart';
import 'package:academy_management/features/branches/presentation/screens/branches_list_screen.dart';
import 'package:academy_management/shared/current_academy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Mock Repositories
// ---------------------------------------------------------------------------

class _FakeStudentRepo implements StudentRepository {
  final List<Student> _students = [];
  int _counter = 100000;

  void addStudents(List<Student> students) {
    _students.addAll(students);
  }

  @override
  Stream<List<Student>> watchAll(String academyId) {
    return Stream.value(_students);
  }

  @override
  Future<Student?> getById(String academyId, String studentId) async {
    return _students.where((s) => s.id == studentId).firstOrNull;
  }

  @override
  Future<String> allocateRollNumber(String academyId) async {
    _counter++;
    return _counter.toString();
  }

  @override
  Future<void> create(Student student) async {
    _students.add(student);
  }

  @override
  Future<void> update(Student student) async {
    final idx = _students.indexWhere((s) => s.id == student.id);
    if (idx != -1) {
      _students[idx] = student;
    }
  }

  @override
  Future<void> delete(String academyId, String studentId) async {
    _students.removeWhere((s) => s.id == studentId);
  }
}

class _FakeAttendanceRepo implements AttendanceRepository {
  final List<AttendanceRecord> _records = [];

  void addRecords(List<AttendanceRecord> records) {
    _records.addAll(records);
  }

  @override
  Stream<List<AttendanceRecord>> watchForDate(String academyId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final matching = _records.where((r) {
      return r.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          r.date.isBefore(end);
    }).toList();
    return Stream.value(matching);
  }

  @override
  Future<void> markAttendance(AttendanceRecord record) async {
    final dateStr = record.date.toIso8601String().substring(0, 10);
    _records.removeWhere(
      (r) =>
          r.studentId == record.studentId &&
          r.date.toIso8601String().substring(0, 10) == dateStr,
    );
    _records.add(record);
  }
}

class _FakeFeeRepo implements FeeRepository {
  final List<FeeInvoice> _invoices = [];
  final List<FeePayment> _payments = [];

  void addInvoices(List<FeeInvoice> invoices) {
    _invoices.addAll(invoices);
  }

  @override
  Stream<List<FeeInvoice>> watchInvoices(String academyId, {String? studentId}) {
    return Stream.value(_invoices);
  }

  @override
  Stream<List<FeePayment>> watchPayments(String academyId, {String? studentId}) {
    return Stream.value(_payments);
  }

  @override
  Future<void> createInvoice(FeeInvoice invoice) async {
    _invoices.add(invoice);
  }

  @override
  Future<void> recordPayment(FeePayment payment) async {
    _payments.add(payment);
    final idx = _invoices.indexWhere((i) => i.id == payment.invoiceId);
    if (idx != -1) {
      final inv = _invoices[idx];
      final newPaid = inv.paidAmount + payment.amount;
      _invoices[idx] = inv.copyWith(
        paidAmount: newPaid,
        status: newPaid >= inv.totalAmount ? 'paid' : 'partial',
      );
    }
  }
}

class _FakeExamRepo implements ExamRepository {
  final List<Exam> _exams = [];
  final List<ExamResult> _results = [];

  void addResults(List<ExamResult> results) {
    _results.addAll(results);
  }

  @override
  Stream<List<Exam>> watchExams(String academyId) {
    return Stream.value(_exams);
  }

  @override
  Stream<List<ExamResult>> watchResults(String academyId, {String? studentId}) {
    return Stream.value(_results);
  }

  @override
  Future<void> createExam(Exam exam) async {
    _exams.add(exam);
  }

  @override
  Future<void> saveResult(ExamResult result) async {
    _results.add(result);
  }
}

class _FakeStaffRepo implements StaffRepository {
  final List<Staff> _staff = [];
  int _counter = 1001;

  void addStaff(List<Staff> staff) {
    _staff.addAll(staff);
  }

  @override
  Stream<List<Staff>> watchAll(String academyId) => Stream.value(_staff);

  @override
  Future<String> allocateStaffId(String academyId) async {
    final staffId = 'STF-$_counter';
    _counter++;
    return staffId;
  }

  @override
  Future<void> create(Staff staff) async {
    _staff.add(staff);
  }

  @override
  Future<void> update(Staff staff) async {
    final idx = _staff.indexWhere((s) => s.id == staff.id);
    if (idx != -1) _staff[idx] = staff;
  }

  @override
  Future<void> resetPassword(
    String academyId,
    String staffId,
    String newPassword,
  ) async {
    final idx = _staff.indexWhere((s) => s.staffId == staffId || s.id == staffId);
    if (idx != -1) {
      _staff[idx] = _staff[idx].copyWith(password: newPassword);
    }
  }

  @override
  Future<void> delete(String academyId, String staffId) async {
    _staff.removeWhere((s) => s.id == staffId);
  }
}

class _FakeBranchRepo implements BranchRepository {
  final List<Branch> _branches = [];

  void addBranches(List<Branch> branches) {
    _branches.addAll(branches);
  }

  @override
  Stream<List<Branch>> watchAll(String academyId) => Stream.value(_branches);

  @override
  Future<void> create(Branch branch) async {
    _branches.add(branch);
  }

  @override
  Future<void> update(Branch branch) async {
    final idx = _branches.indexWhere((b) => b.id == branch.id);
    if (idx != -1) _branches[idx] = branch;
  }

  @override
  Future<void> delete(String academyId, String branchId) async {
    _branches.removeWhere((b) => b.id == branchId);
  }
}

class _FakeAccessRepo implements AcademyAccessRepository {
  _FakeAccessRepo(this._info);
  final AcademyAccessInfo _info;

  @override
  Stream<AcademyAccessInfo> watchAcademyAccess(String academyId) =>
      Stream.value(_info);

  @override
  Future<AcademyAccessInfo> getAcademyAccess(String academyId) async => _info;

  @override
  Future<AcademyAccessInfo> findAndCheckAcademyByEmail(String email) async =>
      _info;
}

class _FakeAuthRepo implements AuthRepository {
  String? lastStaffIdentifier;
  String? lastStaffPassword;

  @override
  Stream<AuthState> authStateChanges() async* {
    yield const AuthState.authenticated(
      AppUser(
        id: 'admin_123',
        email: 'admin@acaderix.com',
        role: AppRole.academyAdmin,
        academyId: 'acad_123',
      ),
    );
  }

  @override
  Future<AuthState> currentState() async {
    return const AuthState.authenticated(
      AppUser(
        id: 'admin_123',
        email: 'admin@acaderix.com',
        role: AppRole.academyAdmin,
        academyId: 'acad_123',
      ),
    );
  }

  @override
  Future<AppUser> signInAsStaff({
    required String identifier,
    required String password,
  }) async {
    lastStaffIdentifier = identifier;
    lastStaffPassword = password;
    return const AppUser(
      id: 'staff_1',
      email: 'staff@test.com',
      role: AppRole.staff,
      academyId: 'acad_123',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Seed Data Fixtures
// ---------------------------------------------------------------------------

List<Student> _createSeededStudents(String academyId) {
  return [
    Student(
      id: 'stu_100001',
      academyId: academyId,
      fullName: 'Muhammad Ali',
      fatherName: 'Tariq Ali',
      guardianPhone: '+92 301 2345678',
      guardianRelation: 'Father',
      academicSession: '2026-2027',
      rollNumber: '100001',
      notes: 'Class 10th · Pre-Medical',
      status: 'active',
    ),
    Student(
      id: 'stu_100002',
      academyId: academyId,
      fullName: 'Fatima Zahra',
      fatherName: 'Syed Qasim',
      guardianPhone: '+92 302 3456789',
      guardianRelation: 'Father',
      academicSession: '2026-2027',
      rollNumber: '100002',
      notes: 'Class 10th · Pre-Engineering',
      status: 'active',
    ),
    Student(
      id: 'stu_100003',
      academyId: academyId,
      fullName: 'Hamza Ahmed',
      fatherName: 'Naveed Ahmed',
      guardianPhone: '+92 303 4567890',
      guardianRelation: 'Father',
      academicSession: '2026-2027',
      rollNumber: '100003',
      notes: 'Class 9th · Computer Science',
      status: 'active',
    ),
    Student(
      id: 'stu_100004',
      academyId: academyId,
      fullName: 'Ayesha Khan',
      fatherName: 'Imran Khan',
      guardianPhone: '+92 304 5678901',
      guardianRelation: 'Father',
      academicSession: '2026-2027',
      rollNumber: '100004',
      notes: 'Class 9th · General Science',
      status: 'active',
    ),
    Student(
      id: 'stu_100005',
      academyId: academyId,
      fullName: 'Zayd Bilal',
      fatherName: 'Bilal Farooq',
      guardianPhone: '+92 305 6789012',
      guardianRelation: 'Father',
      academicSession: '2026-2027',
      rollNumber: '100005',
      notes: 'Class 8th · Middle Section',
      status: 'active',
    ),
  ];
}

void main() {
  const testAcademyId = 'acad_123';
  final accessInfo = AcademyAccessInfo(
    state: AcademyAccessState.active,
    academyId: testAcademyId,
    academyName: 'Al-Huda International Academy',
    academyCode: 'ACD-900',
    planName: 'Premium',
    statusReason: 'Active',
  );

  group('Academy Admin End-to-End Features Tests', () {
    testWidgets('1. Students list renders seeded students and filters by search', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final studentRepo = _FakeStudentRepo();
      studentRepo.addStudents(_createSeededStudents(testAcademyId));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            studentsStreamProvider.overrideWith(
              (ref, id) => studentRepo.watchAll(id),
            ),
          ],
          child: const MaterialApp(
            home: StudentsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 students render
      expect(find.text('Muhammad Ali'), findsOneWidget);
      expect(find.text('Fatima Zahra'), findsOneWidget);
      expect(find.text('Hamza Ahmed'), findsOneWidget);
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.text('Zayd Bilal'), findsOneWidget);
      expect(find.textContaining('100001'), findsOneWidget);

      // Search by Name: "Fatima"
      await tester.enterText(find.byType(TextField).first, 'Fatima');
      await tester.pumpAndSettle();

      expect(find.text('Fatima Zahra'), findsOneWidget);
      expect(find.text('Muhammad Ali'), findsNothing);
      expect(find.text('Hamza Ahmed'), findsNothing);

      // Search by Roll Number: "100003"
      await tester.enterText(find.byType(TextField).first, '100003');
      await tester.pumpAndSettle();

      expect(find.text('Hamza Ahmed'), findsOneWidget);
      expect(find.text('Fatima Zahra'), findsNothing);

      // Clear search: all students return
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();

      expect(find.text('Muhammad Ali'), findsOneWidget);
      expect(find.text('Zayd Bilal'), findsOneWidget);
    });

    testWidgets('2. Add student allocates next roll number and creates record', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final studentRepo = _FakeStudentRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            studentRepositoryProvider.overrideWithValue(studentRepo),
          ],
          child: const MaterialApp(
            home: AddStudentScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter student information
      await tester.enterText(find.byType(TextFormField).at(0), 'Bilal Haider');
      await tester.enterText(find.byType(TextFormField).at(1), 'Haider Sultan');
      await tester.enterText(find.byType(TextFormField).at(2), '03001112233');
      await tester.enterText(find.byType(TextFormField).at(3), 'Father');
      await tester.enterText(find.byType(TextFormField).at(4), '2026-2027');
      await tester.enterText(find.byType(TextFormField).at(5), 'Class 10');

      // Submit
      final submitBtn = find.widgetWithText(FilledButton, 'Admit Student');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Credential slip dialog appears with allocated roll number and temporary PIN
      expect(find.text('Student Credentials'), findsOneWidget);
      expect(find.text('100001'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done on the slip dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      // Verify student was added to repo
      expect(studentRepo._students.length, 1);
      expect(studentRepo._students.first.fullName, 'Bilal Haider');
      expect(studentRepo._students.first.rollNumber, '100001');
    });

    testWidgets('3. Attendance screen displays student roster and marks status', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final studentRepo = _FakeStudentRepo();
      studentRepo.addStudents(_createSeededStudents(testAcademyId));
      final attRepo = _FakeAttendanceRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            studentsStreamProvider.overrideWith(
              (ref, id) => studentRepo.watchAll(id),
            ),
            attendanceForDateProvider.overrideWith(
              (ref, args) => attRepo.watchForDate(args.academyId, args.date),
            ),
            attendanceRepositoryProvider.overrideWithValue(attRepo),
          ],
          child: const MaterialApp(
            home: AttendanceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify students appear
      expect(find.text('Muhammad Ali'), findsOneWidget);
      expect(find.text('Fatima Zahra'), findsOneWidget);

      // Find PRESENT choice chips
      final presentChips = find.widgetWithText(ChoiceChip, 'PRESENT');
      expect(presentChips, findsWidgets);

      // Tap Present on the first student
      await tester.tap(presentChips.first);
      await tester.pumpAndSettle();

      // Verify record is saved in fake repo
      expect(attRepo._records.length, 1);
      expect(attRepo._records.first.status, AttendanceStatus.present);
    });

    testWidgets('4. Fees screen renders invoices and allows collecting payment', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final feeRepo = _FakeFeeRepo();
      feeRepo.addInvoices([
        const FeeInvoice(
          id: 'inv_101',
          academyId: testAcademyId,
          studentId: 'stu_100001',
          invoiceNo: 'INV-101',
          title: 'Tuition Fee - October',
          baseAmount: 8000,
          paidAmount: 0,
          status: 'unpaid',
        ),
        const FeeInvoice(
          id: 'inv_102',
          academyId: testAcademyId,
          studentId: 'stu_100002',
          invoiceNo: 'INV-102',
          title: 'Admission Fee',
          baseAmount: 5000,
          paidAmount: 5000,
          status: 'paid',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            invoicesStreamProvider.overrideWith(
              (ref, id) => feeRepo.watchInvoices(id),
            ),
            feeRepositoryProvider.overrideWithValue(feeRepo),
          ],
          child: const MaterialApp(
            home: FeesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify invoice items render
      expect(find.text('Tuition Fee - October'), findsOneWidget);
      expect(find.text('Admission Fee'), findsOneWidget);

      // First invoice is unpaid -> shows 'Collect' button
      final collectBtn = find.widgetWithText(FilledButton, 'Collect');
      expect(collectBtn, findsOneWidget);

      // Second invoice is paid -> shows check circle
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap Collect payment
      await tester.tap(collectBtn);
      await tester.pumpAndSettle();

      // Payment dialog opens
      expect(find.text('Collect Payment'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Record'),
        ),
        findsOneWidget,
      );

      // Confirm payment collection
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Record'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify payment was recorded
      expect(feeRepo._payments.length, 1);
      expect(feeRepo._payments.first.amount, 8000.0);
    });

    testWidgets('5. Results screen renders exams and allows adding marks', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final examRepo = _FakeExamRepo();
      examRepo.addResults([
        const ExamResult(
          id: 'res_01',
          academyId: testAcademyId,
          examId: 'ex_01',
          studentId: '100001',
          obtainedMarks: 94,
          totalMarks: 100,
          grade: 'A+',
          passed: true,
          isPublished: true,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            resultsStreamProvider.overrideWith(
              (ref, id) => examRepo.watchResults(id),
            ),
            examRepositoryProvider.overrideWithValue(examRepo),
          ],
          child: const MaterialApp(
            home: ResultsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check existing result
      expect(find.text('Student 100001'), findsOneWidget);
      expect(find.text('94 / 100 marks'), findsOneWidget);
      expect(find.text('A+'), findsOneWidget);

      // Open Add Result dialog
      final addResultBtn = find.widgetWithText(FloatingActionButton, 'Add Result');
      expect(addResultBtn, findsOneWidget);
      await tester.tap(addResultBtn);
      await tester.pumpAndSettle();

      expect(find.text('Add Result'), findsWidgets);

      // Enter marks
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Student roll no.'),
        '100002',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Obtained marks'),
        '85',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Total marks'),
        '100',
      );

      // Save
      final saveBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Save'),
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(examRepo._results.length, 2);
      expect(examRepo._results.last.studentId, '100002');
      expect(examRepo._results.last.grade, 'A+');
      expect(examRepo._results.last.passed, isTrue);
    });

    testWidgets('6. Academy Admin Dashboard displays live metrics with zero phone overflow', (
      tester,
    ) async {
      // Test on small 360px mobile width
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final studentRepo = _FakeStudentRepo();
      studentRepo.addStudents(_createSeededStudents(testAcademyId));

      final staffList = [
        const Staff(
          id: 'stf_1',
          academyId: testAcademyId,
          fullName: 'Sir Tariq',
        ),
        const Staff(
          id: 'stf_2',
          academyId: testAcademyId,
          fullName: 'Dr. Amina',
        ),
      ];

      final accessRepo = _FakeAccessRepo(accessInfo);
      final authRepo = _FakeAuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            authRepositoryProvider.overrideWithValue(authRepo),
            academyAccessRepositoryProvider.overrideWithValue(accessRepo),
            academyAccessProvider.overrideWith((ref) => Stream.value(accessInfo)),
            studentsStreamProvider.overrideWith(
              (ref, id) => studentRepo.watchAll(id),
            ),
            staffStreamProvider.overrideWith(
              (ref, id) => Stream.value(staffList),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AcademyAdminDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Overview header and live stats count
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Students'), findsWidgets);
      expect(find.text('Staff'), findsWidgets);
      expect(find.text('5'), findsOneWidget); // 5 seeded students
      expect(find.text('2'), findsOneWidget); // 2 staff members

      // Check module tiles
      expect(find.text('Fees'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);

      // Verify ZERO render overflow errors on small phone screen
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Staff list displays faculty and filters by query', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staffRepo = _FakeStaffRepo();
      staffRepo.addStaff([
        const Staff(
          id: 'stf_1',
          academyId: testAcademyId,
          fullName: 'Sir Tariq Mehmood',
          jobTitle: 'Head of Sciences',
          phone: '03001234567',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            staffStreamProvider.overrideWith(
              (ref, id) => staffRepo.watchAll(id),
            ),
            staffRepositoryProvider.overrideWithValue(staffRepo),
          ],
          child: const MaterialApp(
            home: StaffListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sir Tariq Mehmood'), findsOneWidget);
      expect(find.text('Add Staff Member'), findsOneWidget);
    });

    testWidgets('8. Add staff screen creates staff record in repository and shows credential slip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staffRepo = _FakeStaffRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            staffRepositoryProvider.overrideWithValue(staffRepo),
          ],
          child: const MaterialApp(
            home: AddStaffScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Dr. Amina Qureshi');
      await tester.enterText(find.byType(TextFormField).at(1), 'Senior Lecturer');
      await tester.enterText(find.byType(TextFormField).at(2), '03009876543');

      final submitBtn = find.widgetWithText(FilledButton, 'Add Staff Member');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Credential slip dialog is shown with allocated Staff ID
      expect(find.text('Staff Credentials'), findsOneWidget);
      expect(find.text('STF-1001'), findsOneWidget);
      expect(find.text('Copy Credentials'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      expect(staffRepo._staff.length, 1);
      expect(staffRepo._staff.first.fullName, 'Dr. Amina Qureshi');
      expect(staffRepo._staff.first.jobTitle, 'Senior Lecturer');
      expect(staffRepo._staff.first.staffId, 'STF-1001');
      expect(staffRepo._staff.first.password.isNotEmpty, isTrue);
    });

    testWidgets('9. Branches list displays campuses and filters by query', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final branchRepo = _FakeBranchRepo();
      branchRepo.addBranches([
        const Branch(
          id: 'br_1',
          academyId: testAcademyId,
          name: 'Main Campus',
          city: 'Islamabad',
          address: 'Blue Area',
          phone: '051111222333',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            branchesStreamProvider.overrideWith(
              (ref, id) => branchRepo.watchAll(id),
            ),
            branchRepositoryProvider.overrideWithValue(branchRepo),
          ],
          child: const MaterialApp(
            home: BranchesListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main Campus'), findsOneWidget);
      expect(find.text('Add Branch'), findsOneWidget);
    });

    testWidgets('10. Add branch screen creates branch record in repository', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final branchRepo = _FakeBranchRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            branchRepositoryProvider.overrideWithValue(branchRepo),
          ],
          child: const MaterialApp(
            home: AddBranchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'F-10 Campus');
      await tester.enterText(find.byType(TextFormField).at(1), 'Islamabad');
      await tester.enterText(find.byType(TextFormField).at(2), '0519876543');
      await tester.enterText(find.byType(TextFormField).at(3), 'Street 15, F-10/2');

      final submitBtn = find.widgetWithText(FilledButton, 'Create Branch');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(branchRepo._branches.length, 1);
      expect(branchRepo._branches.first.name, 'F-10 Campus');
      expect(branchRepo._branches.first.city, 'Islamabad');
    });

    testWidgets('11. Edit student screen updates student record in repository', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final studentRepo = _FakeStudentRepo();
      final student = Student(
        id: 'stu_101',
        academyId: testAcademyId,
        fullName: 'Original Name',
        fatherName: 'Father Name',
        guardianPhone: '03001234567',
        academicSession: '2026-2027',
        rollNumber: '100001',
      );
      studentRepo.addStudents([student]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            studentRepositoryProvider.overrideWithValue(studentRepo),
          ],
          child: MaterialApp(
            home: EditStudentScreen(student: student),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Original Name'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Corrected Student Name');

      final saveBtn = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(studentRepo._students.first.fullName, 'Corrected Student Name');
    });

    testWidgets('12. Edit student screen allows deleting student with confirmation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final studentRepo = _FakeStudentRepo();
      final student = Student(
        id: 'stu_101',
        academyId: testAcademyId,
        fullName: 'Student to Delete',
        fatherName: 'Father Name',
        guardianPhone: '03001234567',
        academicSession: '2026-2027',
        rollNumber: '100001',
      );
      studentRepo.addStudents([student]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            studentRepositoryProvider.overrideWithValue(studentRepo),
          ],
          child: MaterialApp(
            home: EditStudentScreen(student: student),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteIconBtn = find.byTooltip('Delete Student');
      expect(deleteIconBtn, findsOneWidget);
      await tester.tap(deleteIconBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete Student'), findsWidgets);
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Delete Student'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(studentRepo._students, isEmpty);
    });

    testWidgets('13. Edit staff screen updates staff record in repository', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staffRepo = _FakeStaffRepo();
      const staff = Staff(
        id: 'stf_101',
        academyId: testAcademyId,
        fullName: 'Original Staff',
        jobTitle: 'Lecturer',
        phone: '03001234567',
      );
      staffRepo.addStaff([staff]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            staffRepositoryProvider.overrideWithValue(staffRepo),
          ],
          child: const MaterialApp(
            home: EditStaffScreen(staff: staff),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Original Staff'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).at(0), 'Updated Professor Name');

      final saveBtn = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(staffRepo._staff.first.fullName, 'Updated Professor Name');
    });

    testWidgets('14. Edit staff screen allows deleting staff member with confirmation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staffRepo = _FakeStaffRepo();
      const staff = Staff(
        id: 'stf_101',
        academyId: testAcademyId,
        fullName: 'Staff to Delete',
        jobTitle: 'Lecturer',
        phone: '03001234567',
      );
      staffRepo.addStaff([staff]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            staffRepositoryProvider.overrideWithValue(staffRepo),
          ],
          child: const MaterialApp(
            home: EditStaffScreen(staff: staff),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteIconBtn = find.byTooltip('Delete Staff Member');
      expect(deleteIconBtn, findsOneWidget);
      await tester.tap(deleteIconBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete Staff Member'), findsWidgets);
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Delete Staff'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(staffRepo._staff, isEmpty);
    });

    testWidgets('15. Edit branch screen updates branch record in repository', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final branchRepo = _FakeBranchRepo();
      const branch = Branch(
        id: 'br_101',
        academyId: testAcademyId,
        name: 'Original Campus',
        city: 'Islamabad',
        phone: '051111222',
        address: 'Sector F-7',
      );
      branchRepo.addBranches([branch]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            branchRepositoryProvider.overrideWithValue(branchRepo),
          ],
          child: const MaterialApp(
            home: EditBranchScreen(branch: branch),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Original Campus'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Updated Premier Campus');

      final saveBtn = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(branchRepo._branches.first.name, 'Updated Premier Campus');
    });

    testWidgets('16. Edit branch screen allows deleting branch with confirmation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final branchRepo = _FakeBranchRepo();
      const branch = Branch(
        id: 'br_101',
        academyId: testAcademyId,
        name: 'Branch to Delete',
        city: 'Islamabad',
        phone: '051111222',
        address: 'Sector F-7',
      );
      branchRepo.addBranches([branch]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            branchRepositoryProvider.overrideWithValue(branchRepo),
          ],
          child: const MaterialApp(
            home: EditBranchScreen(branch: branch),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteIconBtn = find.byTooltip('Delete Branch');
      expect(deleteIconBtn, findsOneWidget);
      await tester.tap(deleteIconBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete Branch'), findsWidgets);
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Delete Branch'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(branchRepo._branches, isEmpty);
    });

    testWidgets('17. Academy Admin can reset staff password and preview updated credentials slip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staffRepo = _FakeStaffRepo();
      const staff = Staff(
        id: 'stf_1',
        staffId: 'STF-1001',
        academyId: testAcademyId,
        fullName: 'Professor Tariq',
        jobTitle: 'HOD Math',
        password: 'OldPassword123',
      );
      staffRepo.addStaff([staff]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            staffStreamProvider.overrideWith(
              (ref, id) => staffRepo.watchAll(id),
            ),
            staffRepositoryProvider.overrideWithValue(staffRepo),
          ],
          child: const MaterialApp(
            home: EditStaffScreen(staff: staff),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final resetBtn = find.widgetWithText(OutlinedButton, 'Reset Password');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reset Staff Password'), findsOneWidget);
      expect(find.text('Save & View Slip'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save & View Slip'));
      await tester.pumpAndSettle();

      expect(find.text('Staff Credentials'), findsOneWidget);
      expect(find.text('STF-1001'), findsWidgets);
      expect(find.text('Copy Credentials'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      expect(staffRepo._staff.first.password, isNot('OldPassword123'));
    });

    testWidgets('18. Staff login screen accepts Staff ID and password and authenticates staff member', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authRepo = _FakeAuthRepo();

      final router = GoRouter(
        initialLocation: '/staff-login',
        routes: [
          GoRoute(
            path: '/staff-login',
            builder: (context, state) => const StaffLoginScreen(),
          ),
          GoRoute(
            path: '/staff',
            builder: (context, state) => const Scaffold(
              body: Text('Staff Home Dashboard'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff Login'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Staff ID or Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Staff ID or Email'),
        'STF-1001',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Staff@7890',
      );

      final signInBtn = find.widgetWithText(FilledButton, 'Sign In');
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(authRepo.lastStaffIdentifier, 'STF-1001');
      expect(authRepo.lastStaffPassword, 'Staff@7890');
      expect(find.text('Staff Home Dashboard'), findsOneWidget);
    });

    testWidgets('19. Staff credentials modal and reset password modal render cleanly on narrow phone (320px) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staffRepo = _FakeStaffRepo();
      const staff = Staff(
        id: 'stf_long',
        staffId: 'STF-8899',
        academyId: testAcademyId,
        fullName: 'Prof. Dr. Muhammad Tariq Mehmood Qureshi Senior Faculty',
        jobTitle: 'Head of Sciences, Physics & Mathematics Department Lead',
        password: 'TemporaryComplexPassword@12345',
      );
      staffRepo.addStaff([staff]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAcademyIdProvider.overrideWithValue(testAcademyId),
            staffStreamProvider.overrideWith(
              (ref, id) => staffRepo.watchAll(id),
            ),
            staffRepositoryProvider.overrideWithValue(staffRepo),
          ],
          child: const MaterialApp(
            home: EditStaffScreen(staff: staff),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify zero overflow on EditStaffScreen header
      expect(tester.takeException(), isNull);

      // Open Reset Password dialog
      final resetBtn = find.widgetWithText(OutlinedButton, 'Reset Password');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Verify zero overflow in Reset Password dialog on 320px screen
      expect(tester.takeException(), isNull);
      expect(find.text('Reset Staff Password'), findsOneWidget);

      // Save and open credential slip modal
      await tester.tap(find.widgetWithText(FilledButton, 'Save & View Slip'));
      await tester.pumpAndSettle();

      // Verify zero overflow in Staff Credentials Slip on 320px screen
      expect(tester.takeException(), isNull);
      expect(find.text('Staff Credentials'), findsOneWidget);
      expect(find.text('Copy Credentials'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

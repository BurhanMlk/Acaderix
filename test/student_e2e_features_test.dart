import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/core/domain/attendance_calculator.dart';
import 'package:academy_management/features/academics/application/course_repository_provider.dart';
import 'package:academy_management/features/academics/domain/course.dart';
import 'package:academy_management/features/academics/domain/course_repository.dart';
import 'package:academy_management/features/admissions/application/student_repository_provider.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/admissions/domain/student_repository.dart';
import 'package:academy_management/features/attendance/application/attendance_repository_provider.dart';
import 'package:academy_management/features/attendance/domain/attendance_record.dart';
import 'package:academy_management/features/attendance/domain/attendance_repository.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/branches/application/branch_repository_provider.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/branches/domain/branch_repository.dart';
import 'package:academy_management/features/exams/application/exam_repository_provider.dart';
import 'package:academy_management/features/exams/domain/exam.dart';
import 'package:academy_management/features/exams/domain/exam_repository.dart';
import 'package:academy_management/features/exams/domain/exam_result.dart';
import 'package:academy_management/features/fees/application/fee_repository_provider.dart';
import 'package:academy_management/features/fees/domain/fee_invoice.dart';
import 'package:academy_management/features/fees/domain/fee_payment.dart';
import 'package:academy_management/features/fees/domain/fee_repository.dart';
import 'package:academy_management/features/student/application/student_providers.dart';
import 'package:academy_management/features/student/presentation/screens/student_shell.dart';
import 'package:academy_management/features/student/presentation/utils/student_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo(this.user);
  final AppUser user;

  @override
  Stream<AuthState> authStateChanges() =>
      Stream.value(AuthState.authenticated(user));

  @override
  Future<AuthState> currentState() async => AuthState.authenticated(user);

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => user;

  @override
  Future<AppUser> signInAsStaff({
    required String identifier,
    required String password,
  }) async => user;

  @override
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) async => user;

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => user;

  @override
  Future<AppUser> refreshCurrentUser() async => user;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeStudentRepo implements StudentRepository {
  final List<Student> _students = [];
  void addStudents(List<Student> students) => _students.addAll(students);

  @override
  Stream<List<Student>> watchAll(String academyId) => Stream.value(_students);

  @override
  Future<Student?> getById(String academyId, String studentId) async =>
      _students.where((s) => s.id == studentId).firstOrNull;

  @override
  Future<String> allocateRollNumber(String academyId) async => '100001';

  @override
  Future<void> create(Student student) async => _students.add(student);

  @override
  Future<void> update(Student student) async {
    final idx = _students.indexWhere((s) => s.id == student.id);
    if (idx != -1) _students[idx] = student;
  }

  @override
  Future<void> delete(String academyId, String studentId) async {
    _students.removeWhere((s) => s.id == studentId);
  }
}

class _FakeBranchRepo implements BranchRepository {
  final List<Branch> _branches = [];
  void addBranches(List<Branch> branches) => _branches.addAll(branches);

  @override
  Stream<List<Branch>> watchAll(String academyId) => Stream.value(_branches);

  @override
  Future<void> create(Branch branch) async => _branches.add(branch);

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

class _FakeAttendanceRepo implements AttendanceRepository {
  final List<AttendanceRecord> _records = [];
  void addRecords(List<AttendanceRecord> records) => _records.addAll(records);

  @override
  Stream<List<AttendanceRecord>> watchForDate(String academyId, DateTime date) =>
      Stream.value(_records);

  @override
  Stream<List<AttendanceRecord>> watchForStudent(
    String academyId,
    String studentId,
  ) {
    return Stream.value(
      _records.where((r) => r.studentId == studentId).toList(),
    );
  }

  @override
  Future<void> markAttendance(AttendanceRecord record) async {
    _records.add(record);
  }

  @override
  Future<void> markBatchAttendance(List<AttendanceRecord> records) async {
    _records.addAll(records);
  }
}

class _FakeCourseRepo implements CourseRepository {
  final List<Course> _courses = [];
  void addCourses(List<Course> courses) => _courses.addAll(courses);

  @override
  Stream<List<Course>> watchAll(String academyId) => Stream.value(_courses);

  @override
  Stream<List<Course>> watchByBranch(String academyId, String branchId) =>
      Stream.value(_courses.where((c) => c.branchId == branchId).toList());

  @override
  Stream<List<Course>> watchByTeacher(String academyId, String teacherId) =>
      Stream.value(_courses.where((c) => c.teacherId == teacherId).toList());

  @override
  Future<Course?> getById(String academyId, String courseId) async =>
      _courses.where((c) => c.id == courseId).firstOrNull;

  @override
  Future<void> saveCourse(Course course) async => _courses.add(course);

  @override
  Future<void> deleteCourse(String academyId, String courseId) async =>
      _courses.removeWhere((c) => c.id == courseId);

  @override
  Future<void> enrollStudents(
    String academyId,
    String courseId,
    List<String> studentIds,
  ) async {}

  @override
  Future<void> unenrollStudent(
    String academyId,
    String courseId,
    String studentId,
  ) async {}
}

class _FakeFeeRepo implements FeeRepository {
  final List<FeeInvoice> _invoices = [];
  final List<FeePayment> _payments = [];

  void addInvoices(List<FeeInvoice> invoices) => _invoices.addAll(invoices);
  void addPayments(List<FeePayment> payments) => _payments.addAll(payments);

  @override
  Stream<List<FeeInvoice>> watchInvoices(String academyId, {String? studentId}) {
    if (studentId != null) {
      return Stream.value(
        _invoices.where((i) => i.studentId == studentId).toList(),
      );
    }
    return Stream.value(_invoices);
  }

  @override
  Stream<List<FeePayment>> watchPayments(String academyId, {String? studentId}) {
    if (studentId != null) {
      return Stream.value(
        _payments.where((p) => p.studentId == studentId).toList(),
      );
    }
    return Stream.value(_payments);
  }

  @override
  Future<void> createInvoice(FeeInvoice invoice) async => _invoices.add(invoice);

  @override
  Future<void> recordPayment(FeePayment payment) async => _payments.add(payment);
}

class _FakeExamRepo implements ExamRepository {
  final List<Exam> _exams = [];
  final List<ExamResult> _results = [];

  void addExams(List<Exam> exams) => _exams.addAll(exams);
  void addResults(List<ExamResult> results) => _results.addAll(results);

  @override
  Stream<List<Exam>> watchExams(String academyId) => Stream.value(_exams);

  @override
  Stream<List<ExamResult>> watchResults(
    String academyId, {
    String? studentId,
  }) {
    if (studentId != null) {
      return Stream.value(
        _results.where((r) => r.studentId == studentId).toList(),
      );
    }
    return Stream.value(_results);
  }

  @override
  Future<void> createExam(Exam exam) async => _exams.add(exam);

  @override
  Future<void> saveResult(ExamResult result) async => _results.add(result);
}

void main() {
  const academyId = 'acd_apex';
  const branchId = 'br_apex_main';
  const studentId = 'std_hamza_100001';
  const rollNumber = '100001';

  final demoStudentUser = const AppUser(
    id: studentId,
    email: 'hamza@student.acaderix.test',
    displayName: 'Hamza Khan',
    role: AppRole.student,
    academyId: academyId,
    branchId: branchId,
    rollNumber: rollNumber,
  );

  final demoBranch = const Branch(
    id: branchId,
    academyId: academyId,
    name: 'Apex City Campus',
    address: 'Main Boulevard, Gulberg, Lahore',
    phone: '+92 42 35789000',
  );

  final demoStudent = Student(
    id: studentId,
    academyId: academyId,
    branchId: branchId,
    rollNumber: rollNumber,
    fullName: 'Hamza Khan',
    fatherName: 'Tariq Khan',
    guardianPhone: '+92 300 1234567',
    guardianRelation: 'Father',
    phone: '+92 321 9876543',
    gender: 'Male',
    academicSession: '2026-2027',
    dateOfBirth: DateTime(2008, 5, 14),
    admissionDate: DateTime(2025, 8, 1),
    address: 'House 42, Block B, Model Town, Lahore',
    status: 'active',
  );

  final demoCourses = [
    Course(
      id: 'crs_phy_10',
      academyId: academyId,
      branchId: branchId,
      name: 'Physics 10th - Batch A',
      courseCode: 'PHY-10A',
      description: 'Mechanics, Heat, Waves, and Modern Physics',
      teacherName: 'Sir Ahmed Raza',
      teacherId: 'stf_ahmed',
      room: '101',
      schedule: 'Mon, Wed, Fri 09:00 - 10:30 AM',
      enrolledStudentIds: [studentId, rollNumber],
    ),
    Course(
      id: 'crs_mth_10',
      academyId: academyId,
      branchId: branchId,
      name: 'Mathematics 10th - Advance',
      courseCode: 'MTH-10ADV',
      description: 'Algebra, Matrices, and Coordinate Geometry',
      teacherName: 'Sir Salman Ali',
      teacherId: 'stf_salman',
      room: 'Lab 2',
      schedule: 'Tue, Thu, Sat 11:00 AM - 12:30 PM',
      enrolledStudentIds: [studentId, rollNumber],
    ),
  ];

  final demoAttendanceRecords = [
    AttendanceRecord(
      id: 'att_01',
      academyId: academyId,
      studentId: studentId,
      courseId: 'crs_phy_10',
      date: DateTime(2026, 10, 20),
      status: AttendanceStatus.present,
    ),
    AttendanceRecord(
      id: 'att_02',
      academyId: academyId,
      studentId: studentId,
      courseId: 'crs_phy_10',
      date: DateTime(2026, 10, 22),
      status: AttendanceStatus.present,
    ),
    AttendanceRecord(
      id: 'att_03',
      academyId: academyId,
      studentId: studentId,
      courseId: 'crs_mth_10',
      date: DateTime(2026, 10, 23),
      status: AttendanceStatus.late,
    ),
    AttendanceRecord(
      id: 'att_04',
      academyId: academyId,
      studentId: studentId,
      courseId: 'crs_mth_10',
      date: DateTime(2026, 10, 24),
      status: AttendanceStatus.present,
    ),
  ];

  final demoExams = [
    Exam(
      id: 'ex_midterm_1',
      academyId: academyId,
      name: 'Mid-Term Comprehensive Assessment',
      category: 'term',
      totalMarks: 100,
      isPublished: true,
    ),
    Exam(
      id: 'ex_monthly_oct',
      academyId: academyId,
      name: 'October Monthly Test',
      category: 'monthly',
      totalMarks: 50,
      isPublished: true,
    ),
  ];

  final demoResults = [
    const ExamResult(
      id: 'res_01',
      academyId: academyId,
      examId: 'ex_midterm_1',
      studentId: studentId,
      obtainedMarks: 88,
      totalMarks: 100,
      grade: 'A+',
      passed: true,
      isPublished: true,
    ),
    const ExamResult(
      id: 'res_02',
      academyId: academyId,
      examId: 'ex_monthly_oct',
      studentId: studentId,
      obtainedMarks: 44,
      totalMarks: 50,
      grade: 'A+',
      passed: true,
      isPublished: true,
    ),
  ];

  final demoInvoices = [
    FeeInvoice(
      id: 'inv_01',
      academyId: academyId,
      studentId: studentId,
      invoiceNo: 'INV-2026-001',
      title: 'October 2026 Term Tuition Fee',
      baseAmount: 12000,
      paidAmount: 12000,
      status: 'paid',
      dueDate: DateTime(2026, 10, 10),
    ),
    FeeInvoice(
      id: 'inv_02',
      academyId: academyId,
      studentId: studentId,
      invoiceNo: 'INV-2026-002',
      title: 'November 2026 Term Tuition Fee',
      baseAmount: 12000,
      paidAmount: 6000,
      status: 'unpaid',
      dueDate: DateTime(2026, 11, 10),
    ),
  ];

  final demoPayments = [
    FeePayment(
      id: 'pay_01',
      academyId: academyId,
      studentId: studentId,
      invoiceId: 'inv_01',
      amount: 12000,
      method: 'Bank Transfer / Online',
      reference: 'TXN-984210',
      paidAt: DateTime(2026, 10, 5),
    ),
    FeePayment(
      id: 'pay_02',
      academyId: academyId,
      studentId: studentId,
      invoiceId: 'inv_02',
      amount: 6000,
      method: 'Cash Office',
      reference: 'CSH-1049',
      paidAt: DateTime(2026, 11, 2),
    ),
  ];

  Widget buildTestApp({
    Size screenSize = const Size(380, 800),
    required Widget child,
  }) {
    final fakeAuth = _FakeAuthRepo(demoStudentUser);
    final fakeStudentRepo = _FakeStudentRepo()..addStudents([demoStudent]);
    final fakeBranchRepo = _FakeBranchRepo()..addBranches([demoBranch]);
    final fakeAttendanceRepo = _FakeAttendanceRepo()
      ..addRecords(demoAttendanceRecords);
    final fakeCourseRepo = _FakeCourseRepo()..addCourses(demoCourses);
    final fakeFeeRepo = _FakeFeeRepo()
      ..addInvoices(demoInvoices)
      ..addPayments(demoPayments);
    final fakeExamRepo = _FakeExamRepo()
      ..addExams(demoExams)
      ..addResults(demoResults);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuth),
        studentRepositoryProvider.overrideWithValue(fakeStudentRepo),
        branchRepositoryProvider.overrideWithValue(fakeBranchRepo),
        attendanceRepositoryProvider.overrideWithValue(fakeAttendanceRepo),
        courseRepositoryProvider.overrideWithValue(fakeCourseRepo),
        feeRepositoryProvider.overrideWithValue(fakeFeeRepo),
        examRepositoryProvider.overrideWithValue(fakeExamRepo),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F172A),
        ),
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: child,
        ),
      ),
    );
  }

  group('Student Experience End-to-End Suite', () {
    testWidgets('Renders StudentShell and Overview Dashboard with metrics',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const StudentShell()),
      );
      await tester.pumpAndSettle();

      // Verify app bar
      expect(find.text('Student Portal'), findsOneWidget);
      expect(find.textContaining('Hamza Khan'), findsWidgets);
      expect(find.textContaining('Roll #100001'), findsWidgets);

      // Verify dashboard KPI cards
      expect(find.text('Attendance'), findsWidgets);
      expect(find.text('Enrolled Courses'), findsOneWidget);
      expect(find.text('Fee Status'), findsOneWidget);
      expect(find.text('Performance'), findsOneWidget);

      // Verify ID Pass button is available
      expect(find.text('ID Card'), findsOneWidget);
    });

    testWidgets('Tapping ID Pass button opens Digital Student ID Modal',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const StudentShell()),
      );
      await tester.pumpAndSettle();

      // Tap on ID Card button
      final idButton = find.text('ID Card');
      expect(idButton, findsOneWidget);
      await tester.tap(idButton);
      await tester.pumpAndSettle();

      // Verify Modal elements
      expect(find.text('Student Digital Pass'), findsOneWidget);
      expect(find.text('ACADERIX ACADEMY'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.text('STUDENT ID'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);

      // Scroll to view Guardian & Sign out
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -350));
      await tester.pumpAndSettle();

      expect(find.text('Father / Guardian'), findsOneWidget);
      expect(find.text('Tariq Khan'), findsOneWidget);
      expect(find.text('Sign Out of Student Portal'), findsOneWidget);
    });

    testWidgets('Switches to Courses Tab and verifies Courses & Timetable',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const StudentShell()),
      );
      await tester.pumpAndSettle();

      // Tap on bottom navigation item "Courses"
      final coursesNav = find.text('Courses');
      expect(coursesNav, findsWidgets);
      await tester.tap(coursesNav.first);
      await tester.pumpAndSettle();

      // Verify Courses header & cards
      expect(find.text('Courses & Timetable'), findsOneWidget);
      expect(find.text('Physics 10th - Batch A'), findsOneWidget);
      expect(find.text('Mathematics 10th - Advance'), findsOneWidget);
      expect(find.text('Sir Ahmed Raza'), findsOneWidget);

      // Switch to Class Timetable view
      final timetableBtn = find.text('Class Timetable');
      expect(timetableBtn, findsOneWidget);
      await tester.tap(timetableBtn);
      await tester.pumpAndSettle();

      expect(find.text('Monday Schedule'), findsOneWidget);
    });

    testWidgets('Switches to Attendance Tab and verifies analytics & records',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const StudentShell()),
      );
      await tester.pumpAndSettle();

      // Tap on Attendance tab
      final attNav = find.text('Attendance');
      expect(attNav, findsWidgets);
      await tester.tap(attNav.first);
      await tester.pumpAndSettle();

      expect(find.text('Attendance Analytics'), findsOneWidget);
      expect(find.text('Attendance Overview'), findsOneWidget);
      expect(find.text('Eligible for Exams'), findsOneWidget);
      expect(find.text('Minimum Exam Requirement (75%)'), findsOneWidget);
      expect(find.textContaining('Attendance Records (4)'), findsOneWidget);
    });

    testWidgets('Switches to Results Tab and verifies Scores & Report Card action',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const StudentShell()),
      );
      await tester.pumpAndSettle();

      // Tap on Results tab
      final resultsNav = find.text('Results');
      expect(resultsNav, findsWidgets);
      await tester.tap(resultsNav.first);
      await tester.pumpAndSettle();

      expect(find.text('Academic Results'), findsOneWidget);
      expect(find.text('Academic Performance'), findsOneWidget);
      expect(find.text('Grade A+'), findsOneWidget);
      expect(find.text('Download Official Report Card (PDF)'), findsOneWidget);
      expect(find.text('Exam Scores (%)'), findsOneWidget);

      // Scroll down to view the examination breakdown cards
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Mid-Term Comprehensive Assessment'), findsOneWidget);
    });

    testWidgets('Switches to Fees Tab and verifies Balance, Invoices & Receipts',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(child: const StudentShell()),
      );
      await tester.pumpAndSettle();

      // Tap on Fees tab
      final feesNav = find.text('Fees');
      expect(feesNav, findsWidgets);
      await tester.tap(feesNav.first);
      await tester.pumpAndSettle();

      expect(find.text('Fees & Ledger'), findsOneWidget);
      expect(find.text('Fee Account Status'), findsOneWidget);
      expect(find.text('Outstanding Balance'), findsOneWidget);
      expect(find.text('Rs 6000'), findsWidgets);
      expect(find.text('October 2026 Term Tuition Fee'), findsOneWidget);

      // Switch to Receipts ledger
      final receiptsBtn = find.textContaining('Receipts (2)');
      expect(receiptsBtn, findsOneWidget);
      await tester.tap(receiptsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Payment Receipts Ledger (2)'), findsOneWidget);
      expect(find.text('Rs 12000'), findsOneWidget);
      expect(find.text('SUCCESSFUL'), findsWidgets);
    });

    testWidgets('Verifies PDF Report Card & Receipt Generation Byte Output',
        (tester) async {
      final metrics = const StudentMetrics(
        attendanceRate: 100,
        feeBalance: 6000,
        overallPercentage: 88,
        overallGrade: 'A+',
      );

      final reportCardBytes = await StudentPdfGenerator.generateReportCardBytes(
        student: demoStudent,
        branch: demoBranch,
        results: demoResults,
        courses: demoCourses,
        metrics: metrics,
      );

      expect(reportCardBytes.isNotEmpty, isTrue);
      expect(reportCardBytes.lengthInBytes, greaterThan(1000));

      final receiptBytes = await StudentPdfGenerator.generateFeeReceiptBytes(
        student: demoStudent,
        branch: demoBranch,
        invoice: demoInvoices.first,
        payment: demoPayments.first,
        feeBalance: 0,
      );

      expect(receiptBytes.isNotEmpty, isTrue);
      expect(receiptBytes.lengthInBytes, greaterThan(1000));
    });

    testWidgets('Responsive narrow mobile viewport (320px) check - zero overflows',
        (tester) async {
      // 320x600 small mobile viewport
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(320, 640),
          child: const StudentShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Check no layout errors on Overview
      expect(tester.takeException(), isNull);

      // Switch to Courses on narrow phone
      await tester.tap(find.text('Courses').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Attendance on narrow phone
      await tester.tap(find.text('Attendance').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Results on narrow phone
      await tester.tap(find.text('Results').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Fees on narrow phone
      await tester.tap(find.text('Fees').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

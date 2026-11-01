import 'package:academy_management/core/constants/roles.dart';
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
import 'package:academy_management/features/exams/domain/exam_result.dart';
import 'package:academy_management/features/exams/domain/exam_repository.dart';
import 'package:academy_management/features/staff/application/staff_repository_provider.dart';
import 'package:academy_management/features/staff/domain/staff.dart';
import 'package:academy_management/features/staff/domain/staff_repository.dart';
import 'package:academy_management/features/staff/presentation/screens/staff_shell.dart';
import 'package:academy_management/features/staff/presentation/screens/staff_students_tab.dart';
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

  void addStudents(List<Student> students) {
    _students.addAll(students);
  }

  @override
  Stream<List<Student>> watchAll(String academyId) => Stream.value(_students);

  @override
  Future<Student?> getById(String academyId, String studentId) async {
    return _students.where((s) => s.id == studentId).firstOrNull;
  }

  @override
  Future<String> allocateRollNumber(String academyId) async => '2001';

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

class _FakeStaffRepo implements StaffRepository {
  final List<Staff> _staff = [];

  void addStaff(List<Staff> staff) {
    _staff.addAll(staff);
  }

  @override
  Stream<List<Staff>> watchAll(String academyId) => Stream.value(_staff);

  @override
  Future<String> allocateStaffId(String academyId) async => 'STF-1005';

  @override
  Future<void> create(Staff staff) async => _staff.add(staff);

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
    final idx =
        _staff.indexWhere((s) => s.staffId == staffId || s.id == staffId);
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

  @override
  Future<void> markBatchAttendance(List<AttendanceRecord> records) async {
    for (final r in records) {
      await markAttendance(r);
    }
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
  Future<void> saveCourse(Course course) async {
    final idx = _courses.indexWhere((c) => c.id == course.id);
    if (idx != -1) {
      _courses[idx] = course;
    } else {
      _courses.add(course);
    }
  }

  @override
  Future<void> deleteCourse(String academyId, String courseId) async =>
      _courses.removeWhere((c) => c.id == courseId);

  @override
  Future<void> enrollStudents(
    String academyId,
    String courseId,
    List<String> studentIds,
  ) async {
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      _courses[idx] = _courses[idx].copyWith(
        enrolledStudentIds: {
          ..._courses[idx].enrolledStudentIds,
          ...studentIds,
        }.toList(),
      );
    }
  }

  @override
  Future<void> unenrollStudent(
    String academyId,
    String courseId,
    String studentId,
  ) async {
    final idx = _courses.indexWhere((c) => c.id == courseId);
    if (idx != -1) {
      _courses[idx] = _courses[idx].copyWith(
        enrolledStudentIds: _courses[idx]
            .enrolledStudentIds
            .where((id) => id != studentId)
            .toList(),
      );
    }
  }
}

class _FakeExamRepo implements ExamRepository {
  final List<Exam> _exams = [];
  final List<ExamResult> _results = [];

  void addExams(List<Exam> exams) => _exams.addAll(exams);
  void addResults(List<ExamResult> results) => _results.addAll(results);

  @override
  Stream<List<Exam>> watchExams(String academyId) => Stream.value(_exams);

  @override
  Stream<List<ExamResult>> watchResults(String academyId, {String? studentId}) =>
      Stream.value(_results);

  @override
  Future<void> createExam(Exam exam) async => _exams.add(exam);

  @override
  Future<void> saveResult(ExamResult result) async {
    final idx = _results.indexWhere((r) => r.id == result.id);
    if (idx != -1) {
      _results[idx] = result;
    } else {
      _results.add(result);
    }
  }
}

void main() {
  const academyId = 'acad_test_123';
  const branchId = 'br_main';

  final testUser = const AppUser(
    id: 'stf_doc_1001',
    email: 'tariq@apex.edu',
    displayName: 'Prof. Tariq Mehmood',
    role: AppRole.staff,
    academyId: academyId,
    branchId: branchId,
    rollNumber: 'STF-1001',
    isActive: true,
  );

  final testBranch = const Branch(
    id: branchId,
    academyId: academyId,
    name: 'Main Campus',
    address: 'Gulberg III, Lahore',
  );

  final testStaff = Staff(
    id: 'stf_doc_1001',
    academyId: academyId,
    staffId: 'STF-1001',
    fullName: 'Prof. Tariq Mehmood',
    email: 'tariq@apex.edu',
    phone: '+92 300 1234567',
    jobTitle: 'Senior Mathematics Lecturer',
    branchId: branchId,
    salary: 85000,
    leaveBalance: 12,
    status: 'active',
    joiningDate: DateTime(2023, 1, 15),
  );

  final testStudents = [
    const Student(
      id: 'stu_101',
      academyId: academyId,
      branchId: branchId,
      fullName: 'Ali Hassan',
      rollNumber: '1001',
      fatherName: 'Hassan Raza',
      guardianPhone: '+92 321 1111111',
      academicSession: '2025-2026',
    ),
    const Student(
      id: 'stu_102',
      academyId: academyId,
      branchId: branchId,
      fullName: 'Ayesha Malik',
      rollNumber: '1002',
      fatherName: 'Malik Tariq',
      guardianPhone: '+92 321 2222222',
      academicSession: '2025-2026',
    ),
  ];

  final testExams = [
    const Exam(
      id: 'exam_01',
      academyId: academyId,
      name: 'Midterm Assessment 2025',
      category: 'monthly',
      totalMarks: 100,
    ),
  ];

  final testResults = [
    const ExamResult(
      id: 'res_01',
      academyId: academyId,
      examId: 'exam_01',
      studentId: 'stu_101',
      obtainedMarks: 88,
      totalMarks: 100,
      grade: 'A+',
      passed: true,
    ),
  ];

  final testCourses = [
    const Course(
      id: 'crs_01',
      academyId: academyId,
      branchId: branchId,
      name: 'Physics 10th - Batch A',
      courseCode: 'PHY-101',
      teacherId: 'stf_doc_1001',
      teacherName: 'Prof. Tariq Mehmood',
      enrolledStudentIds: ['stu_101', 'stu_102'],
      schedule: 'Mon, Wed, Fri • 4:00 PM',
    ),
  ];

  Widget buildStaffTestApp({
    Size screenSize = const Size(390, 1100),
    _FakeStudentRepo? studentRepo,
    _FakeStaffRepo? staffRepo,
    _FakeBranchRepo? branchRepo,
    _FakeAttendanceRepo? attendanceRepo,
    _FakeExamRepo? examRepo,
    _FakeCourseRepo? courseRepo,
  }) {
    final sRepo =
        studentRepo ?? (_FakeStudentRepo()..addStudents(testStudents));
    final stRepo = staffRepo ?? (_FakeStaffRepo()..addStaff([testStaff]));
    final bRepo = branchRepo ?? (_FakeBranchRepo()..addBranches([testBranch]));
    final aRepo = attendanceRepo ?? _FakeAttendanceRepo();
    final eRepo = examRepo ??
        (_FakeExamRepo()
          ..addExams(testExams)
          ..addResults(testResults));
    final cRepo = courseRepo ?? (_FakeCourseRepo()..addCourses(testCourses));

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepo(testUser)),
        studentRepositoryProvider.overrideWithValue(sRepo),
        staffRepositoryProvider.overrideWithValue(stRepo),
        branchRepositoryProvider.overrideWithValue(bRepo),
        attendanceRepositoryProvider.overrideWithValue(aRepo),
        examRepositoryProvider.overrideWithValue(eRepo),
        courseRepositoryProvider.overrideWithValue(cRepo),
      ],
      child: MaterialApp(
        home: Center(
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: MediaQuery(
              data: MediaQueryData(size: screenSize),
              child: const StaffShell(),
            ),
          ),
        ),
      ),
    );
  }

  group('Staff Experience End-to-End Tests', () {
    testWidgets('1. Staff Shell renders with staff badge and assigned branch',
        (tester) async {
      await tester.pumpWidget(buildStaffTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Staff Dashboard'), findsOneWidget);
      expect(find.text('STF-1001'), findsWidgets);
      expect(find.textContaining('Main Campus'), findsWidgets);
      expect(find.text('Prof. Tariq Mehmood'), findsWidgets);
    });

    testWidgets('2. Staff Dashboard displays metrics and quick action shortcuts',
        (tester) async {
      await tester.pumpWidget(buildStaffTestApp());
      await tester.pumpAndSettle();

      expect(find.text('My Campus Overview'), findsOneWidget);
      expect(find.text('Students'), findsWidgets);
      expect(find.text("Today's Attendance"), findsOneWidget);
      expect(find.text('My Courses'), findsOneWidget);
      expect(find.text('Leave Balance'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Physics 10th - Batch A'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Physics 10th - Batch A'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('My Profile & Security'),
        100,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text("Mark Today's Attendance"), findsOneWidget);
      expect(find.text('Record Exam Marks'), findsOneWidget);
      expect(find.text('Campus Student Directory'), findsOneWidget);
      expect(find.text('My Profile & Security'), findsOneWidget);
    });

    testWidgets('3. Bottom Navigation Bar navigates between tabs',
        (tester) async {
      await tester.pumpWidget(buildStaffTestApp());
      await tester.pumpAndSettle();

      Finder navItem(IconData icon) => find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.byIcon(icon),
          );

      // Tap Attendance
      await tester.tap(navItem(Icons.fact_check_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Daily Attendance'), findsOneWidget);

      // Tap Results
      await tester.tap(navItem(Icons.grade_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Exams & Results'), findsOneWidget);

      // Tap Students
      await tester.tap(navItem(Icons.people_outline));
      await tester.pumpAndSettle();
      expect(find.text('Campus Students'), findsOneWidget);

      // Tap Profile
      await tester.tap(navItem(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Staff Profile'), findsOneWidget);
    });

    testWidgets('4. Attendance Tab marks student status and batch marks present',
        (tester) async {
      final aRepo = _FakeAttendanceRepo();
      await tester.pumpWidget(buildStaffTestApp(attendanceRepo: aRepo));
      await tester.pumpAndSettle();

      Finder navItem(IconData icon) => find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.byIcon(icon),
          );

      // Go to Attendance
      await tester.tap(navItem(Icons.fact_check_outlined));
      await tester.pumpAndSettle();

      // Students rendered
      expect(find.text('Ali Hassan'), findsOneWidget);
      expect(find.text('Ayesha Malik'), findsOneWidget);

      // Mark Ali Hassan Present
      await tester.tap(find.text('P').first);
      await tester.pumpAndSettle();

      // Tap "Mark All Present"
      await tester.tap(find.text('Mark All Present'));
      await tester.pumpAndSettle();

      expect(
        find.text('All enrolled students marked Present for today!'),
        findsOneWidget,
      );
    });

    testWidgets(
        '5. Results Tab displays evaluations and saves new exam result',
        (tester) async {
      final eRepo = _FakeExamRepo()
        ..addExams(testExams)
        ..addResults(testResults);

      await tester.pumpWidget(buildStaffTestApp(examRepo: eRepo));
      await tester.pumpAndSettle();

      Finder navItem(IconData icon) => find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.byIcon(icon),
          );

      // Switch to Results
      await tester.tap(navItem(Icons.grade_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Midterm Assessment 2025'), findsWidgets);
      expect(find.text('88 / 100 marks'), findsWidgets);
      expect(find.text('Grade A+'), findsOneWidget);

      // Tap Add Result
      await tester.tap(find.text('Add Result'));
      await tester.pumpAndSettle();

      expect(find.text('Record Exam Result'), findsOneWidget);
      expect(find.text('Save Result'), findsOneWidget);

      await tester.tap(find.text('Save Result'));
      await tester.pumpAndSettle();

      expect(find.text('Exam result saved successfully!'), findsOneWidget);
    });

    testWidgets('6. Students Tab lists campus roster and filters by search',
        (tester) async {
      await tester.pumpWidget(buildStaffTestApp());
      await tester.pumpAndSettle();

      Finder navItem(IconData icon) => find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.byIcon(icon),
          );

      // Switch to Students
      await tester.tap(navItem(Icons.people_outline));
      await tester.pumpAndSettle();

      expect(find.text('Ali Hassan'), findsOneWidget);
      expect(find.text('Ayesha Malik'), findsOneWidget);

      // Enter query 'Ali Hassan'
      await tester.enterText(
        find.descendant(
          of: find.byType(StaffStudentsTab),
          matching: find.byType(TextField),
        ),
        'Ali Hassan',
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('Ali Hassan'),
        ),
        findsOneWidget,
      );
      expect(find.text('Ayesha Malik'), findsNothing);
    });

    testWidgets(
        '7. Profile Tab displays salary, details, and opens password dialog',
        (tester) async {
      await tester.pumpWidget(buildStaffTestApp());
      await tester.pumpAndSettle();

      Finder navItem(IconData icon) => find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.byIcon(icon),
          );

      // Switch to Profile
      await tester.tap(navItem(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('Prof. Tariq Mehmood'), findsWidgets);
      expect(find.text('Senior Mathematics Lecturer'), findsWidgets);
      expect(find.text('PKR 85000'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Change Password'), 100);
      expect(find.text('Change Password'), findsOneWidget);

      // Tap Change Password
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('Update Password'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        '8. Zero RenderFlex overflow on narrow phone (320px) across all tabs',
        (tester) async {
      await tester.pumpWidget(
        buildStaffTestApp(screenSize: const Size(320, 640)),
      );
      await tester.pumpAndSettle();

      Finder navItem(IconData icon) => find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.byIcon(icon),
          );

      // Tab 0: Dashboard
      expect(tester.takeException(), isNull);

      // Tab 1: Attendance
      await tester.tap(navItem(Icons.fact_check_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tab 2: Results
      await tester.tap(navItem(Icons.grade_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tab 3: Students
      await tester.tap(navItem(Icons.people_outline));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Tab 4: Profile
      await tester.tap(navItem(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

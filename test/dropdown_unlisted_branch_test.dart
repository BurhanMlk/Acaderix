import 'package:academy_management/features/academics/application/course_repository_provider.dart';
import 'package:academy_management/features/academics/domain/course.dart';
import 'package:academy_management/features/academics/domain/course_repository.dart';
import 'package:academy_management/features/academics/presentation/screens/add_course_screen.dart';
import 'package:academy_management/features/academics/presentation/screens/edit_course_screen.dart';
import 'package:academy_management/features/academy_admin/application/academy_access_provider.dart';
import 'package:academy_management/features/academy_admin/presentation/screens/academy_admin_shell.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_models.dart';
import 'package:academy_management/features/admissions/application/student_repository_provider.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/admissions/domain/student_repository.dart';
import 'package:academy_management/features/admissions/presentation/screens/add_student_screen.dart';
import 'package:academy_management/features/admissions/presentation/screens/edit_student_screen.dart';
import 'package:academy_management/features/branches/application/branch_repository_provider.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/branches/domain/branch_repository.dart';
import 'package:academy_management/features/staff/application/staff_repository_provider.dart';
import 'package:academy_management/features/staff/domain/staff.dart';
import 'package:academy_management/features/staff/domain/staff_repository.dart';
import 'package:academy_management/features/staff/presentation/screens/add_staff_screen.dart';
import 'package:academy_management/features/staff/presentation/screens/edit_staff_screen.dart';
import 'package:academy_management/shared/current_academy_provider.dart';
import 'package:academy_management/shared/selected_branch_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal in-memory mocks
class _MockBranchRepo implements BranchRepository {
  _MockBranchRepo(this.branches);
  final List<Branch> branches;

  @override
  Stream<List<Branch>> watchAll(String academyId) => Stream.value(branches);

  @override
  Future<void> create(Branch branch) async {}

  @override
  Future<void> update(Branch branch) async {}

  @override
  Future<void> delete(String academyId, String branchId) async {}
}

class _MockStaffRepo implements StaffRepository {
  _MockStaffRepo(this.staff);
  final List<Staff> staff;

  @override
  Stream<List<Staff>> watchAll(String academyId) => Stream.value(staff);

  @override
  Future<String> allocateStaffId(String academyId) async => 'STF-1005';

  @override
  Future<void> create(Staff s) async {}

  @override
  Future<void> update(Staff s) async {}

  @override
  Future<void> resetPassword(
    String academyId,
    String staffId,
    String newPassword,
  ) async {}

  @override
  Future<void> delete(String academyId, String staffId) async {}
}

class _MockCourseRepo implements CourseRepository {
  _MockCourseRepo(this.courses);
  final List<Course> courses;

  @override
  Stream<List<Course>> watchAll(String academyId) => Stream.value(courses);

  @override
  Stream<List<Course>> watchByBranch(String academyId, String branchId) =>
      Stream.value(courses.where((c) => c.branchId == branchId).toList());

  @override
  Stream<List<Course>> watchByTeacher(String academyId, String teacherId) =>
      Stream.value(courses.where((c) => c.teacherId == teacherId).toList());

  @override
  Future<Course?> getById(String academyId, String courseId) async =>
      courses.where((c) => c.id == courseId).firstOrNull;

  @override
  Future<void> saveCourse(Course course) async {}

  @override
  Future<void> deleteCourse(String academyId, String courseId) async {}

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

class _MockStudentRepo implements StudentRepository {
  _MockStudentRepo(this.students);
  final List<Student> students;

  @override
  Stream<List<Student>> watchAll(String academyId) => Stream.value(students);

  @override
  Future<Student?> getById(String academyId, String studentId) async =>
      students.where((s) => s.id == studentId).firstOrNull;

  @override
  Future<String> allocateRollNumber(String academyId) async => 'ROL-2001';

  @override
  Future<void> create(Student student) async {}

  @override
  Future<void> update(Student student) async {}

  @override
  Future<void> delete(String academyId, String studentId) async {}
}

class _TestLegacyBranchNotifier extends SelectedBranchNotifier {
  @override
  String? build() => 'br_apex_city';
}

void main() {
  const academyId = 'acad_test_123';
  final testBranches = [
    const Branch(
      id: 'br_main',
      academyId: academyId,
      name: 'Main Campus',
      address: 'Blue Area',
      city: 'Islamabad',
      phone: '123',
    ),
    const Branch(
      id: 'br_city',
      academyId: academyId,
      name: 'City Campus',
      address: 'Saddar',
      city: 'Rawalpindi',
      phone: '456',
    ),
  ];

  final legacyStaff = Staff(
    id: 'stf_legacy',
    academyId: academyId,
    staffId: 'STF-9999',
    fullName: 'Legacy Staff Member',
    branchId: 'br_apex_city', // Unlisted legacy branch!
    phone: '123456',
    email: 'legacy@acaderix.com',
    jobTitle: 'Math Faculty',
    salary: 50000,
    joiningDate: DateTime(2025, 1, 1),
  );

  const legacyStudent = Student(
    id: 'stu_legacy',
    academyId: academyId,
    branchId: 'br_apex_city', // Unlisted legacy branch!
    fullName: 'Legacy Student',
    rollNumber: 'ROL-999',
    academicSession: '2025-2026',
    phone: '123456',
    fatherName: 'Father',
  );

  const legacyCourse = Course(
    id: 'crs_legacy',
    academyId: academyId,
    branchId: 'br_apex_city', // Unlisted legacy branch!
    name: 'Legacy Course',
    courseCode: 'LEG-101',
    teacherId: 'stf_deleted_99', // Unlisted legacy teacher!
    teacherName: 'Deleted Teacher',
    schedule: 'Mon/Wed 9AM',
    room: 'Room 101',
    fee: 3000,
  );

  testWidgets(
      'EditStaffScreen renders gracefully without exception when staff has unlisted branchId (br_apex_city)',
      (tester) async {
    final branchRepo = _MockBranchRepo(testBranches);
    final courseRepo = _MockCourseRepo([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAcademyIdProvider.overrideWithValue(academyId),
          branchRepositoryProvider.overrideWithValue(branchRepo),
          courseRepositoryProvider.overrideWithValue(courseRepo),
        ],
        child: MaterialApp(
          home: EditStaffScreen(staff: legacyStaff),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EditStaffScreen), findsOneWidget);
    expect(find.text('Previous Campus (br_apex_city)'), findsOneWidget);
  });

  testWidgets(
      'AddStaffScreen renders gracefully when selectedBranchIdProvider holds unlisted br_apex_city',
      (tester) async {
    final branchRepo = _MockBranchRepo(testBranches);
    final courseRepo = _MockCourseRepo([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAcademyIdProvider.overrideWithValue(academyId),
          branchRepositoryProvider.overrideWithValue(branchRepo),
          courseRepositoryProvider.overrideWithValue(courseRepo),
          selectedBranchIdProvider.overrideWith(_TestLegacyBranchNotifier.new),
        ],
        child: const MaterialApp(
          home: AddStaffScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AddStaffScreen), findsOneWidget);
    expect(find.text('Main Campus (Default)'), findsOneWidget);
  });

  testWidgets(
      'EditStudentScreen renders gracefully when student has unlisted branchId (br_apex_city)',
      (tester) async {
    final branchRepo = _MockBranchRepo(testBranches);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAcademyIdProvider.overrideWithValue(academyId),
          branchRepositoryProvider.overrideWithValue(branchRepo),
        ],
        child: const MaterialApp(
          home: EditStudentScreen(student: legacyStudent),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EditStudentScreen), findsOneWidget);
    expect(find.text('Previous Campus (br_apex_city)'), findsOneWidget);
  });

  testWidgets(
      'AddStudentScreen renders gracefully when selectedBranchId is unlisted br_apex_city',
      (tester) async {
    final branchRepo = _MockBranchRepo(testBranches);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAcademyIdProvider.overrideWithValue(academyId),
          branchRepositoryProvider.overrideWithValue(branchRepo),
          selectedBranchIdProvider.overrideWith(_TestLegacyBranchNotifier.new),
        ],
        child: const MaterialApp(
          home: AddStudentScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AddStudentScreen), findsOneWidget);
    expect(find.text('Main Campus (Default)'), findsOneWidget);
  });

  testWidgets(
      'EditCourseScreen renders gracefully when course has unlisted branch and unlisted teacher',
      (tester) async {
    final branchRepo = _MockBranchRepo(testBranches);
    final staffRepo = _MockStaffRepo([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAcademyIdProvider.overrideWithValue(academyId),
          branchRepositoryProvider.overrideWithValue(branchRepo),
          staffRepositoryProvider.overrideWithValue(staffRepo),
        ],
        child: const MaterialApp(
          home: EditCourseScreen(course: legacyCourse),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(EditCourseScreen), findsOneWidget);
    expect(find.text('Previous Branch (br_apex_city)'), findsOneWidget);
    expect(find.text('Deleted Teacher (Legacy)'), findsOneWidget);
  });

  testWidgets(
      'AcademyAdminContentHeader global branch dropdown renders gracefully when selectedBranchId is unlisted br_apex_city',
      (tester) async {
    final branchRepo = _MockBranchRepo(testBranches);
    final accessInfo = AcademyAccessInfo(
      state: AcademyAccessState.active,
      academyId: academyId,
      academyName: 'Apex Academy',
      academyCode: 'APX-101',
      planName: 'Pro',
      statusReason: 'Active',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAcademyIdProvider.overrideWithValue(academyId),
          branchRepositoryProvider.overrideWithValue(branchRepo),
          selectedBranchIdProvider.overrideWith(_TestLegacyBranchNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AcademyAdminContentHeader(
              title: 'Staff Management',
              access: accessInfo,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AcademyAdminContentHeader), findsOneWidget);
    expect(find.text('All Branches'), findsWidgets);
  });
}

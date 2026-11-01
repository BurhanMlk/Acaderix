import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/attendance_calculator.dart';
import '../../academics/application/course_repository_provider.dart';
import '../../academics/domain/course.dart';
import '../../academy_admin/application/academy_admin_providers.dart';
import '../../admissions/domain/student.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../branches/domain/branch.dart';
import '../../exams/domain/exam_result.dart';
import '../domain/staff.dart';

/// Provides the currently authenticated staff member's live record.
final currentStaffMemberProvider = Provider<Staff?>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return null;
  final user = auth.user;
  final academyId = user.academyId ?? '';
  if (academyId.isEmpty) return null;

  final staffList =
      ref.watch(staffStreamProvider(academyId)).value ?? const <Staff>[];
  final userStaffId = (user.rollNumber ?? '').toUpperCase();

  for (final s in staffList) {
    if (s.id == user.id) return s;
    if (userStaffId.isNotEmpty && s.staffId.toUpperCase() == userStaffId) {
      return s;
    }
    if (user.email.isNotEmpty &&
        s.email.toLowerCase() == user.email.toLowerCase()) {
      return s;
    }
  }

  // Fallback synthetic staff member matching session user
  return Staff(
    id: user.id,
    academyId: academyId,
    staffId: user.rollNumber ?? 'STAFF',
    fullName: user.displayName.isNotEmpty ? user.displayName : 'Staff Member',
    email: user.email,
    branchId: user.branchId ?? '',
  );
});

/// Resolves the campus branch assigned to the current staff member.
final currentStaffBranchProvider = Provider<Branch?>((ref) {
  final staff = ref.watch(currentStaffMemberProvider);
  if (staff == null) return null;
  final branches =
      ref.watch(branchesStreamProvider(staff.academyId)).value ??
      const <Branch>[];
  if (staff.branchId.isEmpty && branches.isNotEmpty) {
    return branches.first;
  }
  return branches.where((b) => b.id == staff.branchId).firstOrNull;
});

/// Courses / Batches assigned to the current staff member.
final staffAssignedCoursesProvider = Provider<List<Course>>((ref) {
  final staff = ref.watch(currentStaffMemberProvider);
  if (staff == null) return const <Course>[];
  final allCourses =
      ref.watch(coursesStreamProvider(staff.academyId)).value ??
      const <Course>[];

  final teacherMatches = allCourses.where((c) {
    final matchesId = c.teacherId.isNotEmpty && c.teacherId == staff.id;
    final matchesStaffCode =
        c.teacherId.isNotEmpty &&
        c.teacherId.toUpperCase() == staff.staffId.toUpperCase();
    return matchesId || matchesStaffCode;
  }).toList();

  if (teacherMatches.isNotEmpty) return teacherMatches;

  // Fallback: If no courses explicitly assigned to this teacher yet,
  // scope to the teacher's campus branch so they can still manage courses.
  if (staff.branchId.isNotEmpty) {
    final branchCourses =
        allCourses.where((c) => c.branchId == staff.branchId).toList();
    if (branchCourses.isNotEmpty) return branchCourses;
  }

  return allCourses;
});

/// Notifier managing the staff member's actively selected course scope.
class SelectedStaffCourseNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

/// Active course selected by staff on attendance or results screen.
final selectedStaffCourseIdProvider =
    NotifierProvider<SelectedStaffCourseNotifier, String?>(
  SelectedStaffCourseNotifier.new,
);

/// Resolves the active course being viewed by the staff member.
final activeStaffCourseProvider = Provider<Course?>((ref) {
  final courses = ref.watch(staffAssignedCoursesProvider);
  if (courses.isEmpty) return null;
  final selectedId = ref.watch(selectedStaffCourseIdProvider);
  if (selectedId != null) {
    final found = courses.where((c) => c.id == selectedId).firstOrNull;
    if (found != null) return found;
  }
  return courses.first;
});

/// Students scoped to the staff member's active course or branch.
final staffBranchStudentsProvider = Provider<List<Student>>((ref) {
  final staff = ref.watch(currentStaffMemberProvider);
  if (staff == null) return const <Student>[];
  final allStudents =
      ref.watch(studentsStreamProvider(staff.academyId)).value ??
      const <Student>[];

  final activeCourse = ref.watch(activeStaffCourseProvider);
  if (activeCourse != null && activeCourse.enrolledStudentIds.isNotEmpty) {
    final enrolledSet = activeCourse.enrolledStudentIds.toSet();
    final enrolled = allStudents.where((s) => enrolledSet.contains(s.id)).toList();
    if (enrolled.isNotEmpty) return enrolled;
  }

  if (staff.branchId.isEmpty) return allStudents;
  final branchStudents =
      allStudents.where((s) => s.branchId == staff.branchId).toList();
  return branchStudents.isNotEmpty ? branchStudents : allStudents;
});

/// Today's attendance records for the staff member's academy.
final staffTodayAttendanceRecordsProvider = Provider<List<AttendanceRecord>>((
  ref,
) {
  final staff = ref.watch(currentStaffMemberProvider);
  if (staff == null) return const <AttendanceRecord>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final records =
      ref
          .watch(
            attendanceForDateProvider((
              academyId: staff.academyId,
              date: today,
            )),
          )
          .value ??
      const <AttendanceRecord>[];
  return records;
});

/// Metric summary for the staff member's dashboard.
final staffDashboardMetricsProvider = Provider<({
  int totalStudents,
  double attendanceRate,
  int presentToday,
  int absentToday,
  int lateToday,
  int totalCourses,
  int totalExams,
})>((ref) {
  final students = ref.watch(staffBranchStudentsProvider);
  final attendance = ref.watch(staffTodayAttendanceRecordsProvider);
  final staff = ref.watch(currentStaffMemberProvider);
  final courses = ref.watch(staffAssignedCoursesProvider);
  final allExams =
      staff != null
          ? (ref.watch(resultsStreamProvider(staff.academyId)).value ??
              const <ExamResult>[])
          : const <ExamResult>[];

  final studentIds = students.map((s) => s.id).toSet();
  final relevantAttendance =
      attendance.where((a) => studentIds.contains(a.studentId)).toList();

  final present =
      relevantAttendance
          .where((a) => a.status == AttendanceStatus.present)
          .length;
  final absent =
      relevantAttendance
          .where((a) => a.status == AttendanceStatus.absent)
          .length;
  final late =
      relevantAttendance.where((a) => a.status == AttendanceStatus.late).length;

  final rate = AttendanceCalculator.percentage(
    presentDays: present + late,
    totalDays: students.isEmpty ? 1 : students.length,
  );

  return (
    totalStudents: students.length,
    attendanceRate: rate,
    presentToday: present,
    absentToday: absent,
    lateToday: late,
    totalCourses: courses.length,
    totalExams: allExams.length,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/attendance_calculator.dart';
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

/// Students scoped to the staff member's academy (and branch if assigned).
final staffBranchStudentsProvider = Provider<List<Student>>((ref) {
  final staff = ref.watch(currentStaffMemberProvider);
  if (staff == null) return const <Student>[];
  final allStudents =
      ref.watch(studentsStreamProvider(staff.academyId)).value ??
      const <Student>[];
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
  int totalExams,
})>((ref) {
  final students = ref.watch(staffBranchStudentsProvider);
  final attendance = ref.watch(staffTodayAttendanceRecordsProvider);
  final staff = ref.watch(currentStaffMemberProvider);
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
    totalExams: allExams.length,
  );
});

import '../domain/attendance_record.dart';

/// Repository for student attendance records.
abstract interface class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchForDate(String academyId, DateTime date);

  /// Marks attendance for a student/date combination.
  ///
  /// The implementation uses an idempotent document key derived from the
  /// student id and date, so marking the same student twice for one day
  /// overwrites rather than duplicates.
  Future<void> markAttendance(AttendanceRecord record);
}

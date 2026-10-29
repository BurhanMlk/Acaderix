/// Attendance percentage and status-count helpers.
enum AttendanceStatus { present, absent, late, leave }

abstract final class AttendanceCalculator {
  /// Attendance percentage = present-equivalents / total marked days.
  ///
  /// "Late" counts as present; "leave" is typically excluded from the
  /// denominator, so callers pass the appropriate [totalDays].
  static double percentage({required int presentDays, required int totalDays}) {
    if (totalDays <= 0) return 0;
    return (presentDays / totalDays) * 100;
  }

  /// Counts each status in [records].
  static Map<AttendanceStatus, int> count(Iterable<AttendanceStatus> records) {
    final result = <AttendanceStatus, int>{
      for (final status in AttendanceStatus.values) status: 0,
    };
    for (final record in records) {
      result[record] = (result[record] ?? 0) + 1;
    }
    return result;
  }
}

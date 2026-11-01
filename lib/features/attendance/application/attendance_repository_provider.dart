import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_attendance_repository.dart';
import '../domain/attendance_record.dart';
import '../domain/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => FirestoreAttendanceRepository(ref.watch(firestoreProvider)),
);

/// Streams all attendance records for a specific student in an academy.
final studentAttendanceStreamProvider = StreamProvider.family<
    List<AttendanceRecord>,
    ({String academyId, String studentId})>((ref, arg) {
  if (arg.academyId.isEmpty || arg.studentId.isEmpty) {
    return Stream.value(const <AttendanceRecord>[]);
  }
  return ref
      .watch(attendanceRepositoryProvider)
      .watchForStudent(arg.academyId, arg.studentId);
});

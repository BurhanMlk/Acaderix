import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/attendance_record.dart';
import '../domain/attendance_repository.dart';

/// Firestore-backed [AttendanceRepository].
final class FirestoreAttendanceRepository implements AttendanceRepository {
  FirestoreAttendanceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String academyId) =>
      _firestore.collection(FirestorePaths.attendance(academyId));

  @override
  Stream<List<AttendanceRecord>> watchForDate(String academyId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _collection(academyId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));
  }

  @override
  Future<void> markAttendance(AttendanceRecord record) {
    final key = _idempotencyKey(record);
    final data = toFirestoreData(record.toJson())..remove('id');
    return _collection(
      record.academyId,
    ).doc(key).set(data, SetOptions(merge: true));
  }

  String _idempotencyKey(AttendanceRecord record) {
    final date = record.date.toIso8601String().substring(0, 10);
    return '${record.studentId}_$date';
  }

  AttendanceRecord _fromDoc(String id, Map<String, dynamic> data) =>
      AttendanceRecord.fromJson({...data, 'id': id});
}

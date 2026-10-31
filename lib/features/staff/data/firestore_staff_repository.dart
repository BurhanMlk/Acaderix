import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/staff.dart';
import '../domain/staff_repository.dart';

/// Firestore-backed [StaffRepository].
final class FirestoreStaffRepository implements StaffRepository {
  FirestoreStaffRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String academyId) =>
      _firestore.collection(FirestorePaths.staff(academyId));

  @override
  Stream<List<Staff>> watchAll(String academyId) => _collection(academyId)
      .orderBy('fullName')
      .snapshots()
      .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));

  @override
  Future<void> create(Staff staff) {
    final data = toFirestoreData(staff.toJson())..remove('id');
    return _collection(staff.academyId).doc(staff.id).set(data);
  }

  @override
  Future<void> update(Staff staff) {
    final data = toFirestoreData(staff.toJson())..remove('id');
    return _collection(
      staff.academyId,
    ).doc(staff.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String academyId, String staffId) {
    return _collection(academyId).doc(staffId).delete();
  }

  Staff _fromDoc(String id, Map<String, dynamic> data) =>
      Staff.fromJson({...data, 'id': id});
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../../../core/utils/id_generators.dart';
import '../../../core/utils/security_utils.dart';
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
  Future<String> allocateStaffId(String academyId) async {
    final counterRef = _firestore
        .collection(FirestorePaths.academies)
        .doc(academyId)
        .collection('counters')
        .doc('staff');

    return _firestore.runTransaction<String>((tx) async {
      final snap = await tx.get(counterRef);
      int current = 0;
      if (snap.exists) {
        current = (snap.data()?['lastStaffId'] as num?)?.toInt() ?? 0;
      }
      if (current == 0) {
        final existing = await _collection(academyId).get();
        int maxFound = 1000;
        for (final doc in existing.docs) {
          final sId = doc.data()['staffId'] as String? ?? '';
          final match = RegExp(r'\d+').firstMatch(sId);
          if (match != null) {
            final val = int.tryParse(match.group(0)!) ?? 0;
            if (val > maxFound) maxFound = val;
          }
        }
        current = maxFound;
      }
      final nextValue = IdGenerators.nextStaffId(current);
      tx.set(counterRef, {'lastStaffId': nextValue}, SetOptions(merge: true));
      return IdGenerators.formatStaffId(nextValue);
    });
  }

  @override
  Future<void> create(Staff staff) async {
    final data = toFirestoreData(staff.toJson())..remove('id');
    // Never persist plain-text passwords in Firestore
    if (staff.password.isNotEmpty) {
      data['password'] = SecurityUtils.hashPassword(staff.password);
    }
    await _collection(staff.academyId).doc(staff.id).set(data);

    // Sync to global staff_accounts for seamless Staff ID login with hashed credential
    if (staff.staffId.isNotEmpty) {
      await _firestore
          .collection('staff_accounts')
          .doc(staff.staffId.toUpperCase())
          .set({
        'staffId': staff.staffId.toUpperCase(),
        'staffDocId': staff.id,
        'academyId': staff.academyId,
        'branchId': staff.branchId,
        'fullName': staff.fullName,
        'email': staff.email,
        'password': SecurityUtils.hashPassword(staff.password),
        'status': staff.status,
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> update(Staff staff) async {
    final data = toFirestoreData(staff.toJson())..remove('id');
    if (staff.password.isNotEmpty) {
      data['password'] = SecurityUtils.hashPassword(staff.password);
    } else {
      data.remove('password');
    }
    await _collection(
      staff.academyId,
    ).doc(staff.id).set(data, SetOptions(merge: true));

    if (staff.staffId.isNotEmpty) {
      await _firestore
          .collection('staff_accounts')
          .doc(staff.staffId.toUpperCase())
          .set({
        'staffId': staff.staffId.toUpperCase(),
        'staffDocId': staff.id,
        'academyId': staff.academyId,
        'branchId': staff.branchId,
        'fullName': staff.fullName,
        'email': staff.email,
        'status': staff.status,
        if (staff.password.isNotEmpty)
          'password': SecurityUtils.hashPassword(staff.password),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> resetPassword(
    String academyId,
    String staffId,
    String newPassword,
  ) async {
    final docRef = _collection(academyId).doc(staffId);
    final snap = await docRef.get();
    final staffDocStaffId =
        (snap.data()?['staffId'] as String?)?.toUpperCase() ?? '';

    final hashedPassword = SecurityUtils.hashPassword(newPassword);

    await docRef.update({'password': hashedPassword});

    if (staffDocStaffId.isNotEmpty) {
      await _firestore
          .collection('staff_accounts')
          .doc(staffDocStaffId)
          .set({'password': hashedPassword}, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String academyId, String staffId) async {
    final snap = await _collection(academyId).doc(staffId).get();
    final staffCode = (snap.data()?['staffId'] as String?)?.toUpperCase();
    await _collection(academyId).doc(staffId).delete();

    if (staffCode != null && staffCode.isNotEmpty) {
      await _firestore.collection('staff_accounts').doc(staffCode).delete();
    }
  }

  Staff _fromDoc(String id, Map<String, dynamic> data) =>
      Staff.fromJson({...data, 'id': id});
}

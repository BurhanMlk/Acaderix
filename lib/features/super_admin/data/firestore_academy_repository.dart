import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/academy.dart';
import '../domain/academy_repository.dart';

/// Firestore-backed [AcademyRepository].
final class FirestoreAcademyRepository implements AcademyRepository {
  FirestoreAcademyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.academies);

  @override
  Stream<List<Academy>> watchAll() => _collection
      .orderBy('name')
      .snapshots()
      .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));

  @override
  Future<List<Academy>> getAll() async {
    final snapshot = await _collection.orderBy('name').get();
    return mapQueryDocs(snapshot, _fromDoc);
  }

  @override
  Future<Academy?> getById(String id) async {
    final snapshot = await _collection.doc(id).get();
    return mapDocument(snapshot, _fromDoc);
  }

  @override
  Future<void> create(Academy academy) {
    final data = toFirestoreData(academy.toJson())..remove('id');
    return _collection.doc(academy.id).set(data);
  }

  @override
  Future<void> updateStatus(String id, String status) {
    return _collection.doc(id).update({'status': status});
  }

  @override
  Future<void> updateOwnerEmail(String id, String newEmail) async {
    final trimmed = newEmail.trim();
    await _collection.doc(id).update({'ownerEmail': trimmed});
    try {
      final snapshot = await _collection.doc(id).get();
      final ownerUid = snapshot.data()?['ownerUid'] as String?;
      if (ownerUid != null && ownerUid.isNotEmpty) {
        await _firestore
            .collection(FirestorePaths.users)
            .doc(ownerUid)
            .set({'email': trimmed}, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  static const List<String> _subcollections = [
    'branches',
    'staff',
    'students',
    'guardians',
    'classes',
    'courses',
    'subjects',
    'batches',
    'enrollments',
    'attendance',
    'staff_attendance',
    'fee_structures',
    'fee_invoices',
    'fee_payments',
    'exams',
    'results',
    'homework',
    'timetables',
    'salaries',
    'expenses',
    'announcements',
    'audit_logs',
    'counters',
  ];

  @override
  Future<void> delete(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final code = data['code'] as String?;
    final ownerUid = data['ownerUid'] as String?;

    // 1. Cascade delete all documents across all subcollections under this academy
    for (final subcollection in _subcollections) {
      await _deleteSubcollectionDocs(id, subcollection);
    }

    // 2. Cascade delete owner profile and any other user profiles linked to this academy
    await _deleteAssociatedUsers(id, ownerUid);

    // 3. Delete academy code mapping (so the code can be claimed again)
    if (code != null && code.isNotEmpty) {
      try {
        await _firestore
            .collection(FirestorePaths.academyCodes)
            .doc(code.toUpperCase())
            .delete();
      } catch (_) {}
    }

    // 4. Finally, delete the root academy document
    await _collection.doc(id).delete();
  }

  Future<void> _deleteSubcollectionDocs(
    String academyId,
    String subcollection,
  ) async {
    try {
      final snapshot =
          await _collection.doc(academyId).collection(subcollection).get();
      if (snapshot.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      int count = 0;
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<void> _deleteAssociatedUsers(
    String academyId,
    String? ownerUid,
  ) async {
    // Delete owner profile from users collection
    if (ownerUid != null && ownerUid.isNotEmpty) {
      try {
        await _firestore
            .collection(FirestorePaths.users)
            .doc(ownerUid)
            .delete();
      } catch (_) {}
    }

    // Delete any other user documents assigned to this academy
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users)
          .where('academyId', isEqualTo: academyId)
          .get();
      if (snapshot.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      int count = 0;
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (_) {}
  }

  Academy _fromDoc(String id, Map<String, dynamic> data) =>
      Academy.fromJson({...data, 'id': id});
}

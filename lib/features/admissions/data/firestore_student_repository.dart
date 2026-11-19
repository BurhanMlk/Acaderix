import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../../../core/utils/id_generators.dart';
import '../../../core/utils/security_utils.dart';
import '../domain/student.dart';
import '../domain/student_repository.dart';

/// Firestore-backed [StudentRepository].
///
/// Roll numbers are allocated through a Firestore transaction on the
/// `counters/roll_number` document so concurrent admissions can never produce
/// duplicate roll numbers.
final class FirestoreStudentRepository implements StudentRepository {
  FirestoreStudentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String academyId) =>
      _firestore.collection(FirestorePaths.students(academyId));

  @override
  Stream<List<Student>> watchAll(String academyId) => _collection(academyId)
      .orderBy('rollNumber')
      .snapshots()
      .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));

  @override
  Future<Student?> getById(String academyId, String studentId) async {
    final snapshot = await _collection(academyId).doc(studentId).get();
    return mapDocument(snapshot, _fromDoc);
  }

  @override
  Future<String> allocateRollNumber(String academyId) async {
    final counterRef = _firestore.doc(
      '${FirestorePaths.counters(academyId)}/roll_number',
    );

    final next = await _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final current = snapshot.exists
          ? (snapshot.data()?['value'] as num?)?.toInt() ?? 0
          : 0;
      final nextValue = IdGenerators.nextRollNumber(current);
      transaction.set(counterRef, {
        'value': nextValue,
      }, SetOptions(merge: true));
      return nextValue;
    });

    return next.toString();
  }

  @override
  Future<bool> isRollNumberTaken(String academyId, String rollNumber) async {
    final cleanRoll = rollNumber.trim();
    if (cleanRoll.isEmpty) return false;
    final snap = await _collection(academyId)
        .where('rollNumber', isEqualTo: cleanRoll)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Future<void> resetPin(
    String academyId,
    String studentId,
    String newPin,
  ) async {
    final docRef = _collection(academyId).doc(studentId);
    final snap = await docRef.get();
    final sData = snap.data() ?? {};
    final rollNumber = (sData['rollNumber'] as String? ?? '').trim();
    final fullName = sData['fullName'] as String? ?? '';
    final branchId = sData['branchId'] as String? ?? '';
    final status = sData['status'] as String? ?? 'active';

    final hashedPin = SecurityUtils.hashPin(newPin);
    await docRef.update({'pin': hashedPin});

    if (rollNumber.isNotEmpty) {
      final acadSnap = await _firestore
          .collection(FirestorePaths.academies)
          .doc(academyId)
          .get();
      final acadCode =
          (acadSnap.data()?['code'] as String? ?? '').trim().toUpperCase();
      if (acadCode.isNotEmpty) {
        await _firestore
            .collection('student_accounts')
            .doc('${acadCode}_$rollNumber')
            .set({
          'academyCode': acadCode,
          'academyId': academyId,
          'studentDocId': studentId,
          'rollNumber': rollNumber,
          'fullName': fullName,
          'branchId': branchId,
          'pin': hashedPin,
          'status': status,
        }, SetOptions(merge: true));
      }
    }
  }

  @override
  Future<void> create(Student student) async {
    final cleanRoll = student.rollNumber.trim();
    if (cleanRoll.isNotEmpty &&
        await isRollNumberTaken(student.academyId, cleanRoll)) {
      throw StateError(
        'Roll number "$cleanRoll" is already assigned to another student.',
      );
    }
    final data = toFirestoreData(student.toJson())..remove('id');
    await _collection(student.academyId).doc(student.id).set(data);
  }

  @override
  Future<void> update(Student student) {
    final data = toFirestoreData(student.toJson())..remove('id');
    return _collection(
      student.academyId,
    ).doc(student.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String academyId, String studentId) {
    return _collection(academyId).doc(studentId).delete();
  }

  Student _fromDoc(String id, Map<String, dynamic> data) =>
      Student.fromJson({...data, 'id': id});
}

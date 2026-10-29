import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../../../core/utils/id_generators.dart';
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
  Future<void> create(Student student) {
    final data = toFirestoreData(student.toJson())..remove('id');
    return _collection(student.academyId).doc(student.id).set(data);
  }

  @override
  Future<void> update(Student student) {
    final data = toFirestoreData(student.toJson())..remove('id');
    return _collection(
      student.academyId,
    ).doc(student.id).set(data, SetOptions(merge: true));
  }

  Student _fromDoc(String id, Map<String, dynamic> data) =>
      Student.fromJson({...data, 'id': id});
}

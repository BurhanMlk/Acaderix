import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/exam.dart';
import '../domain/exam_result.dart';
import '../domain/exam_repository.dart';

/// Firestore-backed [ExamRepository].
final class FirestoreExamRepository implements ExamRepository {
  FirestoreExamRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _exams(String academyId) =>
      _firestore.collection(FirestorePaths.exams(academyId));

  CollectionReference<Map<String, dynamic>> _results(String academyId) =>
      _firestore.collection(FirestorePaths.results(academyId));

  @override
  Stream<List<Exam>> watchExams(String academyId) => _exams(academyId)
      .orderBy('examDate', descending: true)
      .snapshots()
      .map((snapshot) => mapQueryDocs(snapshot, _examFromDoc));

  @override
  Stream<List<ExamResult>> watchResults(String academyId, {String? studentId}) {
    var query = _results(academyId).orderBy('studentId');
    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    return query.snapshots().map(
      (snapshot) => mapQueryDocs(snapshot, _resultFromDoc),
    );
  }

  @override
  Future<void> createExam(Exam exam) {
    final data = toFirestoreData(exam.toJson())..remove('id');
    return _exams(exam.academyId).doc(exam.id).set(data);
  }

  @override
  Future<void> saveResult(ExamResult result) {
    final data = toFirestoreData(result.toJson())..remove('id');
    return _results(
      result.academyId,
    ).doc(result.id).set(data, SetOptions(merge: true));
  }

  Exam _examFromDoc(String id, Map<String, dynamic> data) =>
      Exam.fromJson({...data, 'id': id});

  ExamResult _resultFromDoc(String id, Map<String, dynamic> data) =>
      ExamResult.fromJson({...data, 'id': id});
}

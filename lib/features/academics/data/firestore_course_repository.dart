import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/course.dart';
import '../domain/course_repository.dart';

/// Firestore implementation of [CourseRepository].
final class FirestoreCourseRepository implements CourseRepository {
  FirestoreCourseRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String academyId) =>
      _firestore.collection(FirestorePaths.courses(academyId));

  @override
  Stream<List<Course>> watchAll(String academyId) {
    return _collection(academyId)
        .snapshots()
        .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));
  }

  @override
  Stream<List<Course>> watchByBranch(String academyId, String branchId) {
    return _collection(academyId)
        .where('branchId', isEqualTo: branchId)
        .snapshots()
        .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));
  }

  @override
  Stream<List<Course>> watchByTeacher(String academyId, String teacherId) {
    return _collection(academyId)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));
  }

  @override
  Future<Course?> getById(String academyId, String courseId) async {
    final doc = await _collection(academyId).doc(courseId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _fromDoc(doc.id, doc.data()!);
  }

  @override
  Future<void> saveCourse(Course course) {
    final data = toFirestoreData(course.toJson())..remove('id');
    return _collection(course.academyId).doc(course.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteCourse(String academyId, String courseId) {
    return _collection(academyId).doc(courseId).delete();
  }

  @override
  Future<void> enrollStudents(
    String academyId,
    String courseId,
    List<String> studentIds,
  ) {
    return _collection(academyId).doc(courseId).update({
      'enrolledStudentIds': FieldValue.arrayUnion(studentIds),
    });
  }

  @override
  Future<void> unenrollStudent(
    String academyId,
    String courseId,
    String studentId,
  ) {
    return _collection(academyId).doc(courseId).update({
      'enrolledStudentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  Course _fromDoc(String id, Map<String, dynamic> data) =>
      Course.fromJson({...data, 'id': id});
}

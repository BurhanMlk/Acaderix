import 'course.dart';

/// Contract for courses and batches repository.
abstract interface class CourseRepository {
  Stream<List<Course>> watchAll(String academyId);

  Stream<List<Course>> watchByBranch(String academyId, String branchId);

  Stream<List<Course>> watchByTeacher(String academyId, String teacherId);

  Future<Course?> getById(String academyId, String courseId);

  Future<void> saveCourse(Course course);

  Future<void> deleteCourse(String academyId, String courseId);

  Future<void> enrollStudents(String academyId, String courseId, List<String> studentIds);

  Future<void> unenrollStudent(String academyId, String courseId, String studentId);
}

import '../domain/student.dart';

/// Repository for student records within an academy.
abstract interface class StudentRepository {
  Stream<List<Student>> watchAll(String academyId);
  Future<Student?> getById(String academyId, String studentId);

  /// Allocates the next six-digit roll number atomically.
  Future<String> allocateRollNumber(String academyId);

  Future<void> create(Student student);
  Future<void> update(Student student);
  Future<void> delete(String academyId, String studentId);
}

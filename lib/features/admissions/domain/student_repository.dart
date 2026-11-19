import '../domain/student.dart';

/// Repository for student records within an academy.
abstract interface class StudentRepository {
  Stream<List<Student>> watchAll(String academyId);
  Future<Student?> getById(String academyId, String studentId);

  /// Allocates the next six-digit roll number atomically.
  Future<String> allocateRollNumber(String academyId);

  /// Returns true if [rollNumber] is already assigned to a student in [academyId].
  Future<bool> isRollNumberTaken(String academyId, String rollNumber);

  /// Resets the login PIN for a student.
  Future<void> resetPin(String academyId, String studentId, String newPin);

  Future<void> create(Student student);
  Future<void> update(Student student);
  Future<void> delete(String academyId, String studentId);
}

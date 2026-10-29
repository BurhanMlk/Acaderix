import '../domain/exam.dart';
import '../domain/exam_result.dart';

/// Repository for exams and student results.
abstract interface class ExamRepository {
  Stream<List<Exam>> watchExams(String academyId);
  Stream<List<ExamResult>> watchResults(String academyId, {String? studentId});

  Future<void> createExam(Exam exam);
  Future<void> saveResult(ExamResult result);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam_result.freezed.dart';
part 'exam_result.g.dart';

/// A student's result for one exam/subject.
@freezed
abstract class ExamResult with _$ExamResult {
  const factory ExamResult({
    required String id,
    required String academyId,
    required String examId,
    required String studentId,
    @Default(0) double obtainedMarks,
    @Default(0) double totalMarks,
    @Default('') String grade,
    @Default(false) bool passed,
    @Default(false) bool isPublished,
  }) = _ExamResult;

  factory ExamResult.fromJson(Map<String, dynamic> json) =>
      _$ExamResultFromJson(json);
}

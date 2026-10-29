import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam.freezed.dart';
part 'exam.g.dart';

/// An examination definition.
@freezed
abstract class Exam with _$Exam {
  const factory Exam({
    required String id,
    required String academyId,
    @Default('') String name,
    @Default('monthly') String category,
    @Default('') String classId,
    @Default('') String subjectId,
    @Default(0) double totalMarks,
    DateTime? examDate,
    @Default(false) bool isPublished,
  }) = _Exam;

  factory Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);
}

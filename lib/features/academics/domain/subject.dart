import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject.freezed.dart';
part 'subject.g.dart';

/// A subject within a course.
@freezed
abstract class Subject with _$Subject {
  const factory Subject({
    required String id,
    required String academyId,
    @Default('') String name,
    @Default('') String code,
    @Default(100) double totalMarks,
  }) = _Subject;

  factory Subject.fromJson(Map<String, dynamic> json) =>
      _$SubjectFromJson(json);
}

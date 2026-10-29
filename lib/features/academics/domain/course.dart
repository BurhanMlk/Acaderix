import 'package:freezed_annotation/freezed_annotation.dart';

part 'course.freezed.dart';
part 'course.g.dart';

/// A course offered by an academy (e.g. "Matric", "FSc Pre-Medical").
@freezed
abstract class Course with _$Course {
  const factory Course({
    required String id,
    required String academyId,
    @Default('') String name,
    @Default('') String description,
    @Default(true) bool isActive,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
}

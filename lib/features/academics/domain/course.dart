import 'package:freezed_annotation/freezed_annotation.dart';

part 'course.freezed.dart';
part 'course.g.dart';

/// A course/batch offered by an academy (e.g. "Physics 10th - Batch A", "MDCAT Chemistry").
@freezed
abstract class Course with _$Course {
  const factory Course({
    required String id,
    required String academyId,
    @Default('') String branchId,
    @Default('') String name,
    @Default('') String courseCode,
    @Default('') String description,
    @Default('') String teacherId,
    @Default('') String teacherName,
    @Default(<String>[]) List<String> enrolledStudentIds,
    @Default('') String schedule,
    @Default('') String room,
    @Default(0.0) double fee,
    @Default(true) bool isActive,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
}

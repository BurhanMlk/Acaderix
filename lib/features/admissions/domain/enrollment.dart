import 'package:freezed_annotation/freezed_annotation.dart';

part 'enrollment.freezed.dart';
part 'enrollment.g.dart';

/// Links a student to a class and batch with optional subject selection.
@freezed
abstract class Enrollment with _$Enrollment {
  const factory Enrollment({
    required String id,
    required String academyId,
    required String studentId,
    @Default('') String classId,
    @Default('') String batchId,
    @Default(<String>[]) List<String> subjectIds,
    @Default('active') String status,
    DateTime? enrolledAt,
  }) = _Enrollment;

  factory Enrollment.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'student.freezed.dart';
part 'student.g.dart';

/// A student enrolled in an academy.
@freezed
abstract class Student with _$Student {
  const factory Student({
    required String id,
    required String academyId,
    @Default('') String fullName,
    @Default('') String fatherName,
    @Default('') String motherName,
    DateTime? dateOfBirth,
    @Default('') String gender,
    @Default('') String phone,
    @Default('') String guardianPhone,
    @Default('') String guardianRelation,
    @Default('') String address,
    @Default('') String photoUrl,
    DateTime? admissionDate,
    @Default('') String previousInstitute,
    @Default('') String academicSession,
    @Default('') String rollNumber,
    @Default('active') String status,
    @Default('') String notes,
    @Default('') String branchId,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);
}

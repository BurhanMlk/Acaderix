// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Enrollment _$EnrollmentFromJson(Map<String, dynamic> json) => _Enrollment(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  studentId: json['studentId'] as String,
  classId: json['classId'] as String? ?? '',
  batchId: json['batchId'] as String? ?? '',
  subjectIds:
      (json['subjectIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  status: json['status'] as String? ?? 'active',
  enrolledAt: json['enrolledAt'] == null
      ? null
      : DateTime.parse(json['enrolledAt'] as String),
);

Map<String, dynamic> _$EnrollmentToJson(_Enrollment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academyId': instance.academyId,
      'studentId': instance.studentId,
      'classId': instance.classId,
      'batchId': instance.batchId,
      'subjectIds': instance.subjectIds,
      'status': instance.status,
      'enrolledAt': instance.enrolledAt?.toIso8601String(),
    };

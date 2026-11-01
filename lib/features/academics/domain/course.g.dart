// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Course _$CourseFromJson(Map<String, dynamic> json) => _Course(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  branchId: json['branchId'] as String? ?? '',
  name: json['name'] as String? ?? '',
  courseCode: json['courseCode'] as String? ?? '',
  description: json['description'] as String? ?? '',
  teacherId: json['teacherId'] as String? ?? '',
  teacherName: json['teacherName'] as String? ?? '',
  enrolledStudentIds:
      (json['enrolledStudentIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  schedule: json['schedule'] as String? ?? '',
  room: json['room'] as String? ?? '',
  fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$CourseToJson(_Course instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'branchId': instance.branchId,
  'name': instance.name,
  'courseCode': instance.courseCode,
  'description': instance.description,
  'teacherId': instance.teacherId,
  'teacherName': instance.teacherName,
  'enrolledStudentIds': instance.enrolledStudentIds,
  'schedule': instance.schedule,
  'room': instance.room,
  'fee': instance.fee,
  'isActive': instance.isActive,
};

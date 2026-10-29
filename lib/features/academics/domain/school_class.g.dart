// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SchoolClass _$SchoolClassFromJson(Map<String, dynamic> json) => _SchoolClass(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  name: json['name'] as String? ?? '',
  courseId: json['courseId'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$SchoolClassToJson(_SchoolClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academyId': instance.academyId,
      'name': instance.name,
      'courseId': instance.courseId,
      'isActive': instance.isActive,
    };

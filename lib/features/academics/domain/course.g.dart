// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Course _$CourseFromJson(Map<String, dynamic> json) => _Course(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$CourseToJson(_Course instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'name': instance.name,
  'description': instance.description,
  'isActive': instance.isActive,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subject _$SubjectFromJson(Map<String, dynamic> json) => _Subject(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  name: json['name'] as String? ?? '',
  code: json['code'] as String? ?? '',
  totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 100,
);

Map<String, dynamic> _$SubjectToJson(_Subject instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'name': instance.name,
  'code': instance.code,
  'totalMarks': instance.totalMarks,
};

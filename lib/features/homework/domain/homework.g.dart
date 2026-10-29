// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homework.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Homework _$HomeworkFromJson(Map<String, dynamic> json) => _Homework(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  title: json['title'] as String? ?? '',
  description: json['description'] as String? ?? '',
  subjectId: json['subjectId'] as String? ?? '',
  batchId: json['batchId'] as String? ?? '',
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  attachmentUrls:
      (json['attachmentUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  assignedById: json['assignedById'] as String? ?? '',
);

Map<String, dynamic> _$HomeworkToJson(_Homework instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'title': instance.title,
  'description': instance.description,
  'subjectId': instance.subjectId,
  'batchId': instance.batchId,
  'dueDate': instance.dueDate?.toIso8601String(),
  'attachmentUrls': instance.attachmentUrls,
  'assignedById': instance.assignedById,
};

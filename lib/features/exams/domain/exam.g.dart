// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Exam _$ExamFromJson(Map<String, dynamic> json) => _Exam(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  name: json['name'] as String? ?? '',
  category: json['category'] as String? ?? 'monthly',
  classId: json['classId'] as String? ?? '',
  subjectId: json['subjectId'] as String? ?? '',
  totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0,
  examDate: json['examDate'] == null
      ? null
      : DateTime.parse(json['examDate'] as String),
  isPublished: json['isPublished'] as bool? ?? false,
);

Map<String, dynamic> _$ExamToJson(_Exam instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'name': instance.name,
  'category': instance.category,
  'classId': instance.classId,
  'subjectId': instance.subjectId,
  'totalMarks': instance.totalMarks,
  'examDate': instance.examDate?.toIso8601String(),
  'isPublished': instance.isPublished,
};

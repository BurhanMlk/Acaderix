// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExamResult _$ExamResultFromJson(Map<String, dynamic> json) => _ExamResult(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  examId: json['examId'] as String,
  studentId: json['studentId'] as String,
  obtainedMarks: (json['obtainedMarks'] as num?)?.toDouble() ?? 0,
  totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 0,
  grade: json['grade'] as String? ?? '',
  passed: json['passed'] as bool? ?? false,
  isPublished: json['isPublished'] as bool? ?? false,
);

Map<String, dynamic> _$ExamResultToJson(_ExamResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academyId': instance.academyId,
      'examId': instance.examId,
      'studentId': instance.studentId,
      'obtainedMarks': instance.obtainedMarks,
      'totalMarks': instance.totalMarks,
      'grade': instance.grade,
      'passed': instance.passed,
      'isPublished': instance.isPublished,
    };

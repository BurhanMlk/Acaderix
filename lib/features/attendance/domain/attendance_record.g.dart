// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceRecord _$AttendanceRecordFromJson(Map<String, dynamic> json) =>
    _AttendanceRecord(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      studentId: json['studentId'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] == null
          ? AttendanceStatus.present
          : const AttendanceStatusConverter().fromJson(
              json['status'] as String,
            ),
      batchId: json['batchId'] as String? ?? '',
      markedById: json['markedById'] as String? ?? '',
    );

Map<String, dynamic> _$AttendanceRecordToJson(_AttendanceRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academyId': instance.academyId,
      'studentId': instance.studentId,
      'date': instance.date.toIso8601String(),
      'status': const AttendanceStatusConverter().toJson(instance.status),
      'batchId': instance.batchId,
      'markedById': instance.markedById,
    };

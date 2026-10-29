// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Batch _$BatchFromJson(Map<String, dynamic> json) => _Batch(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  name: json['name'] as String? ?? '',
  classId: json['classId'] as String? ?? '',
  branchId: json['branchId'] as String? ?? '',
  capacity: (json['capacity'] as num?)?.toInt() ?? 0,
  timing: json['timing'] as String? ?? '',
  classroom: json['classroom'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$BatchToJson(_Batch instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'name': instance.name,
  'classId': instance.classId,
  'branchId': instance.branchId,
  'capacity': instance.capacity,
  'timing': instance.timing,
  'classroom': instance.classroom,
  'isActive': instance.isActive,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_structure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeeStructure _$FeeStructureFromJson(Map<String, dynamic> json) =>
    _FeeStructure(
      id: json['id'] as String,
      academyId: json['academyId'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      frequency: json['frequency'] as String? ?? 'monthly',
      dueDayOfMonth: (json['dueDayOfMonth'] as num?)?.toInt() ?? 15,
      lateFinePerDay: (json['lateFinePerDay'] as num?)?.toDouble() ?? 0,
      lateFineMax: (json['lateFineMax'] as num?)?.toDouble() ?? 500,
      branchId: json['branchId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FeeStructureToJson(_FeeStructure instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academyId': instance.academyId,
      'title': instance.title,
      'description': instance.description,
      'amount': instance.amount,
      'frequency': instance.frequency,
      'dueDayOfMonth': instance.dueDayOfMonth,
      'lateFinePerDay': instance.lateFinePerDay,
      'lateFineMax': instance.lateFineMax,
      'branchId': instance.branchId,
      'courseId': instance.courseId,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

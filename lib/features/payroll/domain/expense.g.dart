// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  category: json['category'] as String? ?? '',
  amount: (json['amount'] as num?)?.toDouble() ?? 0,
  description: json['description'] as String? ?? '',
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  recordedById: json['recordedById'] as String? ?? '',
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'category': instance.category,
  'amount': instance.amount,
  'description': instance.description,
  'date': instance.date?.toIso8601String(),
  'recordedById': instance.recordedById,
};

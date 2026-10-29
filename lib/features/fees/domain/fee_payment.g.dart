// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeePayment _$FeePaymentFromJson(Map<String, dynamic> json) => _FeePayment(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  studentId: json['studentId'] as String,
  invoiceId: json['invoiceId'] as String? ?? '',
  amount: (json['amount'] as num?)?.toDouble() ?? 0,
  method: json['method'] as String? ?? '',
  reference: json['reference'] as String? ?? '',
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  receivedById: json['receivedById'] as String? ?? '',
);

Map<String, dynamic> _$FeePaymentToJson(_FeePayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academyId': instance.academyId,
      'studentId': instance.studentId,
      'invoiceId': instance.invoiceId,
      'amount': instance.amount,
      'method': instance.method,
      'reference': instance.reference,
      'paidAt': instance.paidAt?.toIso8601String(),
      'receivedById': instance.receivedById,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeeInvoice _$FeeInvoiceFromJson(Map<String, dynamic> json) => _FeeInvoice(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  studentId: json['studentId'] as String,
  invoiceNo: json['invoiceNo'] as String? ?? '',
  title: json['title'] as String? ?? '',
  baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 0,
  fine: (json['fine'] as num?)?.toDouble() ?? 0,
  discount: (json['discount'] as num?)?.toDouble() ?? 0,
  scholarship: (json['scholarship'] as num?)?.toDouble() ?? 0,
  paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  issuedAt: json['issuedAt'] == null
      ? null
      : DateTime.parse(json['issuedAt'] as String),
  status: json['status'] as String? ?? 'unpaid',
);

Map<String, dynamic> _$FeeInvoiceToJson(_FeeInvoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academyId': instance.academyId,
      'studentId': instance.studentId,
      'invoiceNo': instance.invoiceNo,
      'title': instance.title,
      'baseAmount': instance.baseAmount,
      'fine': instance.fine,
      'discount': instance.discount,
      'scholarship': instance.scholarship,
      'paidAmount': instance.paidAmount,
      'dueDate': instance.dueDate?.toIso8601String(),
      'issuedAt': instance.issuedAt?.toIso8601String(),
      'status': instance.status,
    };

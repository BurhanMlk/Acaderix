import 'package:freezed_annotation/freezed_annotation.dart';

part 'fee_invoice.freezed.dart';
part 'fee_invoice.g.dart';

/// A fee invoice issued to a student.
///
/// Invoices are immutable once posted; changes are modeled as adjustments or
/// separate invoices, never as in-place edits of paid amounts.
@freezed
abstract class FeeInvoice with _$FeeInvoice {
  const FeeInvoice._();

  const factory FeeInvoice({
    required String id,
    required String academyId,
    required String studentId,
    @Default('') String invoiceNo,
    @Default('') String title,
    @Default(0) double baseAmount,
    @Default(0) double fine,
    @Default(0) double discount,
    @Default(0) double scholarship,
    @Default(0) double paidAmount,
    DateTime? dueDate,
    DateTime? issuedAt,
    @Default('unpaid') String status,
  }) = _FeeInvoice;

  factory FeeInvoice.fromJson(Map<String, dynamic> json) =>
      _$FeeInvoiceFromJson(json);

  /// Total payable for this invoice.
  double get totalAmount => baseAmount + fine - discount - scholarship;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'fee_payment.freezed.dart';
part 'fee_payment.g.dart';

/// An immutable payment/transaction against a student ledger.
@freezed
abstract class FeePayment with _$FeePayment {
  const factory FeePayment({
    required String id,
    required String academyId,
    required String studentId,
    @Default('') String invoiceId,
    @Default(0) double amount,
    @Default('') String method,
    @Default('') String reference,
    DateTime? paidAt,
    @Default('') String receivedById,
  }) = _FeePayment;

  factory FeePayment.fromJson(Map<String, dynamic> json) =>
      _$FeePaymentFromJson(json);
}

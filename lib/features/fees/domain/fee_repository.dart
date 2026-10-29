import '../domain/fee_invoice.dart';
import '../domain/fee_payment.dart';

/// Repository for fee invoices and payments.
abstract interface class FeeRepository {
  Stream<List<FeeInvoice>> watchInvoices(String academyId, {String? studentId});

  Stream<List<FeePayment>> watchPayments(String academyId, {String? studentId});

  Future<void> createInvoice(FeeInvoice invoice);

  /// Posts a payment and updates the linked invoice's paid amount atomically.
  Future<void> recordPayment(FeePayment payment);
}

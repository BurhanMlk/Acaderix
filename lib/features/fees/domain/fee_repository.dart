import '../domain/fee_invoice.dart';
import '../domain/fee_payment.dart';
import '../domain/fee_structure.dart';

/// Repository for fee structures, invoices, and payments.
abstract interface class FeeRepository {
  // Fee Structures
  Stream<List<FeeStructure>> watchFeeStructures(String academyId);
  Future<void> saveFeeStructure(FeeStructure structure);
  Future<void> deleteFeeStructure(String academyId, String structureId);

  // Invoices
  Stream<List<FeeInvoice>> watchInvoices(String academyId, {String? studentId});
  Future<void> createInvoice(FeeInvoice invoice);

  /// Bulk-create invoices for a list of students from a fee structure.
  Future<int> bulkCreateInvoices({
    required FeeStructure structure,
    required List<String> studentIds,
    required String monthLabel,
    required DateTime dueDate,
  });

  // Payments
  Stream<List<FeePayment>> watchPayments(String academyId, {String? studentId});

  /// Posts a payment and updates the linked invoice's paid amount atomically.
  Future<void> recordPayment(FeePayment payment);
}

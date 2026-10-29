import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/domain/fee_calculator.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/fee_invoice.dart';
import '../domain/fee_payment.dart';
import '../domain/fee_repository.dart';

/// Firestore-backed [FeeRepository].
///
/// Payments are posted with a transaction so an invoice's `paidAmount` can
/// never drift out of sync with its payment records.
final class FirestoreFeeRepository implements FeeRepository {
  FirestoreFeeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _invoices(String academyId) =>
      _firestore.collection(FirestorePaths.feeInvoices(academyId));

  CollectionReference<Map<String, dynamic>> _payments(String academyId) =>
      _firestore.collection(FirestorePaths.feePayments(academyId));

  @override
  Stream<List<FeeInvoice>> watchInvoices(
    String academyId, {
    String? studentId,
  }) {
    var query = _invoices(academyId).orderBy('issuedAt', descending: true);
    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    return query.snapshots().map(
      (snapshot) => mapQueryDocs(snapshot, _invoiceFromDoc),
    );
  }

  @override
  Stream<List<FeePayment>> watchPayments(
    String academyId, {
    String? studentId,
  }) {
    var query = _payments(academyId).orderBy('paidAt', descending: true);
    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    return query.snapshots().map(
      (snapshot) => mapQueryDocs(snapshot, _paymentFromDoc),
    );
  }

  @override
  Future<void> createInvoice(FeeInvoice invoice) {
    final data = toFirestoreData(invoice.toJson())..remove('id');
    return _invoices(invoice.academyId).doc(invoice.id).set(data);
  }

  @override
  Future<void> recordPayment(FeePayment payment) async {
    final invoiceRef = _invoices(payment.academyId).doc(payment.invoiceId);
    final paymentRef = _payments(payment.academyId).doc(payment.id);

    await _firestore.runTransaction((transaction) async {
      final invoiceSnapshot = await transaction.get(invoiceRef);
      if (!invoiceSnapshot.exists) {
        throw StateError('Invoice ${payment.invoiceId} does not exist.');
      }
      final invoice = _invoiceFromDoc(
        invoiceSnapshot.id,
        invoiceSnapshot.data()!,
      );
      final newPaid = invoice.paidAmount + payment.amount;
      final settled = FeeCalculator.isSettled(invoice.totalAmount, newPaid);

      transaction.set(
        paymentRef,
        toFirestoreData(payment.toJson())..remove('id'),
      );
      transaction.update(invoiceRef, {
        'paidAmount': newPaid,
        'status': settled ? 'paid' : 'partial',
      });
    });
  }

  FeeInvoice _invoiceFromDoc(String id, Map<String, dynamic> data) =>
      FeeInvoice.fromJson({...fromFirestoreData(data), 'id': id});

  FeePayment _paymentFromDoc(String id, Map<String, dynamic> data) =>
      FeePayment.fromJson({...fromFirestoreData(data), 'id': id});
}

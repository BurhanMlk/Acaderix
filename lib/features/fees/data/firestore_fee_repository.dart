import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/domain/fee_calculator.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/fee_invoice.dart';
import '../domain/fee_payment.dart';
import '../domain/fee_repository.dart';
import '../domain/fee_structure.dart';

/// Firestore-backed [FeeRepository].
///
/// Payments are posted with a transaction so an invoice's `paidAmount` can
/// never drift out of sync with its payment records.
final class FirestoreFeeRepository implements FeeRepository {
  FirestoreFeeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _uuid = Uuid();

  // ── Collection references ───────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _structures(String academyId) =>
      _firestore.collection(FirestorePaths.feeStructures(academyId));

  CollectionReference<Map<String, dynamic>> _invoices(String academyId) =>
      _firestore.collection(FirestorePaths.feeInvoices(academyId));

  CollectionReference<Map<String, dynamic>> _payments(String academyId) =>
      _firestore.collection(FirestorePaths.feePayments(academyId));

  // ── Fee Structures ──────────────────────────────────────────────────

  @override
  Stream<List<FeeStructure>> watchFeeStructures(String academyId) {
    return _structures(academyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => mapQueryDocs(snapshot, _structureFromDoc));
  }

  @override
  Future<void> saveFeeStructure(FeeStructure structure) {
    final data = toFirestoreData(structure.toJson())..remove('id');
    return _structures(
      structure.academyId,
    ).doc(structure.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteFeeStructure(String academyId, String structureId) {
    return _structures(academyId).doc(structureId).delete();
  }

  // ── Invoices ────────────────────────────────────────────────────────

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
  Future<void> createInvoice(FeeInvoice invoice) {
    final data = toFirestoreData(invoice.toJson())..remove('id');
    return _invoices(invoice.academyId).doc(invoice.id).set(data);
  }

  @override
  Future<int> bulkCreateInvoices({
    required FeeStructure structure,
    required List<String> studentIds,
    required String monthLabel,
    required DateTime dueDate,
  }) async {
    if (studentIds.isEmpty) return 0;

    final now = DateTime.now();
    final timestampSuffix = now.millisecondsSinceEpoch.toString().substring(
      now.millisecondsSinceEpoch.toString().length - 6,
    );

    // Firestore batches are capped at 500 operations.
    const batchLimit = 500;
    var count = 0;

    for (var i = 0; i < studentIds.length; i += batchLimit) {
      final batch = _firestore.batch();
      final end = (i + batchLimit > studentIds.length)
          ? studentIds.length
          : i + batchLimit;

      for (var j = i; j < end; j++) {
        final invoiceId = _uuid.v4();
        final invoiceNo = 'INV-$timestampSuffix-$j';

        final invoice = FeeInvoice(
          id: invoiceId,
          academyId: structure.academyId,
          studentId: studentIds[j],
          invoiceNo: invoiceNo,
          title: '${structure.title} — $monthLabel',
          baseAmount: structure.amount,
          fine: 0,
          discount: 0,
          scholarship: 0,
          paidAmount: 0,
          status: 'unpaid',
          dueDate: dueDate,
          issuedAt: now,
        );

        final data = toFirestoreData(invoice.toJson())..remove('id');
        batch.set(_invoices(structure.academyId).doc(invoiceId), data);
      }

      await batch.commit();
      count += end - i;
    }

    return count;
  }

  // ── Payments ────────────────────────────────────────────────────────

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

  // ── Mappers ─────────────────────────────────────────────────────────

  FeeStructure _structureFromDoc(String id, Map<String, dynamic> data) =>
      FeeStructure.fromJson({...fromFirestoreData(data), 'id': id});

  FeeInvoice _invoiceFromDoc(String id, Map<String, dynamic> data) =>
      FeeInvoice.fromJson({...fromFirestoreData(data), 'id': id});

  FeePayment _paymentFromDoc(String id, Map<String, dynamic> data) =>
      FeePayment.fromJson({...fromFirestoreData(data), 'id': id});
}

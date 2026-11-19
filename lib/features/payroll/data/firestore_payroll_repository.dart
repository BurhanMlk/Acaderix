import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../../staff/domain/staff.dart';
import '../domain/payroll_repository.dart';
import '../domain/salary_record.dart';

/// Firestore-backed [PayrollRepository] storing records under
/// `academies/{academyId}/salaries`.
final class FirestorePayrollRepository implements PayrollRepository {
  FirestorePayrollRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String academyId) =>
      _firestore.collection(FirestorePaths.salaries(academyId));

  @override
  Stream<List<SalaryRecord>> watchAll(
    String academyId, {
    String? staffId,
    String? monthKey,
  }) {
    Query<Map<String, dynamic>> query = _collection(academyId);
    if (staffId != null && staffId.isNotEmpty) {
      query = query.where('staffId', isEqualTo: staffId);
    }
    if (monthKey != null && monthKey.isNotEmpty) {
      query = query.where('monthKey', isEqualTo: monthKey);
    }
    return query.snapshots().map((snapshot) {
      final list = mapQueryDocs(snapshot, _fromDoc);
      list.sort((a, b) {
        final monthCmp = b.monthKey.compareTo(a.monthKey);
        if (monthCmp != 0) return monthCmp;
        return a.staffName.compareTo(b.staffName);
      });
      return list;
    });
  }

  @override
  Future<void> createOrUpdate(SalaryRecord record) {
    final data = record.toJson();
    return _collection(
      record.academyId,
    ).doc(record.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<int> generateMonthlyPayroll({
    required String academyId,
    required List<Staff> staffList,
    required String monthKey,
    required String monthLabel,
  }) async {
    final activeStaff = staffList
        .where((s) => s.status == 'active' && s.salary > 0)
        .toList();
    if (activeStaff.isEmpty) return 0;

    final existingSnap = await _collection(
      academyId,
    ).where('monthKey', isEqualTo: monthKey).get();
    final existingStaffIds = existingSnap.docs
        .map((d) => d.data()['staffId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final toCreate = activeStaff
        .where((s) => !existingStaffIds.contains(s.id))
        .toList();
    if (toCreate.isEmpty) return 0;

    final now = DateTime.now();
    const batchLimit = 500;
    var createdCount = 0;

    for (var i = 0; i < toCreate.length; i += batchLimit) {
      final batch = _firestore.batch();
      final end = (i + batchLimit > toCreate.length)
          ? toCreate.length
          : i + batchLimit;

      for (var j = i; j < end; j++) {
        final member = toCreate[j];
        final docId = '${monthKey}_${member.id}';
        final record = SalaryRecord(
          id: docId,
          academyId: academyId,
          staffId: member.id,
          staffCode: member.staffId,
          staffName: member.fullName,
          jobTitle: member.jobTitle,
          branchId: member.branchId,
          monthKey: monthKey,
          monthLabel: monthLabel,
          baseSalary: member.salary,
          status: 'pending',
          createdAt: now,
        );
        batch.set(_collection(academyId).doc(docId), record.toJson());
      }

      await batch.commit();
      createdCount += end - i;
    }

    return createdCount;
  }

  @override
  Future<void> markAsPaid(
    String academyId,
    String recordId, {
    required String paymentMethod,
    String notes = '',
  }) {
    return _collection(academyId).doc(recordId).set({
      'status': 'paid',
      'paymentMethod': paymentMethod,
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      'paidAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> delete(String academyId, String recordId) {
    return _collection(academyId).doc(recordId).delete();
  }

  SalaryRecord _fromDoc(String id, Map<String, dynamic> data) =>
      SalaryRecord.fromJson(data, id: id);
}

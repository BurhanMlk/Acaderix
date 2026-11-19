import '../../staff/domain/staff.dart';
import 'salary_record.dart';

/// Repository for staff payroll and salary disbursement records.
abstract interface class PayrollRepository {
  Stream<List<SalaryRecord>> watchAll(
    String academyId, {
    String? staffId,
    String? monthKey,
  });

  Future<void> createOrUpdate(SalaryRecord record);

  /// Generates pending salary records for active [staffList] for [monthKey],
  /// skipping any staff member who already has a record for that month.
  /// Returns the number of newly created records.
  Future<int> generateMonthlyPayroll({
    required String academyId,
    required List<Staff> staffList,
    required String monthKey,
    required String monthLabel,
  });

  Future<void> markAsPaid(
    String academyId,
    String recordId, {
    required String paymentMethod,
    String notes = '',
  });

  Future<void> delete(String academyId, String recordId);
}

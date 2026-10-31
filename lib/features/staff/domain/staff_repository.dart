import '../domain/staff.dart';

/// Repository for staff records within an academy.
abstract interface class StaffRepository {
  Stream<List<Staff>> watchAll(String academyId);
  Future<void> create(Staff staff);
  Future<void> update(Staff staff);
  Future<void> delete(String academyId, String staffId);
}

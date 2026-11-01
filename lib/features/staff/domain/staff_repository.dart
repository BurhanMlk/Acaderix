import '../domain/staff.dart';

/// Repository for staff records within an academy.
abstract interface class StaffRepository {
  Stream<List<Staff>> watchAll(String academyId);
  Future<void> create(Staff staff);
  Future<void> update(Staff staff);
  Future<void> delete(String academyId, String staffId);

  /// Atomically allocates the next sequential human-friendly Staff ID (e.g. 'STF-1001').
  Future<String> allocateStaffId(String academyId);

  /// Resets the login password for a staff member.
  Future<void> resetPassword(String academyId, String staffId, String newPassword);
}

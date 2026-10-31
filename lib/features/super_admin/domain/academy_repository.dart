import '../domain/academy.dart';

/// Repository for platform-wide academy management (Super Admin only).
abstract interface class AcademyRepository {
  Stream<List<Academy>> watchAll();
  Future<List<Academy>> getAll();
  Future<Academy?> getById(String id);
  Future<void> create(Academy academy);
  Future<void> updateStatus(String id, String status);
  Future<void> updateOwnerEmail(String id, String newEmail);
  Future<void> delete(String id);
}

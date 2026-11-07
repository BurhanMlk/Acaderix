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

  /// Super Admin custom creation of academy and owner account with customized package quotas.
  Future<String> createCustomAcademyWithPackage({
    required String academyName,
    required String academyCode,
    required String address,
    required String city,
    required String province,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    required String ownerPhone,
    required int maxBranches,
    required int maxStudents,
    required int monthlyFee,
    String billingCycle = 'monthly',
    String status = 'active',
    String paymentStatus = 'paid',
    String? logoUrl,
    String? cnic,
  });
}

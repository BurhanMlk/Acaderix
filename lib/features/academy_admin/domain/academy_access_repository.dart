import '../domain/academy_access_models.dart';

/// Repository interface for checking an academy's account standing and subscription status.
abstract class AcademyAccessRepository {
  /// Watches the real-time access and subscription status of an academy.
  Stream<AcademyAccessInfo> watchAcademyAccess(String academyId);

  /// Fetches the current access and subscription status of an academy once.
  Future<AcademyAccessInfo> getAcademyAccess(String academyId);

  /// Locates an academy by owner or admin email and verifies its standing
  /// BEFORE issuing any authentication token or session.
  Future<AcademyAccessInfo> findAndCheckAcademyByEmail(String email);
}

import '../domain/branch.dart';

/// Repository for academy branches.
abstract interface class BranchRepository {
  Stream<List<Branch>> watchAll(String academyId);
  Future<void> create(Branch branch);
  Future<void> update(Branch branch);
  Future<void> delete(String academyId, String branchId);
}

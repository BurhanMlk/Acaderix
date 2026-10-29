import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/branch.dart';
import '../domain/branch_repository.dart';

/// Firestore-backed [BranchRepository].
final class FirestoreBranchRepository implements BranchRepository {
  FirestoreBranchRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Branch>> watchAll(String academyId) => _firestore
      .collection(FirestorePaths.branches(academyId))
      .orderBy('name')
      .snapshots()
      .map((snapshot) => mapQueryDocs(snapshot, _fromDoc));

  @override
  Future<void> create(Branch branch) {
    final data = toFirestoreData(branch.toJson())..remove('id');
    return _firestore
        .collection(FirestorePaths.branches(branch.academyId))
        .doc(branch.id)
        .set(data);
  }

  Branch _fromDoc(String id, Map<String, dynamic> data) =>
      Branch.fromJson({...data, 'id': id});
}

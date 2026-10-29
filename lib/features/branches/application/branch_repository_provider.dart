import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_branch_repository.dart';
import '../domain/branch_repository.dart';

final branchRepositoryProvider = Provider<BranchRepository>(
  (ref) => FirestoreBranchRepository(ref.watch(firestoreProvider)),
);

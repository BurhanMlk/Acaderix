import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_fee_repository.dart';
import '../domain/fee_repository.dart';

final feeRepositoryProvider = Provider<FeeRepository>(
  (ref) => FirestoreFeeRepository(ref.watch(firestoreProvider)),
);

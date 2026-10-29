import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_staff_repository.dart';
import '../domain/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => FirestoreStaffRepository(ref.watch(firestoreProvider)),
);

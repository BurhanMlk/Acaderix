import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_academy_repository.dart';
import '../domain/academy_repository.dart';

final academyRepositoryProvider = Provider<AcademyRepository>(
  (ref) => FirestoreAcademyRepository(ref.watch(firestoreProvider)),
);

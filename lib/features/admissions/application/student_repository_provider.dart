import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_student_repository.dart';
import '../domain/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => FirestoreStudentRepository(ref.watch(firestoreProvider)),
);

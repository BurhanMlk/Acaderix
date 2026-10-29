import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_exam_repository.dart';
import '../domain/exam_repository.dart';

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => FirestoreExamRepository(ref.watch(firestoreProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/firebase_services.dart';
import '../data/firestore_course_repository.dart';
import '../domain/course.dart';
import '../domain/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => FirestoreCourseRepository(ref.watch(firestoreProvider)),
);

/// Streams all courses for an academy.
final coursesStreamProvider = StreamProvider.family<List<Course>, String>(
  (ref, academyId) {
    if (academyId.isEmpty) return const Stream.empty();
    return ref.watch(courseRepositoryProvider).watchAll(academyId);
  },
);

/// Streams courses taught by a specific teacher.
final teacherCoursesStreamProvider =
    StreamProvider.family<List<Course>, ({String academyId, String teacherId})>(
  (ref, params) {
    if (params.academyId.isEmpty || params.teacherId.isEmpty) {
      return const Stream.empty();
    }
    return ref
        .watch(courseRepositoryProvider)
        .watchByTeacher(params.academyId, params.teacherId);
  },
);

/// Streams courses scoped to a specific branch.
final branchCoursesStreamProvider =
    StreamProvider.family<List<Course>, ({String academyId, String branchId})>(
  (ref, params) {
    if (params.academyId.isEmpty || params.branchId.isEmpty) {
      return const Stream.empty();
    }
    return ref
        .watch(courseRepositoryProvider)
        .watchByBranch(params.academyId, params.branchId);
  },
);

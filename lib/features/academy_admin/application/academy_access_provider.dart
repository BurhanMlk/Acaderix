import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/roles.dart';
import '../../../core/network/firebase_services.dart';
import '../../../shared/current_academy_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/firestore_academy_access_repository.dart';
import '../domain/academy_access_models.dart';
import '../domain/academy_access_repository.dart';

/// Provider for [AcademyAccessRepository].
final academyAccessRepositoryProvider = Provider<AcademyAccessRepository>(
  (ref) => FirestoreAcademyAccessRepository(ref.watch(firestoreProvider)),
);

/// Real-time stream provider for the currently signed-in academy admin's access standing.
final academyAccessProvider = StreamProvider<AcademyAccessInfo>((ref) {
  final auth = ref.watch(authControllerProvider);
  final user = switch (auth) {
    AuthAuthenticated(:final user) when user.role == AppRole.academyAdmin =>
      user,
    _ => null,
  };

  if (user == null) {
    return Stream.value(const AcademyAccessInfo(
      state: AcademyAccessState.notFound,
      academyId: '',
      statusReason: 'User is not signed in as an academy admin.',
    ));
  }

  final academyId = ref.watch(currentAcademyIdProvider) ?? user.academyId ?? '';
  final repo = ref.watch(academyAccessRepositoryProvider);

  return repo.watchAcademyAccess(academyId);
});

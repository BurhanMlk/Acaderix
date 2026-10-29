import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_state.dart';

/// The academy id of the currently signed-in user, or null.
///
/// Academy-scoped screens use this to scope their repositories. Tenant
/// isolation is ultimately enforced by security rules and claims, not by this
/// client-side convenience.
final currentAcademyIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return switch (auth) {
    AuthAuthenticated(:final user) => user.academyId,
    _ => null,
  };
});

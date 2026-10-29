import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_user.dart';

part 'auth_state.freezed.dart';

/// The authentication state of the application.
@freezed
sealed class AuthState with _$AuthState {
  const AuthState._();

  /// Initial state before the first auth resolution completes.
  const factory AuthState.unknown() = AuthUnknown;

  /// No authenticated user.
  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  /// An authenticated user with an assigned role.
  const factory AuthState.authenticated(AppUser user) = AuthAuthenticated;
}

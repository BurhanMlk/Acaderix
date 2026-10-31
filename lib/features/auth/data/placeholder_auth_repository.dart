import 'dart:async';

import '../../../core/errors/app_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_state.dart';

/// Development-only auth repository used until Firebase is configured.
///
/// It reports an unauthenticated state and rejects sign-in attempts with a
/// clear configuration error. No production code depends on this class.
final class PlaceholderAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> authStateChanges() async* {
    yield const AuthState.unauthenticated();
  }

  @override
  Future<AuthState> currentState() async => const AuthState.unauthenticated();

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw const AuthException(
      'Sign in is unavailable until Firebase is configured. See README.md.',
      code: 'firebase-not-configured',
    );
  }

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw const AuthException(
      'Registration is unavailable until Firebase is configured.',
      code: 'firebase-not-configured',
    );
  }

  @override
  Future<AppUser> refreshCurrentUser() {
    throw const AuthException(
      'Authentication is unavailable until Firebase is configured.',
      code: 'firebase-not-configured',
    );
  }

  @override
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) {
    throw const AuthException(
      'Student sign in is unavailable until Firebase is configured.',
      code: 'firebase-not-configured',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw const AuthException(
      'Password reset is unavailable until Firebase is configured.',
      code: 'firebase-not-configured',
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

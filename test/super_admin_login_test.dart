import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/app/app.dart';
import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/core/errors/app_exception.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/super_admin/application/super_admin_providers.dart';
import 'package:academy_management/features/super_admin/domain/academy.dart';

class _MockSuperAdminAuthRepository implements AuthRepository {
  _MockSuperAdminAuthRepository({this.shouldFail = false});

  final bool shouldFail;
  AuthState _current = const AuthState.unauthenticated();
  final _controller = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AuthState> currentState() async => _current;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw const AuthException(
        'Incorrect email or password.',
        code: 'invalid-credentials',
      );
    }
    const user = AppUser(
      id: 'super_admin_uid',
      email: 'admin@acadrix.com',
      role: AppRole.superAdmin,
    );
    _current = const AuthState.authenticated(user);
    _controller.add(_current);
    return user;
  }

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> refreshCurrentUser() async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signInAsStaff({
    required String identifier,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {
    _current = const AuthState.unauthenticated();
    _controller.add(_current);
  }
}

void main() {
  testWidgets('Super Admin login navigates and authenticates successfully', (
    tester,
  ) async {
    final mockRepo = _MockSuperAdminAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
          academiesStreamProvider.overrideWith((ref) => Stream.value(<Academy>[])),
        ],
        child: const AcademyApp(),
      ),
    );

    // Initial load: advance frames to let splash resolve to welcome
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('Welcome to Acadrix'), findsOneWidget);

    // Ensure "Log In" button is visible and tap it
    final loginButton = find.text('Log In');
    expect(loginButton, findsOneWidget);
    await tester.ensureVisible(loginButton);
    await tester.pumpAndSettle();
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify Super Admin tile exists on Login Selection Screen
    expect(find.text('Super Admin'), findsOneWidget);
    expect(
      find.text('Platform management & global controls'),
      findsOneWidget,
    );

    // Tap "Super Admin" tile
    await tester.tap(find.text('Super Admin'));
    await tester.pumpAndSettle();

    // Verify on Super Admin Login screen
    expect(find.text('Super Admin Login'), findsOneWidget);

    // Fill in credentials
    final emailField = find.widgetWithText(TextFormField, 'Email');
    final passwordField = find.widgetWithText(TextFormField, 'Password');

    await tester.enterText(emailField, 'admin@acadrix.com');
    await tester.enterText(passwordField, 'Admin@12345');

    // Tap "Sign In as Super Admin"
    final submitButton = find.text('Sign In as Super Admin');
    expect(submitButton, findsOneWidget);
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);

    // Wait for auth resolution and redirect
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify Super Admin Dashboard is reached
    expect(find.text('Platform Overview'), findsOneWidget);
  });

  testWidgets('Super Admin login shows error message on invalid credentials', (
    tester,
  ) async {
    final mockRepo = _MockSuperAdminAuthRepository(shouldFail: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const AcademyApp(),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();

    final loginButton = find.text('Log In');
    await tester.ensureVisible(loginButton);
    await tester.pumpAndSettle();
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Super Admin'));
    await tester.pumpAndSettle();

    final emailField = find.widgetWithText(TextFormField, 'Email');
    final passwordField = find.widgetWithText(TextFormField, 'Password');

    await tester.enterText(emailField, 'admin@acadrix.com');
    await tester.enterText(passwordField, 'wrongpassword');

    final submitButton = find.text('Sign In as Super Admin');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify error message is displayed
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });
}

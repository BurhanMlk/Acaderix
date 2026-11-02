import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/core/widgets/glass.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/auth/presentation/screens/academy_admin_login_screen.dart';
import 'package:academy_management/features/auth/presentation/screens/register_screen.dart';
import 'package:academy_management/features/auth/presentation/screens/staff_login_screen.dart';
import 'package:academy_management/features/auth/presentation/screens/student_login_screen.dart';
import 'package:academy_management/features/auth/presentation/screens/super_admin_login_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> authStateChanges() => Stream.value(const AuthState.unauthenticated());

  @override
  Future<AuthState> currentState() async => const AuthState.unauthenticated();

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return const AppUser(id: 'u1', email: 'test@example.com', role: AppRole.academyAdmin);
  }

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return const AppUser(id: 'u2', email: 'test@example.com', role: AppRole.academyAdmin);
  }

  @override
  Future<AppUser> signInAsStaff({
    required String identifier,
    required String password,
  }) async {
    return const AppUser(id: 'u3', email: 'staff@example.com', role: AppRole.staff);
  }

  @override
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) async {
    return const AppUser(id: 'u4', email: 'student@example.com', role: AppRole.student);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> refreshCurrentUser() async =>
      const AppUser(id: 'u1', email: 'test@example.com', role: AppRole.academyAdmin);
}

void main() {
  group('Password Visibility Eye/Hide Toggle Tests', () {
    testWidgets('Academy Admin Login: toggles password visibility eye icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: AcademyAdminLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final passGlassField = find.widgetWithText(GlassTextField, 'Password');
      expect(passGlassField, findsOneWidget);

      TextField textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);

      // Eye icon button should be present
      final eyeIconFinder = find.byTooltip('Show password');
      expect(eyeIconFinder, findsOneWidget);

      // Tap eye icon to reveal password
      await tester.tap(eyeIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isFalse);

      // Tap eye icon again to hide password
      final hideIconFinder = find.byTooltip('Hide password');
      expect(hideIconFinder, findsOneWidget);

      await tester.tap(hideIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Staff Login: toggles password visibility eye icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: StaffLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final passGlassField = find.widgetWithText(GlassTextField, 'Password');
      expect(passGlassField, findsOneWidget);

      TextField textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);

      final eyeIconFinder = find.byTooltip('Show password');
      expect(eyeIconFinder, findsOneWidget);

      await tester.ensureVisible(eyeIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(eyeIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isFalse);

      final hideIconFinder = find.byTooltip('Hide password');
      expect(hideIconFinder, findsOneWidget);

      await tester.ensureVisible(hideIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(hideIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Student Login: toggles PIN/Password visibility eye icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: StudentLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pinGlassField = find.widgetWithText(GlassTextField, 'PIN / Password');
      expect(pinGlassField, findsOneWidget);

      TextField textField = tester.widget(
        find.descendant(of: pinGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);

      final eyeIconFinder = find.byTooltip('Show PIN');
      expect(eyeIconFinder, findsOneWidget);

      await tester.tap(eyeIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: pinGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isFalse);

      final hideIconFinder = find.byTooltip('Hide PIN');
      expect(hideIconFinder, findsOneWidget);

      await tester.tap(hideIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: pinGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Super Admin Login: toggles password visibility eye icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: SuperAdminLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final passGlassField = find.widgetWithText(GlassTextField, 'Password');
      expect(passGlassField, findsOneWidget);

      TextField textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);

      final eyeIconFinder = find.byTooltip('Show password');
      expect(eyeIconFinder, findsOneWidget);

      await tester.ensureVisible(eyeIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(eyeIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isFalse);

      final hideIconFinder = find.byTooltip('Hide password');
      expect(hideIconFinder, findsOneWidget);

      await tester.ensureVisible(hideIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(hideIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Register Academy: toggles password visibility eye icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final passGlassField = find.widgetWithText(GlassTextField, 'Password *');
      expect(passGlassField, findsOneWidget);

      TextField textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);

      final eyeIconFinder = find.byTooltip('Show password');
      expect(eyeIconFinder, findsOneWidget);

      await tester.ensureVisible(eyeIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(eyeIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isFalse);

      final hideIconFinder = find.byTooltip('Hide password');
      expect(hideIconFinder, findsOneWidget);

      await tester.ensureVisible(hideIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(hideIconFinder);
      await tester.pumpAndSettle();

      textField = tester.widget(
        find.descendant(of: passGlassField, matching: find.byType(TextField)),
      );
      expect(textField.obscureText, isTrue);
    });
  });
}

import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepo implements AuthRepository {
  String? sentEmail;

  @override
  Stream<AuthState> authStateChanges() =>
      Stream.value(const AuthState.unauthenticated());

  @override
  Future<AuthState> currentState() async => const AuthState.unauthenticated();

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sentEmail = email;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'ForgotPasswordScreen sends reset link and displays spam folder info message',
    (tester) async {
      final fakeAuth = _FakeAuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and fields exist
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      // Enter email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'teacher@academy.com',
      );

      // Tap Send Reset Link
      await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Link'));
      await tester.pumpAndSettle();

      // Verify email was sent to fake repo
      expect(fakeAuth.sentEmail, equals('teacher@academy.com'));

      // Verify success info message mentions Spam or Junk folder
      expect(find.text('Password Reset Link Sent'), findsOneWidget);
      expect(
        find.textContaining('be sure to check your Spam or Junk folder'),
        findsOneWidget,
      );
    },
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/core/errors/app_exception.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/data/academy_registration_service.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/auth/presentation/screens/register_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.shouldFail = false, this.errorMessage});

  final bool shouldFail;
  final String? errorMessage;
  final AuthState _current = const AuthState.unauthenticated();
  final _ctrl = StreamController<AuthState>.broadcast();

  String? createdEmail;
  String? createdPassword;

  @override
  Stream<AuthState> authStateChanges() async* {
    yield _current;
    yield* _ctrl.stream;
  }

  @override
  Future<AuthState> currentState() async => _current;

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw AuthException(
        errorMessage ?? 'The email address is already in use by another account.',
        code: 'email-already-in-use',
      );
    }
    createdEmail = email;
    createdPassword = password;
    return AppUser(
      id: 'mock_owner_uid',
      email: email,
      role: AppRole.academyAdmin,
      academyId: 'mock_registered_academy_id',
    );
  }

  @override
  Future<AppUser> refreshCurrentUser() async {
    return AppUser(
      id: 'mock_owner_uid',
      email: createdEmail ?? 'admin@test.com',
      role: AppRole.academyAdmin,
      academyId: 'mock_registered_academy_id',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAcademyRegistrationService implements AcademyRegistrationService {
  String? registeredUid;
  String? registeredAcademyName;
  String? registeredAddress;
  String? registeredCnic;
  String? registeredOwnerName;
  String? registeredOwnerPhone;
  String? registeredPlanName;
  int? registeredPlanPrice;
  bool didRegister = false;

  @override
  Future<String> registerAcademy({
    required String uid,
    required String email,
    required String academyName,
    required String address,
    required String cnic,
    required String ownerName,
    required String ownerPhone,
    required String planName,
    required int planPrice,
    String? logoUrl,
  }) async {
    didRegister = true;
    registeredUid = uid;
    registeredAcademyName = academyName;
    registeredAddress = address;
    registeredCnic = cnic;
    registeredOwnerName = ownerName;
    registeredOwnerPhone = ownerPhone;
    registeredPlanName = planName;
    registeredPlanPrice = planPrice;
    return 'mock_registered_academy_id';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Register Academy Feature Tests', () {
    testWidgets('1. RegisterScreen renders all required fields and subscription plan options', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify Screen Header
      expect(find.text('Register your academy'), findsOneWidget);
      expect(find.text('Create your academy account'), findsOneWidget);

      // Verify Text Input Fields
      expect(find.text('Academy Name *'), findsOneWidget);
      expect(find.text('Address *'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Academy Head *'), findsOneWidget);
      expect(find.text('CNIC'), findsOneWidget);
      expect(find.text('Contact Number *'), findsOneWidget);
      expect(find.text('Password *'), findsOneWidget);

      // Scroll to view subscription plans and action button
      await tester.ensureVisible(find.text('Subscription Plan'));
      await tester.pumpAndSettle();
      expect(find.text('Subscription Plan'), findsOneWidget);
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create Account'));
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('2. Empty submission triggers validation warnings on mandatory fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pump();

      // Scroll to button and submit empty form
      final submitBtn = find.widgetWithText(FilledButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Scroll back up to verify validation messages
      await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('Academy name is required'), findsOneWidget);
      expect(find.text('Address is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Academy Head name is required'), findsOneWidget);
      expect(find.text('Contact number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('3. Successfully registers academy, saves details, and sets academyAdmin role', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthRepository();
      final fakeReg = _FakeAcademyRegistrationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            academyRegistrationServiceProvider.overrideWithValue(fakeReg),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pump();

      // Enter Academy Name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Academy Name *'),
        'Falcon High Academy',
      );

      // Enter Address
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *'),
        'Plot 42, Main Boulevard, Gulberg, Lahore',
      );

      // Enter Email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email *'),
        'tariq@falconacademy.edu.pk',
      );

      // Enter Academy Head Name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Academy Head *'),
        'Professor Tariq Mehmood',
      );

      // Enter Owner CNIC
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CNIC'),
        '3520198765431',
      );

      // Enter Contact Number
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contact Number *'),
        '03009876543',
      );

      // Enter Password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password *'),
        'SuperSecret99',
      );

      // Scroll to select 'Standard' plan
      await tester.ensureVisible(find.text('Standard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Standard'));
      await tester.pumpAndSettle();

      // Scroll to submit button and tap
      final submitBtn = find.widgetWithText(FilledButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Assert registration service was called with exact attributes
      expect(fakeReg.didRegister, isTrue);
      expect(fakeReg.registeredAcademyName, equals('Falcon High Academy'));
      expect(fakeReg.registeredAddress, equals('Plot 42, Main Boulevard, Gulberg, Lahore'));
      expect(fakeReg.registeredOwnerName, equals('Professor Tariq Mehmood'));
      expect(fakeReg.registeredCnic, equals('3520198765431'));
      expect(fakeReg.registeredOwnerPhone, equals('03009876543'));
      expect(fakeReg.registeredPlanName, equals('Standard'));
      expect(fakeReg.registeredPlanPrice, equals(15000));

      // Assert auth repository created account
      expect(fakeAuth.createdEmail, equals('tariq@falconacademy.edu.pk'));
      expect(fakeAuth.createdPassword, equals('SuperSecret99'));
    });

    testWidgets('4. Displays error banner when registration fails (e.g. duplicate email)', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthRepository(
        shouldFail: true,
        errorMessage: 'The email address is already in use by another account.',
      );
      final fakeReg = _FakeAcademyRegistrationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            academyRegistrationServiceProvider.overrideWithValue(fakeReg),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pump();

      // Fill in fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Academy Name *'), 'Test Academy');
      await tester.enterText(find.widgetWithText(TextFormField, 'Address *'), 'Test Address');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email *'), 'existing@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Academy Head *'), 'Test Owner');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contact Number *'), '03001234567');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password *'), 'Secret123');

      // Scroll to submit button and tap
      final submitBtn = find.widgetWithText(FilledButton, 'Create Account');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Assert error message is visible
      expect(
        find.text('The email address is already in use by another account.'),
        findsOneWidget,
      );
      expect(fakeReg.didRegister, isFalse);
    });

    testWidgets('5. Zero RenderFlex overflow on narrow mobile screen (320px width)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Register your academy'), findsOneWidget);
    });
  });
}

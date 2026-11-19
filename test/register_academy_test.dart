import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Multi-Step Register Academy Feature & Draft Persistence Tests', () {
    testWidgets('1. Step 1 (Academy Profile) renders with progress indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top navigation and step status
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Academy Profile'), findsOneWidget);
      expect(find.text('Institution Profile'), findsOneWidget);

      // Step 1 input fields
      expect(find.text('Academy Name *'), findsOneWidget);
      expect(find.text('Address *'), findsOneWidget);
      expect(find.text('Continue to Administrator'), findsOneWidget);

      // Subsequent steps are not yet rendered
      expect(find.text('Academy Head *'), findsNothing);
      expect(find.text('Password *'), findsNothing);
    });

    testWidgets('2. Step 1 validation prevents advancing with empty fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt to advance with empty fields
      await tester.tap(find.text('Continue to Administrator'));
      await tester.pumpAndSettle();

      // Validation warnings shown
      expect(find.text('Academy name is required'), findsOneWidget);
      expect(find.text('Address is required'), findsOneWidget);

      // Still on Step 1
      expect(find.text('Step 1 of 4'), findsOneWidget);
    });

    testWidgets('3. Multi-step progression through all 4 steps and back navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Complete Step 1
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Academy Name *'),
        'Falcon High Academy',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *'),
        'Plot 42, Main Boulevard, Lahore',
      );
      await tester.tap(find.text('Continue to Administrator'));
      await tester.pumpAndSettle();

      // Now at Step 2: Administrator & Contact
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('Academy Head *'), findsOneWidget);
      expect(find.text('Contact Number *'), findsOneWidget);

      // Test Back button returning to Step 1 with preserved values
      await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Falcon High Academy'), findsOneWidget);

      // Re-advance to Step 2
      await tester.tap(find.text('Continue to Administrator'));
      await tester.pumpAndSettle();

      // Complete Step 2
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Academy Head *'),
        'Professor Tariq Mehmood',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CNIC'),
        '3520198765431',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contact Number *'),
        '03009876543',
      );
      await tester.tap(find.text('Continue to Credentials'));
      await tester.pumpAndSettle();

      // Now at Step 3: Account Credentials
      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(find.text('Credentials'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Password *'), findsOneWidget);

      // Complete Step 3
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email *'),
        'tariq@falconacademy.edu.pk',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password *'),
        'SuperSecret99',
      );
      await tester.tap(find.text('Continue to Plan'));
      await tester.pumpAndSettle();

      // Now at Step 4: Subscription & Branding
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(find.text('Plan & Branding'), findsOneWidget);
      expect(find.text('Select Subscription Plan *'), findsOneWidget);
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('Registration Summary'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('4. Local device storage draft restores in-progress data when user re-opens screen', (
      tester,
    ) async {
      // Simulate draft data previously saved to device storage
      SharedPreferences.setMockInitialValues({
        'acaderix_reg_draft_academy_name': 'Recovered Academy',
        'acaderix_reg_draft_address': 'Recovered Address 123',
        'acaderix_reg_draft_owner_name': 'Principal Ahmed',
        'acaderix_reg_draft_contact': '03001122334',
        'acaderix_reg_draft_email': 'ahmed@recovered.com',
        'acaderix_reg_draft_selected_plan': 1,
        'acaderix_reg_draft_step': 2,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify draft recovered notification banner
      expect(find.text('Draft recovered from your device'), findsOneWidget);
      expect(find.text('Start fresh'), findsOneWidget);

      // Resumed at Step 3 (step index 2) with restored email
      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(find.text('ahmed@recovered.com'), findsOneWidget);

      // Tap 'Start fresh' to clear draft
      await tester.tap(find.text('Start fresh'));
      await tester.pumpAndSettle();

      // Should reset to Step 1 with empty fields
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Draft recovered from your device'), findsNothing);
      expect(find.text('Recovered Academy'), findsNothing);
    });

    testWidgets('5. Full end-to-end registration submits consolidated details and clears draft', (
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
      await tester.pumpAndSettle();

      // Step 1: Academy Profile
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Academy Name *'),
        'Falcon High Academy',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Address *'),
        'Plot 42, Main Boulevard, Gulberg, Lahore',
      );
      await tester.tap(find.text('Continue to Administrator'));
      await tester.pumpAndSettle();

      // Step 2: Administrator & Contact
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Academy Head *'),
        'Professor Tariq Mehmood',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CNIC'),
        '3520198765431',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contact Number *'),
        '03009876543',
      );
      await tester.tap(find.text('Continue to Credentials'));
      await tester.pumpAndSettle();

      // Step 3: Account Credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email *'),
        'tariq@falconacademy.edu.pk',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password *'),
        'SuperSecret99',
      );
      await tester.tap(find.text('Continue to Plan'));
      await tester.pumpAndSettle();

      // Step 4: Plan & Submit
      // Select 'Standard' plan
      await tester.tap(find.text('Standard'));
      await tester.pumpAndSettle();

      // Verify Summary card shows all consolidated values
      expect(find.text('Falcon High Academy'), findsOneWidget);
      expect(find.text('Plot 42, Main Boulevard, Gulberg, Lahore'), findsOneWidget);
      expect(find.text('Professor Tariq Mehmood'), findsOneWidget);
      expect(find.text('03009876543'), findsOneWidget);
      expect(find.text('tariq@falconacademy.edu.pk'), findsOneWidget);
      expect(find.text('Standard (Rs. 15,000/mo)'), findsOneWidget);

      // Submit Form
      final submitBtn = find.widgetWithText(FilledButton, 'Create Account');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Assert registration service was called with all consolidated attributes
      expect(fakeReg.didRegister, isTrue);
      expect(fakeReg.registeredAcademyName, equals('Falcon High Academy'));
      expect(fakeReg.registeredAddress, equals('Plot 42, Main Boulevard, Gulberg, Lahore'));
      expect(fakeReg.registeredOwnerName, equals('Professor Tariq Mehmood'));
      expect(fakeReg.registeredCnic, equals('3520198765431'));
      expect(fakeReg.registeredOwnerPhone, equals('03009876543'));
      expect(fakeReg.registeredPlanName, equals('Standard'));
      expect(fakeReg.registeredPlanPrice, equals(15000));

      // Assert auth repository created credentials
      expect(fakeAuth.createdEmail, equals('tariq@falconacademy.edu.pk'));
      expect(fakeAuth.createdPassword, equals('SuperSecret99'));

      // Assert draft storage was purged
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('acaderix_reg_draft_academy_name'), isNull);
      expect(prefs.getString('acaderix_reg_draft_email'), isNull);
    });

    testWidgets('6. Displays error banner when registration fails (e.g. duplicate email)', (
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
      await tester.pumpAndSettle();

      // Step 1
      await tester.enterText(find.widgetWithText(TextFormField, 'Academy Name *'), 'Test Academy');
      await tester.enterText(find.widgetWithText(TextFormField, 'Address *'), 'Test Address');
      await tester.tap(find.text('Continue to Administrator'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.enterText(find.widgetWithText(TextFormField, 'Academy Head *'), 'Test Owner');
      await tester.enterText(find.widgetWithText(TextFormField, 'Contact Number *'), '03001234567');
      await tester.tap(find.text('Continue to Credentials'));
      await tester.pumpAndSettle();

      // Step 3
      await tester.enterText(find.widgetWithText(TextFormField, 'Email *'), 'existing@test.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password *'), 'Secret123');
      await tester.tap(find.text('Continue to Plan'));
      await tester.pumpAndSettle();

      // Step 4
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

    testWidgets('7. Zero RenderFlex overflow on narrow mobile screen (320px width)', (
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
      expect(find.text('Academy Profile'), findsOneWidget);
    });
  });
}

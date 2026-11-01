import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/core/errors/app_exception.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/super_admin/application/academy_repository_provider.dart';
import 'package:academy_management/features/super_admin/application/super_admin_providers.dart';
import 'package:academy_management/features/super_admin/domain/academy.dart';
import 'package:academy_management/features/super_admin/domain/academy_repository.dart';
import 'package:academy_management/features/super_admin/presentation/screens/academy_admin_reset_password_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/academy_details_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/super_admin_reset_password_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/super_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAcademyRepository implements AcademyRepository {
  final List<Academy> _academies = [
    Academy(
      id: 'acad_1',
      code: 'ACD-TEST1',
      name: 'Premier Science Academy',
      city: 'Lahore',
      province: 'Punjab',
      address: '123 Main Blvd',
      ownerName: 'Dr. Tariq',
      ownerEmail: 'tariq@test.com',
      ownerPhone: '03001234567',
      status: 'active',
      branchCount: 2,
      registrationDate: DateTime(2026, 10, 1),
    ),
    Academy(
      id: 'acad_2',
      code: 'ACD-TEST2',
      name: 'Apex Coaching Center',
      city: 'Karachi',
      province: 'Sindh',
      address: '45 Clifton',
      ownerName: 'Prof. Aslam',
      ownerEmail: 'aslam@test.com',
      ownerPhone: '03009876543',
      status: 'pending',
      branchCount: 1,
      registrationDate: DateTime(2026, 10, 15),
    ),
  ];

  bool deleted = false;
  String? updatedStatus;

  @override
  Stream<List<Academy>> watchAll() => Stream.value(_academies);

  @override
  Future<List<Academy>> getAll() async => _academies;

  @override
  Future<Academy?> getById(String id) async =>
      _academies.where((a) => a.id == id).firstOrNull;

  @override
  Future<void> create(Academy academy) async {
    _academies.add(academy);
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    updatedStatus = status;
  }

  String? updatedOwnerEmail;

  @override
  Future<void> updateOwnerEmail(String id, String newEmail) async {
    updatedOwnerEmail = newEmail;
    final index = _academies.indexWhere((a) => a.id == id);
    if (index != -1) {
      _academies[index] = _academies[index].copyWith(ownerEmail: newEmail);
    }
  }

  @override
  Future<void> delete(String id) async {
    deleted = true;
    _academies.removeWhere((a) => a.id == id);
  }
}

class _FakeAuthRepo implements AuthRepository {
  bool passwordChanged = false;
  String? lastOldPassword;
  String? lastNewPassword;
  bool shouldFailOldPassword = false;

  @override
  Stream<AuthState> authStateChanges() async* {
    yield const AuthState.authenticated(
      AppUser(
        id: 'super_admin_id',
        email: 'admin@acadrix.com',
        role: AppRole.superAdmin,
      ),
    );
  }

  @override
  Future<AuthState> currentState() async {
    return const AuthState.authenticated(
      AppUser(
        id: 'super_admin_id',
        email: 'admin@acadrix.com',
        role: AppRole.superAdmin,
      ),
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (shouldFailOldPassword) {
      throw const AuthException(
        'Current password is incorrect.',
        code: 'wrong-password',
      );
    }
    lastOldPassword = currentPassword;
    lastNewPassword = newPassword;
    passwordChanged = true;
  }

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AppUser> refreshCurrentUser() => throw UnimplementedError();

  String? lastResetEmailSent;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmailSent = email;
  }

  @override
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signInAsStaff({
    required String identifier,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  bool signedOut = false;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  group('Super Admin Academy Details Screen Tests', () {
    testWidgets('Displays full academy details on dedicated screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAcademyRepository();
      final academy = (await fakeRepo.getAll()).first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academyRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: AcademyDetailsScreen(initialAcademy: academy),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & info
      expect(find.text('Academy Details'), findsOneWidget);
      expect(find.text('Premier Science Academy'), findsOneWidget);
      expect(find.text('ACD-TEST1'), findsOneWidget);
      expect(find.text('Dr. Tariq'), findsOneWidget);
      expect(find.text('tariq@test.com'), findsOneWidget);
      expect(find.text('03001234567'), findsOneWidget);
      expect(find.text('123 Main Blvd'), findsOneWidget);
      expect(find.text('Lahore, Punjab'), findsOneWidget);
      expect(find.text('Delete Academy Record'), findsOneWidget);
    });

    testWidgets('Super admin can delete academy record from dedicated screen',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAcademyRepository();
      final academy = (await fakeRepo.getAll()).first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academyRepositoryProvider.overrideWithValue(fakeRepo),
            academiesStreamProvider.overrideWith((ref) => fakeRepo.watchAll()),
          ],
          child: MaterialApp(
            home: AcademyDetailsScreen(initialAcademy: academy),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to Danger Zone and tap delete
      await tester.scrollUntilVisible(find.text('Delete Academy Record'), 200);
      await tester.tap(find.text('Delete Academy Record'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete Academy Record'), findsWidgets);
      expect(find.text('Delete Permanently'), findsOneWidget);

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(fakeRepo.deleted, isTrue);
    });

    testWidgets('Super admin can update status from dedicated screen',
        (tester) async {
      final fakeRepo = _FakeAcademyRepository();
      final academy = (await fakeRepo.getAll()).first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academyRepositoryProvider.overrideWithValue(fakeRepo),
            academiesStreamProvider.overrideWith((ref) => fakeRepo.watchAll()),
          ],
          child: MaterialApp(
            home: AcademyDetailsScreen(initialAcademy: academy),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Suspended choice chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Suspended'));
      await tester.pumpAndSettle();

      // Confirmation appears
      expect(find.text('Update Academy Status'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);

      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      expect(fakeRepo.updatedStatus, equals('suspended'));
    });
  });

  group('Super Admin Reset Password Screen Tests', () {
    testWidgets('Successfully changes password on dedicated screen', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: SuperAdminResetPasswordScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reset Account Password'), findsOneWidget);

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(3));

      await tester.enterText(fields.at(0), 'Admin@12345');
      await tester.enterText(fields.at(1), 'NewPass@2026');
      await tester.enterText(fields.at(2), 'NewPass@2026');

      // Tap submit button to trigger confirmation dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.text('Update Account Password'), findsOneWidget);

      // Confirm in dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Update Password'),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeAuth.passwordChanged, isTrue);
      expect(fakeAuth.lastOldPassword, 'Admin@12345');
      expect(fakeAuth.lastNewPassword, 'NewPass@2026');
    });

    testWidgets('Shows error when current password is wrong', (tester) async {
      final fakeAuth = _FakeAuthRepo()..shouldFailOldPassword = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: SuperAdminResetPasswordScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'WrongOldPass');
      await tester.enterText(fields.at(1), 'NewPass@2026');
      await tester.enterText(fields.at(2), 'NewPass@2026');

      // Tap submit button to trigger confirmation dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Update Account Password'), findsOneWidget);

      // Confirm in dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Update Password'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
    });
  });

  group('Super Admin Mobile Drawer Tests', () {
    testWidgets('Tapping drawer item automatically closes the drawer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = _FakeAuthRepo();
      final router = GoRouter(
        initialLocation: '/super-admin',
        routes: [
          GoRoute(
            path: '/super-admin',
            builder: (context, state) => const SuperAdminShell(
              location: '/super-admin',
              child: Scaffold(body: Text('Dashboard Content')),
            ),
          ),
          GoRoute(
            path: '/super-admin/academies',
            builder: (context, state) => const SuperAdminShell(
              location: '/super-admin/academies',
              child: Scaffold(body: Text('Academies Screen')),
            ),
          ),
          GoRoute(
            path: '/super-admin/platform-settings',
            builder: (context, state) => const SuperAdminShell(
              location: '/super-admin/platform-settings',
              child: Scaffold(body: Text('Settings Screen')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On narrow screen, drawer icon (hamburger) is visible
      final drawerIcon = find.byTooltip('Open navigation menu');
      expect(drawerIcon, findsOneWidget);

      // Open drawer
      await tester.tap(drawerIcon);
      await tester.pumpAndSettle();

      // Drawer is open with close button and menu options
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byTooltip('Close menu'), findsOneWidget);

      // Tap close button closes drawer
      await tester.tap(find.byTooltip('Close menu'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);

      // Open drawer again
      await tester.tap(drawerIcon);
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);

      // Tap an item in drawer (e.g. Settings)
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Drawer is closed automatically!
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets(
        'Sign out prompts confirmation dialog and signs out when confirmed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeAuth = _FakeAuthRepo();
      final router = GoRouter(
        initialLocation: '/super-admin',
        routes: [
          GoRoute(
            path: '/super-admin',
            builder: (context, state) => const SuperAdminShell(
              location: '/super-admin',
              child: Scaffold(body: Text('Dashboard Content')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      // Tap Sign out
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be shown
      expect(find.text('Sign Out'), findsWidgets);
      expect(
        find.text('Are you sure you want to sign out of the Super Admin dashboard?'),
        findsOneWidget,
      );

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fakeAuth.signedOut, isFalse);

      // Open drawer again and confirm sign out
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Sign Out'),
      );
      await tester.pumpAndSettle();

      expect(fakeAuth.signedOut, isTrue);
    });
  });

  group('Academy Admin Password Reset Screen Tests', () {
    testWidgets('Displays academy and admin details and sends reset link', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAcademyRepository();
      final fakeAuth = _FakeAuthRepo();
      final academy = await fakeRepo.getById('acad_1');
      expect(academy, isNotNull);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academyRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AcademyAdminResetPasswordScreen(initialAcademy: academy),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and academy info
      expect(find.text('Reset Admin Password'), findsOneWidget);
      expect(find.text('Premier Science Academy'), findsOneWidget);
      expect(find.text('Dr. Tariq'), findsOneWidget);
      expect(find.text('tariq@test.com'), findsWidgets);

      // Verify Send Reset Link button exists
      final sendButton = find.widgetWithText(
        FilledButton,
        'Send Password Reset Link',
      );
      expect(sendButton, findsOneWidget);

      // Tap Send Password Reset Link
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.text('Send Password Reset Link'), findsWidgets);
      expect(
        find.text(
          'Send an official Firebase password reset link to "tariq@test.com" for "Premier Science Academy"?\n\nThe administrator will be able to follow the link to set their new password.',
        ),
        findsOneWidget,
      );

      // Tap confirm button
      await tester.tap(find.widgetWithText(FilledButton, 'Send Reset Link'));
      await tester.pumpAndSettle();

      // Verify fake auth received the call
      expect(fakeAuth.lastResetEmailSent, equals('tariq@test.com'));

      // Verify success banner and snackbar
      expect(
        find.text(
          'Password reset email sent to "tariq@test.com"! The academy administrator can open the link in their inbox to establish their new password.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
        'AcademyDetailsScreen provides Change Admin Password action that navigates to reset screen',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAcademyRepository();
      final fakeAuth = _FakeAuthRepo();
      final academy = await fakeRepo.getById('acad_1');

      final router = GoRouter(
        initialLocation: '/super-admin/academies/details',
        routes: [
          GoRoute(
            path: '/super-admin/academies/details',
            builder: (context, state) => AcademyDetailsScreen(
              initialAcademy: academy,
            ),
          ),
          GoRoute(
            path: '/super-admin/academies/reset-password',
            builder: (context, state) => AcademyAdminResetPasswordScreen(
              initialAcademy: state.extra as Academy?,
              academyId: state.uri.queryParameters['id'],
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academyRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to Owner & Contact Information section
      final changePasswordBtn = find.widgetWithText(
        OutlinedButton,
        'Change Admin Password',
      );
      await tester.scrollUntilVisible(changePasswordBtn, 300);
      expect(changePasswordBtn, findsOneWidget);

      // Tap Change Admin Password
      await tester.tap(changePasswordBtn);
      await tester.pumpAndSettle();

      // Navigates to AcademyAdminResetPasswordScreen
      expect(find.text('Reset Admin Password'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Send Password Reset Link'),
        findsOneWidget,
      );
    });
  });
}

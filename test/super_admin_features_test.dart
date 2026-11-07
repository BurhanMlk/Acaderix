import 'dart:async';

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
import 'package:academy_management/features/super_admin/application/platform_broadcast_providers.dart';
import 'package:academy_management/features/super_admin/application/support_ticket_providers.dart';
import 'package:academy_management/features/super_admin/domain/platform_broadcast.dart';
import 'package:academy_management/features/super_admin/domain/platform_broadcast_repository.dart';
import 'package:academy_management/features/super_admin/domain/support_ticket.dart';
import 'package:academy_management/features/super_admin/domain/support_ticket_repository.dart';
import 'package:academy_management/features/super_admin/presentation/screens/academy_admin_reset_password_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/academy_details_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/platform_broadcasts_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/platform_settings_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/super_admin_reset_password_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/super_admin_shell.dart';
import 'package:academy_management/features/super_admin/presentation/screens/support_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:academy_management/core/widgets/stat_card.dart';
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

  @override
  Future<String> createCustomAcademyWithPackage({
    required String academyName,
    required String academyCode,
    required String address,
    required String city,
    required String province,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    required String ownerPhone,
    required int maxBranches,
    required int maxStudents,
    required int monthlyFee,
    String billingCycle = 'monthly',
    String status = 'active',
    String paymentStatus = 'paid',
    String? logoUrl,
    String? cnic,
  }) async {
    final id = 'acad_${_academies.length + 1}';
    _academies.add(Academy(
      id: id,
      code: academyCode.isNotEmpty ? academyCode : 'CODE-$id',
      name: academyName,
      city: city,
      province: province,
      address: address,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPhone: ownerPhone,
      status: status,
      branchCount: 1,
      registrationDate: DateTime.now(),
    ));
    return id;
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

class _FakePlatformBroadcastRepository implements PlatformBroadcastRepository {
  final List<PlatformBroadcast> _broadcasts = [
    PlatformBroadcast(
      id: 'b_1',
      title: 'Platform v1.2 Release',
      message: 'New broadcast capabilities deployed.',
      category: 'feature',
      priority: 'high',
      targetAudience: 'all',
      isActive: true,
      createdAt: DateTime(2026, 11, 1),
    ),
    PlatformBroadcast(
      id: 'b_2',
      title: 'Scheduled Cloud Maintenance Notice',
      message: 'System upgrade on Sunday 02:00 AM.',
      category: 'maintenance',
      priority: 'urgent',
      targetAudience: 'all',
      isActive: true,
      createdAt: DateTime(2026, 10, 28),
    ),
  ];

  final _ctrl = StreamController<List<PlatformBroadcast>>.broadcast();
  bool created = false;
  bool deleted = false;
  bool toggled = false;

  @override
  Stream<List<PlatformBroadcast>> watchBroadcasts() async* {
    yield List.of(_broadcasts);
    yield* _ctrl.stream;
  }

  @override
  Future<List<PlatformBroadcast>> getBroadcasts() async => List.of(_broadcasts);

  @override
  Future<void> createBroadcast(PlatformBroadcast broadcast) async {
    created = true;
    _broadcasts.insert(0, broadcast);
    _ctrl.add(List.of(_broadcasts));
  }

  @override
  Future<void> toggleBroadcastActive(String id, bool isActive) async {
    toggled = true;
    final i = _broadcasts.indexWhere((b) => b.id == id);
    if (i != -1) {
      _broadcasts[i] = _broadcasts[i].copyWith(isActive: isActive);
      _ctrl.add(List.of(_broadcasts));
    }
  }

  @override
  Future<void> deleteBroadcast(String id) async {
    deleted = true;
    _broadcasts.removeWhere((b) => b.id == id);
    _ctrl.add(List.of(_broadcasts));
  }
}

class _FakeSupportTicketRepository implements SupportTicketRepository {
  final List<SupportTicket> _tickets = [
    SupportTicket(
      id: 't_1',
      ticketNumber: 'TICK-1042',
      academyId: 'acad_1',
      academyName: 'Premier Science Academy',
      academyCode: 'ACD-PSA10',
      contactName: 'Dr. Tariq',
      contactEmail: 'tariq@test.com',
      contactPhone: '03001234567',
      subject: 'Branch quota upgrade request',
      description: 'Opening campus in Model Town Lahore.',
      category: 'billing',
      priority: 'high',
      status: 'open',
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      messages: [
        SupportTicketMessage(
          id: 'm_1',
          senderName: 'Dr. Tariq',
          senderRole: 'academyAdmin',
          message: 'Opening campus in Model Town Lahore.',
          createdAt: DateTime(2026, 11, 1),
        ),
      ],
    ),
    SupportTicket(
      id: 't_2',
      ticketNumber: 'TICK-1038',
      academyId: 'acad_2',
      academyName: 'Apex Coaching Center',
      academyCode: 'ACD-ACC22',
      contactName: 'Prof. Aslam',
      contactEmail: 'aslam@test.com',
      contactPhone: '03009876543',
      subject: 'Bulk enrollment sync verification',
      description: 'Enrolled 120 new session students.',
      category: 'technical',
      priority: 'medium',
      status: 'in_progress',
      createdAt: DateTime(2026, 10, 30),
      updatedAt: DateTime(2026, 10, 30),
      messages: [],
    ),
  ];

  final _ctrl = StreamController<List<SupportTicket>>.broadcast();
  bool created = false;
  bool deleted = false;
  String? updatedStatus;
  String? addedReply;

  @override
  Stream<List<SupportTicket>> watchTickets() async* {
    yield List.of(_tickets);
    yield* _ctrl.stream;
  }

  @override
  Future<List<SupportTicket>> getTickets() async => List.of(_tickets);

  @override
  Future<SupportTicket?> getTicketById(String id) async =>
      _tickets.where((t) => t.id == id).firstOrNull;

  @override
  Future<void> createTicket(SupportTicket ticket) async {
    created = true;
    _tickets.insert(0, ticket);
    _ctrl.add(List.of(_tickets));
  }

  @override
  Future<void> updateTicketStatus(
    String id,
    String status, {
    String? resolutionNote,
  }) async {
    updatedStatus = status;
    final i = _tickets.indexWhere((t) => t.id == id);
    if (i != -1) {
      _tickets[i] = _tickets[i].copyWith(
        status: status,
        resolutionNote: resolutionNote,
      );
      _ctrl.add(List.of(_tickets));
    }
  }

  @override
  Future<void> addTicketMessage(String id, SupportTicketMessage message) async {
    addedReply = message.message;
    final i = _tickets.indexWhere((t) => t.id == id);
    if (i != -1) {
      final updatedList = List<SupportTicketMessage>.from(_tickets[i].messages)
        ..add(message);
      _tickets[i] = _tickets[i].copyWith(messages: updatedList);
      _ctrl.add(List.of(_tickets));
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    deleted = true;
    _tickets.removeWhere((t) => t.id == id);
    _ctrl.add(List.of(_tickets));
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

    testWidgets(
        'SuperAdminShell navigates to Broadcasts and Support modules',
        (tester) async {
      final fakeBroadcastRepo = _FakePlatformBroadcastRepository();
      final fakeTicketRepo = _FakeSupportTicketRepository();

      final router = GoRouter(
        initialLocation: '/super-admin/broadcasts',
        routes: [
          ShellRoute(
            builder: (context, state, child) => SuperAdminShell(
              location: state.matchedLocation,
              child: child,
            ),
            routes: [
              GoRoute(
                path: '/super-admin/broadcasts',
                builder: (context, state) =>
                    const PlatformBroadcastsScreen(),
              ),
              GoRoute(
                path: '/super-admin/support-tickets',
                builder: (context, state) => const SupportTicketsScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformBroadcastRepositoryProvider
                .overrideWithValue(fakeBroadcastRepo),
            supportTicketRepositoryProvider.overrideWithValue(fakeTicketRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Broadcasts screen is displayed
      expect(find.text('Total Broadcasts'), findsOneWidget);
      expect(find.text('Platform v1.2 Release'), findsOneWidget);

      // Navigate to Support Tickets
      router.go('/super-admin/support-tickets');
      await tester.pumpAndSettle();

      expect(find.text('Total Tickets'), findsOneWidget);
      expect(find.text('TICK-1042'), findsOneWidget);
    });

    testWidgets(
        'PlatformBroadcastsScreen renders stats, filters, and logs new broadcast',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeBroadcastRepo = _FakePlatformBroadcastRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformBroadcastRepositoryProvider
                .overrideWithValue(fakeBroadcastRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformBroadcastsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify StatCards
      expect(find.text('Total Broadcasts'), findsOneWidget);
      expect(find.text('Active Notices'), findsOneWidget);
      expect(find.text('Urgent Alerts'), findsOneWidget);

      // Verify Seeded Broadcasts
      expect(find.text('Platform v1.2 Release'), findsOneWidget);
      expect(find.text('Scheduled Cloud Maintenance Notice'), findsOneWidget);

      // Test Search Filter
      final searchField =
          find.widgetWithText(TextField, 'Search broadcasts by title or keyword...');
      await tester.enterText(searchField, 'Maintenance');
      await tester.pumpAndSettle();

      expect(find.text('Scheduled Cloud Maintenance Notice'), findsOneWidget);
      expect(find.text('Platform v1.2 Release'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('Platform v1.2 Release'), findsOneWidget);

      // Open New Broadcast Modal
      await tester.tap(find.text('New Broadcast'));
      await tester.pumpAndSettle();

      expect(find.text('Create Platform Broadcast'), findsOneWidget);

      // Fill in Form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notice Title *'),
        'Emergency Infrastructure Upgrade',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Detailed Message *'),
        'Global network route optimization complete.',
      );

      // Submit
      final publishBtn =
          find.widgetWithText(FilledButton, 'Publish Broadcast');
      await tester.ensureVisible(publishBtn);
      await tester.pumpAndSettle();
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // Verify created in repo
      expect(fakeBroadcastRepo.created, isTrue);
      expect(
        find.text('Emergency Infrastructure Upgrade'),
        findsOneWidget,
      );
    });

    testWidgets(
        'PlatformBroadcastsScreen toggles status and deletes with confirmation dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeBroadcastRepo = _FakePlatformBroadcastRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformBroadcastRepositoryProvider
                .overrideWithValue(fakeBroadcastRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformBroadcastsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle Active State
      final pauseBtn = find.byIcon(Icons.pause_circle_outline_rounded).first;
      await tester.tap(pauseBtn);
      await tester.pumpAndSettle();
      expect(fakeBroadcastRepo.toggled, isTrue);

      // Delete Broadcast with confirmation
      final deleteBtn = find.byIcon(Icons.delete_outline_rounded).first;
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog should be open
      expect(find.text('Delete Broadcast'), findsOneWidget);
      expect(
        find.text('Are you sure you want to permanently delete "Platform v1.2 Release"?'),
        findsOneWidget,
      );

      // Confirm Delete
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(fakeBroadcastRepo.deleted, isTrue);
    });

    testWidgets(
        'SupportTicketsScreen renders KPI stats, opens details, updates status and replies',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeTicketRepo = _FakeSupportTicketRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportTicketRepositoryProvider.overrideWithValue(fakeTicketRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SupportTicketsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify KPI StatCards
      expect(find.text('Total Tickets'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'Open'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'In Progress'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'Resolved'), findsOneWidget);

      // Verify Tickets List
      expect(find.text('TICK-1042'), findsOneWidget);
      expect(find.text('Branch quota upgrade request'), findsOneWidget);

      // Tap ticket to view details
      await tester.tap(find.text('TICK-1042'));
      await tester.pumpAndSettle();

      // Details view should be displayed
      expect(find.text('Activity Thread'), findsOneWidget);
      expect(find.text('Opening campus in Model Town Lahore.'), findsWidgets);

      // Add Admin Reply
      final replyField = find.widgetWithText(
        TextField,
        'Type response to academy administrator...',
      );
      await tester.enterText(
        replyField,
        'Approved branch quota for Model Town campus.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Send Reply'));
      await tester.pumpAndSettle();

      expect(
        fakeTicketRepo.addedReply,
        equals('Approved branch quota for Model Town campus.'),
      );
      expect(
        find.text('Reply dispatched to academy administrator.'),
        findsOneWidget,
      );

      // Open details again and update status to Resolved
      await tester.tap(find.text('TICK-1042'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Resolved'));
      await tester.pumpAndSettle();

      expect(fakeTicketRepo.updatedStatus, equals('resolved'));
    });

    testWidgets(
        'PlatformSettingsScreen toggles System Maintenance Mode with confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformSettingsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Platform Settings'), findsOneWidget);
      expect(find.text('System Maintenance Mode'), findsOneWidget);

      // Toggle Maintenance Switch ON
      final maintenanceSwitch =
          find.widgetWithText(SwitchListTile, 'System Maintenance Mode');
      await tester.tap(maintenanceSwitch);
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.text('Enable Maintenance Mode?'), findsOneWidget);

      // Confirm
      await tester.tap(find.widgetWithText(FilledButton, 'Enable Maintenance'));
      await tester.pumpAndSettle();

      expect(
        find.text('Active: All non-admin operations are temporarily paused.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'PlatformSettingsScreen renders cleanly on narrow 320px phone viewport without RenderFlex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformSettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Platform Settings'), findsOneWidget);
      expect(find.text('Platform Controls & Maintenance'), findsOneWidget);

      // Scroll down to reveal diagnostics card
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Platform Information & Diagnostics'), findsOneWidget);
    });

    testWidgets(
        'PlatformBroadcastsScreen and SupportTicketsScreen render cleanly on narrow 320px phone viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeBroadcastRepo = _FakePlatformBroadcastRepository();
      final fakeTicketRepo = _FakeSupportTicketRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformBroadcastRepositoryProvider
                .overrideWithValue(fakeBroadcastRepo),
            supportTicketRepositoryProvider.overrideWithValue(fakeTicketRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformBroadcastsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Total Broadcasts'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformBroadcastRepositoryProvider
                .overrideWithValue(fakeBroadcastRepo),
            supportTicketRepositoryProvider.overrideWithValue(fakeTicketRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SupportTicketsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Total Tickets'), findsOneWidget);
    });

    testWidgets(
        'PlatformSettingsScreen renders cleanly on 360px mobile viewport without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformSettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Platform Controls & Maintenance'), findsOneWidget);

      // Scroll to bottom card
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Flush Local Cache & Re-sync State'), findsOneWidget);
    });
  });
}

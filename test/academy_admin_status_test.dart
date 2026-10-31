import 'package:academy_management/app/router.dart';
import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/features/academy_admin/application/academy_access_provider.dart';
import 'package:academy_management/features/academy_admin/application/academy_admin_providers.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_models.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_repository.dart';
import 'package:academy_management/features/academy_admin/presentation/screens/academy_admin_dashboard.dart';
import 'package:academy_management/features/academy_admin/presentation/screens/academy_admin_shell.dart';
import 'package:academy_management/features/academy_admin/presentation/screens/academy_status_notice_screen.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/attendance/domain/attendance_record.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/auth/presentation/screens/academy_admin_login_screen.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/exams/domain/exam.dart';
import 'package:academy_management/features/exams/domain/exam_result.dart';
import 'package:academy_management/features/fees/domain/fee_invoice.dart';
import 'package:academy_management/features/fees/domain/fee_payment.dart';
import 'package:academy_management/features/staff/domain/staff.dart';
import 'package:academy_management/shared/current_academy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAcademyAccessRepository implements AcademyAccessRepository {
  _FakeAcademyAccessRepository(this._currentInfo);

  AcademyAccessInfo _currentInfo;

  void updateInfo(AcademyAccessInfo newInfo) {
    _currentInfo = newInfo;
  }

  @override
  Stream<AcademyAccessInfo> watchAcademyAccess(String academyId) {
    return Stream.value(_currentInfo);
  }

  @override
  Future<AcademyAccessInfo> getAcademyAccess(String academyId) async {
    return _currentInfo;
  }

  @override
  Future<AcademyAccessInfo> findAndCheckAcademyByEmail(String email) async {
    return _currentInfo;
  }
}

class _FakeAuthRepo implements AuthRepository {
  bool signInCalled = false;
  String? signedInEmail;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    signedInEmail = email;
    return AppUser(
      id: 'admin_123',
      email: email,
      role: AppRole.academyAdmin,
      academyId: 'acad_123',
    );
  }
  @override
  Stream<AuthState> authStateChanges() async* {
    yield const AuthState.authenticated(
      AppUser(
        id: 'admin_123',
        email: 'admin@alhuda.com',
        role: AppRole.academyAdmin,
        academyId: 'acad_123',
      ),
    );
  }

  @override
  Future<AuthState> currentState() async {
    return const AuthState.authenticated(
      AppUser(
        id: 'admin_123',
        email: 'admin@alhuda.com',
        role: AppRole.academyAdmin,
        academyId: 'acad_123',
      ),
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Academy Admin Access Gating Tests', () {
    testWidgets('Active academy with paid subscription renders dashboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final info = AcademyAccessInfo(
        state: AcademyAccessState.active,
        academyId: 'acad_123',
        academyName: 'Al-Huda Academy',
        academyCode: 'ACD-101',
        rawStatus: 'active',
        renewalDate: DateTime.now().add(const Duration(days: 25)),
        paymentStatus: 'paid',
        planName: 'Standard',
      );
      final repo = _FakeAcademyAccessRepository(info);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            currentAcademyIdProvider.overrideWithValue('acad_123'),
            academyAccessRepositoryProvider.overrideWithValue(repo),
            academyAccessProvider.overrideWith((ref) => Stream.value(info)),
            studentsStreamProvider.overrideWith(
              (ref, id) => Stream<List<Student>>.value([]),
            ),
            staffStreamProvider.overrideWith(
              (ref, id) => Stream<List<Staff>>.value([]),
            ),
            branchesStreamProvider.overrideWith(
              (ref, id) => Stream<List<Branch>>.value([]),
            ),
            invoicesStreamProvider.overrideWith(
              (ref, id) => Stream<List<FeeInvoice>>.value([]),
            ),
            paymentsStreamProvider.overrideWith(
              (ref, id) => Stream<List<FeePayment>>.value([]),
            ),
            attendanceForDateProvider.overrideWith(
              (ref, args) => Stream<List<AttendanceRecord>>.value([]),
            ),
            examsStreamProvider.overrideWith(
              (ref, id) => Stream<List<Exam>>.value([]),
            ),
            resultsStreamProvider.overrideWith(
              (ref, id) => Stream<List<ExamResult>>.value([]),
            ),
          ],
          child: const MaterialApp(
            home: AcademyAdminShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render the normal AcademyAdminDashboard
      expect(find.byType(AcademyAdminDashboard), findsOneWidget);
      expect(find.byType(AcademyStatusNoticeScreen), findsNothing);
    });

    testWidgets(
        'Pending academy renders approval notice with Super Admin contact info',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final info = const AcademyAccessInfo(
        state: AcademyAccessState.pending,
        academyId: 'acad_123',
        academyName: 'Apex Science Academy',
        academyCode: 'ACD-202',
        rawStatus: 'pending',
        supportPhone: '+92 300 1234567',
        supportEmail: 'support@acaderix.com',
      );
      final repo = _FakeAcademyAccessRepository(info);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            currentAcademyIdProvider.overrideWithValue('acad_123'),
            academyAccessRepositoryProvider.overrideWithValue(repo),
            academyAccessProvider.overrideWith((ref) => Stream.value(info)),
          ],
          child: const MaterialApp(
            home: AcademyAdminShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AcademyStatusNoticeScreen), findsOneWidget);
      expect(find.byType(AcademyAdminDashboard), findsNothing);

      // Verify Status details
      expect(find.text('APPROVAL PENDING'), findsOneWidget);
      expect(find.text('Account Approval Pending'), findsOneWidget);
      expect(find.text('Apex Science Academy'), findsOneWidget);
      expect(find.text('ACD-202'), findsOneWidget);

      // Verify Super Admin contact details
      expect(find.text('Contact Super Admin'), findsOneWidget);
      expect(find.text('+92 300 1234567'), findsOneWidget);
      expect(find.text('support@acaderix.com'), findsOneWidget);
    });

    testWidgets(
        'Suspended academy renders suspended notice with Super Admin contact info',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final info = const AcademyAccessInfo(
        state: AcademyAccessState.suspended,
        academyId: 'acad_123',
        academyName: 'Beacon Heights School',
        academyCode: 'ACD-303',
        rawStatus: 'suspended',
        supportPhone: '+92 300 1234567',
      );
      final repo = _FakeAcademyAccessRepository(info);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            currentAcademyIdProvider.overrideWithValue('acad_123'),
            academyAccessRepositoryProvider.overrideWithValue(repo),
            academyAccessProvider.overrideWith((ref) => Stream.value(info)),
          ],
          child: const MaterialApp(
            home: AcademyAdminShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AcademyStatusNoticeScreen), findsOneWidget);
      expect(find.text('ACCOUNT SUSPENDED'), findsOneWidget);
      expect(find.text('Academy Account Suspended'), findsOneWidget);
      expect(find.text('+92 300 1234567'), findsOneWidget);
    });

    testWidgets(
        'Expired subscription renders renewal required with Super Admin contact info',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final info = AcademyAccessInfo(
        state: AcademyAccessState.expired,
        academyId: 'acad_123',
        academyName: 'Crescent Grammar Academy',
        academyCode: 'ACD-404',
        rawStatus: 'active',
        renewalDate: DateTime.now().subtract(const Duration(days: 3)),
        paymentStatus: 'paid',
        supportPhone: '+92 300 1234567',
      );
      final repo = _FakeAcademyAccessRepository(info);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            currentAcademyIdProvider.overrideWithValue('acad_123'),
            academyAccessRepositoryProvider.overrideWithValue(repo),
            academyAccessProvider.overrideWith((ref) => Stream.value(info)),
          ],
          child: const MaterialApp(
            home: AcademyAdminShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AcademyStatusNoticeScreen), findsOneWidget);
      expect(find.text('SUBSCRIPTION EXPIRED'), findsOneWidget);
      expect(find.text('Subscription Renewal Required'), findsOneWidget);
      expect(find.text('Crescent Grammar Academy'), findsOneWidget);
      expect(find.text('+92 300 1234567'), findsOneWidget);
    });

    testWidgets(
        'Unpaid/overdue payment renders subscription payment required notice',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final info = AcademyAccessInfo(
        state: AcademyAccessState.expired,
        academyId: 'acad_123',
        academyName: 'Delta Learning Institute',
        academyCode: 'ACD-505',
        rawStatus: 'active',
        renewalDate: DateTime.now().add(const Duration(days: 10)),
        paymentStatus: 'overdue',
        supportPhone: '+92 300 1234567',
      );
      final repo = _FakeAcademyAccessRepository(info);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            currentAcademyIdProvider.overrideWithValue('acad_123'),
            academyAccessRepositoryProvider.overrideWithValue(repo),
            academyAccessProvider.overrideWith((ref) => Stream.value(info)),
          ],
          child: const MaterialApp(
            home: AcademyAdminShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AcademyStatusNoticeScreen), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(find.text('+92 300 1234567'), findsOneWidget);
    });

    testWidgets('Tapping copy button copies contact number', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final info = const AcademyAccessInfo(
        state: AcademyAccessState.pending,
        academyId: 'acad_123',
        academyName: 'Eden High Academy',
        academyCode: 'ACD-606',
        supportPhone: '+92 300 1234567',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            academyAccessProvider.overrideWith((ref) => Stream.value(info)),
          ],
          child: MaterialApp(
            home: AcademyStatusNoticeScreen(accessInfo: info),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap copy button for phone
      final copyBtn = find.byTooltip('Copy Phone Number');
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pump();

      expect(find.text('Phone number copied to clipboard!'), findsOneWidget);
    });

    testWidgets('Check Status Again button triggers refresh', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final info = const AcademyAccessInfo(
        state: AcademyAccessState.pending,
        academyId: 'acad_123',
        academyName: 'Falcon Academy',
        academyCode: 'ACD-707',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            academyAccessProvider.overrideWith((ref) => Stream.value(info)),
          ],
          child: MaterialApp(
            home: AcademyStatusNoticeScreen(accessInfo: info),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final refreshBtn =
          find.widgetWithText(FilledButton, 'Check Status Again');
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pump();

      expect(find.text('Checking Status...'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Pre-login gating: does NOT sign in or issue token if academy is suspended or pending',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeAuth = _FakeAuthRepo();
        final suspendedInfo = const AcademyAccessInfo(
          state: AcademyAccessState.suspended,
          academyId: 'acad_suspended',
          academyName: 'Suspended Academy',
          academyCode: 'ACD-999',
          rawStatus: 'suspended',
          ownerEmail: 'suspended@academy.com',
          statusReason: 'Suspended by admin',
        );
        final accessRepo = _FakeAcademyAccessRepository(suspendedInfo);

        final router = GoRouter(
          initialLocation: AppRoutes.academyAdminLogin,
          routes: [
            GoRoute(
              path: AppRoutes.academyAdminLogin,
              builder: (context, state) => const AcademyAdminLoginScreen(),
            ),
            GoRoute(
              path: AppRoutes.academyStatus,
              builder: (context, state) {
                final access =
                    state.extra as AcademyAccessInfo? ?? suspendedInfo;
                return AcademyStatusNoticeScreen(accessInfo: access);
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuth),
              academyAccessRepositoryProvider.overrideWithValue(accessRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Fill in email and password
        await tester.enterText(
          find.byType(TextFormField).first,
          'suspended@academy.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'secret123',
        );

        // Tap Sign In button
        final signInBtn = find.widgetWithText(FilledButton, 'Sign In');
        expect(signInBtn, findsOneWidget);
        await tester.tap(signInBtn);
        await tester.pumpAndSettle();

        // 1. Verify signInWithEmailAndPassword was NEVER CALLED (NO token issued!)
        expect(fakeAuth.signInCalled, isFalse);

        // 2. Verify routed to AcademyStatusNoticeScreen showing suspended notice
        expect(find.text('ACCOUNT SUSPENDED'), findsOneWidget);
        expect(find.text('Suspended Academy'), findsOneWidget);
        expect(find.text('+92 300 1234567'), findsOneWidget);
      },
    );

    testWidgets(
      'Pre-login gating: calls signInWithEmailAndPassword & issues token ONLY when academy is active',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeAuth = _FakeAuthRepo();
        final activeInfo = AcademyAccessInfo(
          state: AcademyAccessState.active,
          academyId: 'acad_active',
          academyName: 'Active Academy',
          academyCode: 'ACD-111',
          rawStatus: 'active',
          ownerEmail: 'active@academy.com',
          renewalDate: DateTime.now().add(const Duration(days: 20)),
          paymentStatus: 'paid',
        );
        final accessRepo = _FakeAcademyAccessRepository(activeInfo);

        final router = GoRouter(
          initialLocation: AppRoutes.academyAdminLogin,
          routes: [
            GoRoute(
              path: AppRoutes.academyAdminLogin,
              builder: (context, state) => const AcademyAdminLoginScreen(),
            ),
            GoRoute(
              path: AppRoutes.academyAdmin,
              builder: (context, state) => const Scaffold(
                body: Text('Academy Admin Dashboard Home'),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuth),
              academyAccessRepositoryProvider.overrideWithValue(accessRepo),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Fill in email and password
        await tester.enterText(
          find.byType(TextFormField).first,
          'active@academy.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'secret123',
        );

        // Tap Sign In button
        final signInBtn = find.widgetWithText(FilledButton, 'Sign In');
        expect(signInBtn, findsOneWidget);
        await tester.tap(signInBtn);
        await tester.pumpAndSettle();

        // 1. Verify signInWithEmailAndPassword WAS CALLED (Token issued!)
        expect(fakeAuth.signInCalled, isTrue);
        expect(fakeAuth.signedInEmail, 'active@academy.com');

        // 2. Verify navigated to Academy Admin dashboard
        expect(find.text('Academy Admin Dashboard Home'), findsOneWidget);
      },
    );
  });
}

import 'dart:async';

import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/core/widgets/stat_card.dart';
import 'package:academy_management/features/academy_admin/application/academy_access_provider.dart';
import 'package:academy_management/features/academy_admin/application/academy_admin_providers.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_models.dart';
import 'package:academy_management/features/academy_admin/presentation/screens/academy_admin_dashboard.dart';
import 'package:academy_management/features/academy_admin/presentation/screens/academy_support_screen.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/communication/application/communication_providers.dart';
import 'package:academy_management/features/communication/domain/announcement.dart';
import 'package:academy_management/features/communication/presentation/screens/announcements_screen.dart';
import 'package:academy_management/features/fees/domain/fee_payment.dart';
import 'package:academy_management/features/staff/domain/staff.dart';
import 'package:academy_management/features/super_admin/application/platform_broadcast_providers.dart';
import 'package:academy_management/features/super_admin/application/support_ticket_providers.dart';
import 'package:academy_management/features/super_admin/domain/platform_broadcast.dart';
import 'package:academy_management/features/super_admin/domain/platform_broadcast_repository.dart';
import 'package:academy_management/features/super_admin/domain/support_ticket.dart';
import 'package:academy_management/features/super_admin/domain/support_ticket_repository.dart';
import 'package:academy_management/features/super_admin/presentation/screens/platform_broadcasts_screen.dart';
import 'package:academy_management/features/super_admin/presentation/screens/support_tickets_screen.dart';
import 'package:academy_management/shared/current_academy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo(this.user);
  final AppUser user;

  @override
  Stream<AuthState> authStateChanges() =>
      Stream.value(AuthState.authenticated(user));

  @override
  Future<AuthState> currentState() async => AuthState.authenticated(user);

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      user;

  @override
  Future<AppUser> signInAsStaff({
    required String identifier,
    required String password,
  }) async =>
      user;

  @override
  Future<AppUser> signInAsStudent({
    required String academyCode,
    required String rollNumber,
    required String pin,
  }) async =>
      user;

  @override
  Future<AppUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      user;

  @override
  Future<AppUser> refreshCurrentUser() async => user;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeSupportTicketRepository implements SupportTicketRepository {
  final List<SupportTicket> _tickets = [
    SupportTicket(
      id: 'ticket_demo_1',
      ticketNumber: 'TICK-1001',
      academyId: 'acad_101',
      academyName: 'Al-Huda Science Academy',
      academyCode: 'ACAD-ALH1',
      contactName: 'Prof. Tariq',
      contactEmail: 'tariq@test.com',
      contactPhone: '03001234567',
      subject: 'Inquiry regarding student roll generation',
      description: 'Need help with auto-numbering configuration.',
      category: 'technical',
      priority: 'medium',
      status: 'open',
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      messages: [
        SupportTicketMessage(
          id: 'msg_1',
          senderName: 'Prof. Tariq',
          senderRole: 'academyAdmin',
          message: 'Need help with auto-numbering configuration.',
          createdAt: DateTime(2026, 11, 1),
        ),
      ],
    ),
  ];

  final _controller = StreamController<List<SupportTicket>>.broadcast();

  @override
  Stream<List<SupportTicket>> watchTickets() async* {
    yield List.of(_tickets);
    yield* _controller.stream;
  }

  @override
  Future<List<SupportTicket>> getTickets() async => List.of(_tickets);

  @override
  Future<SupportTicket?> getTicketById(String id) async =>
      _tickets.where((t) => t.id == id).firstOrNull;

  @override
  Future<void> createTicket(SupportTicket ticket) async {
    _tickets.insert(0, ticket);
    _controller.add(List.of(_tickets));
  }

  @override
  Future<void> updateTicketStatus(
    String id,
    String status, {
    String? resolutionNote,
  }) async {
    final i = _tickets.indexWhere((t) => t.id == id);
    if (i != -1) {
      _tickets[i] = _tickets[i].copyWith(
        status: status,
        updatedAt: DateTime.now(),
        resolutionNote: resolutionNote ?? _tickets[i].resolutionNote,
      );
      _controller.add(List.of(_tickets));
    }
  }

  @override
  Future<void> addTicketMessage(String id, SupportTicketMessage message) async {
    final i = _tickets.indexWhere((t) => t.id == id);
    if (i != -1) {
      final updatedList = List<SupportTicketMessage>.from(_tickets[i].messages)
        ..add(message);
      _tickets[i] = _tickets[i].copyWith(
        messages: updatedList,
        updatedAt: DateTime.now(),
      );
      _controller.add(List.of(_tickets));
    }
  }

  @override
  Future<void> deleteTicket(String id) async {
    _tickets.removeWhere((t) => t.id == id);
    _controller.add(List.of(_tickets));
  }
}

class _FakePlatformBroadcastRepository implements PlatformBroadcastRepository {
  final List<PlatformBroadcast> _broadcasts = [
    PlatformBroadcast(
      id: 'pb_init_1',
      title: 'Scheduled Cloud Maintenance Notice',
      message: 'Cloud database optimization Sunday 02:00 AM.',
      category: 'maintenance',
      priority: 'urgent',
      targetAudience: 'all',
      isActive: true,
      createdAt: DateTime(2026, 11, 1),
      sentPushNotification: true,
    ),
  ];

  final _controller = StreamController<List<PlatformBroadcast>>.broadcast();

  @override
  Stream<List<PlatformBroadcast>> watchBroadcasts() async* {
    yield List.of(_broadcasts);
    yield* _controller.stream;
  }

  @override
  Future<List<PlatformBroadcast>> getBroadcasts() async =>
      List.of(_broadcasts);

  @override
  Future<void> createBroadcast(PlatformBroadcast broadcast) async {
    _broadcasts.insert(0, broadcast);
    _controller.add(List.of(_broadcasts));
  }

  @override
  Future<void> toggleBroadcastActive(String id, bool isActive) async {
    final i = _broadcasts.indexWhere((b) => b.id == id);
    if (i != -1) {
      _broadcasts[i] = _broadcasts[i].copyWith(isActive: isActive);
      _controller.add(List.of(_broadcasts));
    }
  }

  @override
  Future<void> deleteBroadcast(String id) async {
    _broadcasts.removeWhere((b) => b.id == id);
    _controller.add(List.of(_broadcasts));
  }
}

void main() {
  const fakeAccess = AcademyAccessInfo(
    state: AcademyAccessState.active,
    academyId: 'acad_101',
    academyName: 'Al-Huda Science Academy',
    academyCode: 'ACAD-ALH1',
    ownerName: 'Prof. Tariq',
    ownerEmail: 'tariq@test.com',
    supportPhone: '03001234567',
  );

  final testUser = AppUser(
    id: 'user_101',
    email: 'tariq@test.com',
    role: AppRole.academyAdmin,
    academyId: 'acad_101',
    displayName: 'Prof. Tariq',
  );

  final fakeAuth = _FakeAuthRepo(testUser);

  group('Academy Admin Support Desk & Super Admin Communication Tests', () {
    testWidgets(
        'Academy Admin submits ticket, Super Admin replies, Academy Admin responds',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeTickets = _FakeSupportTicketRepository();
      final fakeBroadcasts = _FakePlatformBroadcastRepository();

      // 1. Academy Admin opens AcademySupportScreen
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            academyAccessProvider.overrideWith((ref) => Stream.value(fakeAccess)),
            currentAcademyIdProvider.overrideWith((ref) => 'acad_101'),
            supportTicketRepositoryProvider.overrideWithValue(fakeTickets),
            platformBroadcastRepositoryProvider.overrideWithValue(fakeBroadcasts),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AcademySupportScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify KPI StatCards
      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.widgetWithText(StatCard, 'Open'), findsOneWidget);
      expect(find.text('TICK-1001'), findsOneWidget);
      expect(
        find.text('Inquiry regarding student roll generation'),
        findsOneWidget,
      );

      // 2. Academy Admin creates a new support ticket
      await tester.tap(find.text('Ask Super Admin'));
      await tester.pumpAndSettle();

      expect(
        find.text('Submit Inquire / Ticket to Super Admin'),
        findsOneWidget,
      );

      // Fill Subject & Description
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subject *'),
        'Urgent fee invoice tax calculation question',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Detailed Inquiry *'),
        'Need clarification on provincial sales tax exemption setup.',
      );

      await tester.tap(find.text('Submit Ticket to Super Admin'));
      await tester.pumpAndSettle();

      // Verify ticket was added in repo
      final ticketsAfterCreate = await fakeTickets.getTickets();
      expect(ticketsAfterCreate.length, equals(2));
      final newTicket = ticketsAfterCreate.first;
      expect(
        newTicket.subject,
        equals('Urgent fee invoice tax calculation question'),
      );
      expect(newTicket.academyName, equals('Al-Huda Science Academy'));

      // 3. Super Admin opens SupportTicketsScreen and replies
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            supportTicketRepositoryProvider.overrideWithValue(fakeTickets),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SupportTicketsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Super Admin sees the new ticket from Al-Huda Science Academy
      expect(find.text('Urgent fee invoice tax calculation question'), findsOneWidget);
      expect(find.text('Al-Huda Science Academy'), findsWidgets);

      // Super Admin taps ticket to open conversation
      await tester.tap(find.text('Urgent fee invoice tax calculation question'));
      await tester.pumpAndSettle();

      // Super Admin types response
      final replyField = find.widgetWithText(
        TextField,
        'Type response to academy administrator...',
      );
      await tester.enterText(
        replyField,
        'Sales tax configuration guide sent to your email. Feature enabled.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Send Reply'));
      await tester.pumpAndSettle();

      // Verify message added in fake repo
      final ticketAfterReply = await fakeTickets.getTicketById(newTicket.id);
      expect(ticketAfterReply!.messages.length, equals(2));
      expect(ticketAfterReply.messages.last.isStaffReply, isTrue);

      // 4. Academy Admin returns to AcademySupportScreen and reads the reply
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            academyAccessProvider.overrideWith((ref) => Stream.value(fakeAccess)),
            currentAcademyIdProvider.overrideWith((ref) => 'acad_101'),
            supportTicketRepositoryProvider.overrideWithValue(fakeTickets),
            platformBroadcastRepositoryProvider.overrideWithValue(fakeBroadcasts),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AcademySupportScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap ticket to view thread
      await tester.tap(find.text('Urgent fee invoice tax calculation question'));
      await tester.pumpAndSettle();

      // Academy Admin sees Super Admin reply
      expect(find.text('Super Admin (Platform Support)'), findsOneWidget);
      expect(
        find.text(
          'Sales tax configuration guide sent to your email. Feature enabled.',
        ),
        findsOneWidget,
      );

      // Academy Admin replies back
      final followUpField = find.widgetWithText(
        TextField,
        'Type your message to Super Admin...',
      );
      await tester.enterText(followUpField, 'Verified and working perfectly, thank you!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final ticketAfterFollowUp = await fakeTickets.getTicketById(newTicket.id);
      expect(ticketAfterFollowUp!.messages.length, equals(3));
      expect(
        ticketAfterFollowUp.messages.last.message,
        equals('Verified and working perfectly, thank you!'),
      );
    });

    testWidgets(
        'Super Admin broadcasts message, Academy Admin views it on Noticeboard and Dashboard',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeBroadcasts = _FakePlatformBroadcastRepository();

      // 1. Super Admin publishes a new platform broadcast
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            platformBroadcastRepositoryProvider.overrideWithValue(fakeBroadcasts),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PlatformBroadcastsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Super Admin logs new broadcast
      await tester.tap(find.text('New Broadcast'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notice Title *'),
        'Major Platform v2.0 Release Update',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Detailed Message *'),
        'Multi-campus student portals and fee invoice automation now live.',
      );

      await tester.tap(find.text('Publish Broadcast'));
      await tester.pumpAndSettle();

      final allBroadcasts = await fakeBroadcasts.getBroadcasts();
      expect(allBroadcasts.length, equals(2));
      expect(allBroadcasts.first.title, equals('Major Platform v2.0 Release Update'));

      // 2. Academy Admin opens AnnouncementsScreen (Noticeboard) and switches to "From Super Admin"
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            academyAccessProvider.overrideWith((ref) => Stream.value(fakeAccess)),
            currentAcademyIdProvider.overrideWith((ref) => 'acad_101'),
            platformBroadcastRepositoryProvider.overrideWithValue(fakeBroadcasts),
            announcementsStreamProvider((
              academyId: 'acad_101',
              audience: null,
              branchId: null,
            )).overrideWith((ref) => Stream.value(<Announcement>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AnnouncementsScreen(academyId: 'acad_101'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch tab to Super Admin notices
      await tester.tap(find.textContaining('From Super Admin'));
      await tester.pumpAndSettle();

      // Academy Admin sees Super Admin broadcast
      expect(find.text('Major Platform v2.0 Release Update'), findsOneWidget);
      expect(
        find.text('Multi-campus student portals and fee invoice automation now live.'),
        findsOneWidget,
      );

      // Tap card to inspect details modal
      await tester.tap(find.text('Major Platform v2.0 Release Update'));
      await tester.pumpAndSettle();

      expect(find.text('Super Admin Notice'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // 3. Academy Admin opens Dashboard and sees the top Platform Alert Banner
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            academyAccessProvider.overrideWith((ref) => Stream.value(fakeAccess)),
            currentAcademyIdProvider.overrideWith((ref) => 'acad_101'),
            platformBroadcastRepositoryProvider.overrideWithValue(fakeBroadcasts),
            studentsStreamProvider('acad_101')
                .overrideWith((ref) => Stream.value(<Student>[])),
            staffStreamProvider('acad_101')
                .overrideWith((ref) => Stream.value(<Staff>[])),
            branchesStreamProvider('acad_101')
                .overrideWith((ref) => Stream.value(<Branch>[])),
            paymentsStreamProvider('acad_101')
                .overrideWith((ref) => Stream.value(<FeePayment>[])),
            attendanceForDateProvider((academyId: 'acad_101', date: today))
                .overrideWith((ref) => Stream.value([])),
            announcementsStreamProvider((
              academyId: 'acad_101',
              audience: null,
              branchId: null,
            )).overrideWith((ref) => Stream.value(<Announcement>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AcademyAdminDashboard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Banner should be visible on dashboard
      expect(
        find.text('PLATFORM NOTICE FROM SUPER ADMIN'),
        findsOneWidget,
      );
      expect(
        find.text('Major Platform v2.0 Release Update'),
        findsWidgets,
      );

      // Verify Help Desk tile exists in Manage grid
      await tester.scrollUntilVisible(
        find.text('Help Desk'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Help Desk'), findsOneWidget);
    });

    testWidgets('AcademySupportScreen renders cleanly on narrow 320px phone viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeTickets = _FakeSupportTicketRepository();
      final fakeBroadcasts = _FakePlatformBroadcastRepository();

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
            academyAccessProvider.overrideWith((ref) => Stream.value(fakeAccess)),
            currentAcademyIdProvider.overrideWith((ref) => 'acad_101'),
            supportTicketRepositoryProvider.overrideWithValue(fakeTickets),
            platformBroadcastRepositoryProvider.overrideWithValue(fakeBroadcasts),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AcademySupportScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('My Tickets'), findsOneWidget);
    });
  });
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/app/router.dart';
import 'package:academy_management/features/academics/application/course_repository_provider.dart';
import 'package:academy_management/features/academics/domain/course.dart';
import 'package:academy_management/features/academy_admin/application/academy_access_provider.dart';
import 'package:academy_management/features/academy_admin/application/academy_admin_providers.dart';
import 'package:academy_management/features/academy_admin/domain/academy_access_models.dart';
import 'package:academy_management/features/academy_admin/presentation/academy_admin_modules.dart';
import 'package:academy_management/features/academy_admin/presentation/screens/academy_conversations_screen.dart';
import 'package:academy_management/features/admissions/domain/student.dart';
import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/communication/application/communication_providers.dart';
import 'package:academy_management/features/communication/domain/announcement.dart';
import 'package:academy_management/features/communication/domain/app_notification.dart';
import 'package:academy_management/features/communication/domain/chat_message.dart';
import 'package:academy_management/features/communication/domain/communication_repository.dart';
import 'package:academy_management/features/communication/domain/inquiry.dart';
import 'package:academy_management/features/communication/presentation/screens/academic_chat_screen.dart';
import 'package:academy_management/features/staff/application/staff_providers.dart';
import 'package:academy_management/features/staff/domain/staff.dart';
import 'package:academy_management/features/staff/presentation/screens/staff_students_tab.dart';
import 'package:academy_management/shared/current_academy_provider.dart';

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
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> refreshCurrentUser() async => user;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

class _FakeCommunicationRepository implements CommunicationRepository {
  final List<StudentInquiry> _inquiries = [];
  final List<AppNotification> _notifications = [];
  final StreamController<List<StudentInquiry>> _controller =
      StreamController<List<StudentInquiry>>.broadcast();

  void addInquiries(List<StudentInquiry> items) {
    _inquiries.addAll(items);
    _controller.add(List.unmodifiable(_inquiries));
  }

  @override
  Stream<List<StudentInquiry>> watchAllInquiries(String academyId) async* {
    yield List.unmodifiable(_inquiries);
    yield* _controller.stream;
  }

  @override
  Stream<List<StudentInquiry>> watchInquiriesForStudent(
    String academyId,
    String studentId, {
    String? studentRollNumber,
  }) async* {
    yield _inquiries
        .where((i) => i.studentId == studentId || i.studentRollNumber == studentRollNumber)
        .toList();
    yield* _controller.stream.map((list) => list
        .where((i) => i.studentId == studentId || i.studentRollNumber == studentRollNumber)
        .toList());
  }

  @override
  Stream<List<StudentInquiry>> watchInquiriesForTeacher(
    String academyId,
    String teacherId, {
    String? teacherStaffId,
    String? teacherName,
    List<String>? teacherCourseIds,
  }) async* {
    yield _inquiries
        .where((i) => i.teacherId == teacherId || i.teacherName == teacherName)
        .toList();
    yield* _controller.stream.map((list) => list
        .where((i) => i.teacherId == teacherId || i.teacherName == teacherName)
        .toList());
  }

  @override
  Future<void> submitInquiry(StudentInquiry inquiry) async {
    _inquiries.add(inquiry);
    _controller.add(List.unmodifiable(_inquiries));

    final isTeacherSender = inquiry.isSentByTeacher;
    final recipientId = isTeacherSender ? inquiry.studentId : inquiry.teacherId;
    final recipientRole = isTeacherSender ? 'student' : 'staff';
    final actualSender = inquiry.senderId ?? (isTeacherSender ? inquiry.teacherId : inquiry.studentId);

    if (recipientId.isNotEmpty && recipientId != actualSender) {
      final notif = AppNotification(
        id: 'notif_${_notifications.length + 1}',
        academyId: inquiry.academyId,
        recipientId: recipientId,
        recipientRole: recipientRole,
        title: isTeacherSender
            ? 'Message from ${inquiry.teacherName}'
            : 'New Student Question: ${inquiry.courseName}',
        body: inquiry.question,
        type: isTeacherSender ? 'teacher_message' : 'inquiry_question',
        relatedId: inquiry.id,
        createdAt: DateTime.now(),
      );
      await sendNotification(notif);
    }
  }

  @override
  Future<void> answerInquiry({
    required String academyId,
    required String inquiryId,
    required String reply,
    String status = 'answered',
    String? replierRole,
    String? replierId,
  }) async {
    final idx = _inquiries.indexWhere((i) => i.id == inquiryId);
    if (idx != -1) {
      _inquiries[idx] = _inquiries[idx].copyWith(
        reply: reply,
        status: status,
        answeredAt: DateTime.now(),
      );
      _controller.add(List.unmodifiable(_inquiries));
    }
  }

  @override
  Stream<List<Announcement>> watchAnnouncements(
    String academyId, {
    String? audience,
    String? branchId,
  }) =>
      const Stream.empty();

  @override
  Future<void> sendAnnouncement(Announcement announcement) async {}

  @override
  Future<void> deleteAnnouncement(String academyId, String announcementId) async {}

  @override
  Stream<List<AppNotification>> watchNotifications(
    String academyId, {
    required String recipientId,
    required String recipientRole,
    List<String>? alternativeRecipientIds,
  }) =>
      const Stream.empty();

  @override
  Future<void> sendNotification(AppNotification notification) async {
    _notifications.add(notification);
  }

  @override
  Future<void> markNotificationAsRead(String academyId, String notificationId) async {}

  @override
  Future<void> markAllNotificationsAsRead(String academyId, String recipientId) async {}

  final List<AcademicConversation> _conversations = [];
  final List<ChatMessage> _messages = [];
  final StreamController<List<ChatMessage>> _msgController =
      StreamController<List<ChatMessage>>.broadcast();

  void addConversations(List<AcademicConversation> items) {
    _conversations.addAll(items);
  }

  @override
  Stream<List<ChatMessage>> watchChatMessages(
    String academyId,
    String conversationId,
  ) async* {
    yield _messages.where((m) => m.conversationId == conversationId).toList();
    yield* _msgController.stream.map((list) =>
        list.where((m) => m.conversationId == conversationId).toList());
  }

  @override
  Future<void> sendChatMessage(
    ChatMessage message, {
    required String recipientId,
    required String recipientRole,
  }) async {
    _messages.add(message);
    _msgController.add(List.unmodifiable(_messages));

    if (recipientId.isNotEmpty && recipientId != message.senderId) {
      final notif = AppNotification(
        id: 'notif_${_notifications.length + 1}',
        academyId: message.academyId,
        recipientId: recipientId,
        recipientRole: recipientRole,
        title: 'New message from ${message.senderName}',
        body: message.text,
        type: 'chat_message',
        relatedId: message.conversationId,
        createdAt: DateTime.now(),
      );
      await sendNotification(notif);
    }
  }

  @override
  Stream<List<AcademicConversation>> watchAcademicConversations(
    String academyId, {
    String? teacherId,
    String? studentId,
  }) async* {
    yield _conversations.where((c) {
      if (teacherId != null && teacherId.isNotEmpty && c.teacherId != teacherId) {
        return false;
      }
      if (studentId != null && studentId.isNotEmpty && c.studentId != studentId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<AcademicConversation> getOrCreateConversation({
    required String academyId,
    required String teacherId,
    required String teacherName,
    String teacherStaffId = '',
    required String studentId,
    required String studentName,
    required String studentRollNumber,
    String courseId = '',
    String courseName = 'Academic Guidance',
  }) async {
    final existing = _conversations.where(
        (c) => c.teacherId == teacherId && c.studentId == studentId);
    if (existing.isNotEmpty) return existing.first;

    final conv = AcademicConversation(
      id: 'conv_${teacherId}_$studentId',
      academyId: academyId,
      teacherId: teacherId,
      teacherName: teacherName,
      teacherStaffId: teacherStaffId,
      studentId: studentId,
      studentName: studentName,
      studentRollNumber: studentRollNumber,
      courseId: courseId,
      courseName: courseName,
      lastMessage: 'Conversation opened',
      lastMessageAt: DateTime.now(),
      lastSenderRole: 'teacher',
      lastSenderId: teacherId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _conversations.add(conv);
    return conv;
  }

  void dispose() {
    _controller.close();
    _msgController.close();
  }
}

void main() {
  group('Staff Portal Student Privacy & Direct Chat Tests', () {
    const testAcademyId = 'acad_apex_123';
    const testBranchId = 'branch_main_01';

    final testStaff = Staff(
      id: 'staff_tariq_01',
      academyId: testAcademyId,
      staffId: 'STF-101',
      fullName: 'Dr. Tariq Mehmood',
      phone: '+92 300 1234567',
      email: 'tariq@apex.edu',
      jobTitle: 'Senior Mathematics Lecturer',
      branchId: testBranchId,
      status: 'active',
    );

    final testStudent = Student(
      id: 'stu_001',
      academyId: testAcademyId,
      branchId: testBranchId,
      fullName: 'Hamza Farooq',
      rollNumber: '100001',
      academicSession: '2026-Pre-Eng',
      fatherName: 'Farooq Ahmed',
      guardianPhone: '+92 321 9876543',
      guardianRelation: 'Father',
      gender: 'Male',
      address: 'Gulberg III, Lahore',
      status: 'active',
    );

    testWidgets(
      'Staff cannot see parent phone number on student roster and sees chat action button',
      (tester) async {
        final commRepo = _FakeCommunicationRepository();
        addTearDown(commRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                _FakeAuthRepo(
                  AppUser(
                    id: testStaff.id,
                    email: testStaff.email,
                    displayName: testStaff.fullName,
                    role: AppRole.staff,
                    academyId: testAcademyId,
                  ),
                ),
              ),
              currentStaffMemberProvider.overrideWithValue(testStaff),
              staffBranchStudentsProvider.overrideWithValue([testStudent]),
              currentStaffBranchProvider.overrideWithValue(
                const Branch(
                  id: testBranchId,
                  academyId: testAcademyId,
                  name: 'Main Campus',
                  city: 'Lahore',
                  address: 'Gulberg III',
                  phone: '+92 42 35789012',
                ),
              ),
              communicationRepositoryProvider.overrideWithValue(commRepo),
              staffAssignedCoursesProvider.overrideWithValue([]),
            ],
            child: const MaterialApp(
              home: Scaffold(body: StaffStudentsTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify student is listed with Roll number
        expect(find.text('Hamza Farooq'), findsOneWidget);
        expect(find.text('Roll #100001'), findsOneWidget);

        // GUARDIAN PHONE MUST NOT BE DISPLAYED ON CARD
        expect(find.textContaining('+92 321 9876543'), findsNothing);
        expect(find.textContaining('Parent:'), findsNothing);

        // Per user request: no chat icon on the student record row itself; instead chevron is shown and 'Message Student' is in header
        expect(find.text('Message Student'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      },
    );

    testWidgets(
      'Staff student detail modal hides guardian phone number and allows initiating direct chat with student',
      (tester) async {
        final commRepo = _FakeCommunicationRepository();
        addTearDown(commRepo.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                _FakeAuthRepo(
                  AppUser(
                    id: testStaff.id,
                    email: testStaff.email,
                    displayName: testStaff.fullName,
                    role: AppRole.staff,
                    academyId: testAcademyId,
                  ),
                ),
              ),
              currentStaffMemberProvider.overrideWithValue(testStaff),
              staffBranchStudentsProvider.overrideWithValue([testStudent]),
              currentStaffBranchProvider.overrideWithValue(
                const Branch(
                  id: testBranchId,
                  academyId: testAcademyId,
                  name: 'Main Campus',
                  city: 'Lahore',
                  address: 'Gulberg III',
                  phone: '+92 42 35789012',
                ),
              ),
              communicationRepositoryProvider.overrideWithValue(commRepo),
              staffAssignedCoursesProvider.overrideWithValue([
                const Course(
                  id: 'course_math_12',
                  academyId: testAcademyId,
                  branchId: testBranchId,
                  name: 'Advanced Calculus & Analytical Geometry',
                  courseCode: 'MATH-12',
                  teacherId: 'staff_tariq_01',
                  teacherName: 'Dr. Tariq Mehmood',
                ),
              ]),
            ],
            child: const MaterialApp(
              home: Scaffold(body: StaffStudentsTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the student card to open details modal
        await tester.tap(find.text('Hamza Farooq'));
        await tester.pumpAndSettle();

        // Verify modal opened
        expect(find.text('Father/Guardian'), findsOneWidget);
        expect(find.text('Farooq Ahmed'), findsOneWidget);

        // GUARDIAN PHONE NUMBER MUST NOT BE IN MODAL
        expect(find.text('Guardian Phone'), findsNothing);
        expect(find.text('+92 321 9876543'), findsNothing);

        // Verify privacy notice is shown
        expect(
          find.textContaining('Parent phone numbers are restricted to protect family privacy'),
          findsOneWidget,
        );

        // Verify 'Message Hamza Farooq' action button is present
        expect(find.text('Message Hamza Farooq'), findsOneWidget);

        // Tap 'Message Hamza Farooq'
        await tester.tap(find.text('Message Hamza Farooq'));
        await tester.pumpAndSettle();

        // Verify direct AcademicChatScreen opened
        expect(find.text('Roll #100001 • 2026-Pre-Eng'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // Enter and send message in WhatsApp chat
        await tester.enterText(
          find.byType(TextField),
          'Please review chapter 4 formulas before Friday class.',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        // Verify message rendered in chat
        expect(
          find.text('Please review chapter 4 formulas before Friday class.'),
          findsOneWidget,
        );

        // ZERO SELF-NOTIFICATION INVARIANT:
        // Student receives the notification; Teacher receives ZERO self-notifications!
        expect(commRepo._notifications.length, 1);
        expect(commRepo._notifications.first.recipientId, 'stu_001');
        expect(commRepo._notifications.first.recipientRole, 'student');
        expect(
          commRepo._notifications.any(
            (n) => n.recipientId == testStaff.id || n.recipientId == testStaff.staffId,
          ),
          isFalse,
        );
      },
    );
  });

  group('Academy Admin Conversations Tab & Audit Hub Tests', () {
    const testAcademyId = 'acad_apex_123';

    final testConversation1 = AcademicConversation(
      id: 'conv_01',
      academyId: testAcademyId,
      courseId: 'course_math_12',
      courseName: 'Mathematics 12',
      studentId: 'stu_001',
      studentName: 'Hamza Farooq',
      studentRollNumber: '100001',
      teacherId: 'staff_tariq_01',
      teacherName: 'Dr. Tariq Mehmood',
      lastMessage: 'Sir, on problem 14 of Exercise 3.4, how do we choose u and dv?',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastSenderRole: 'student',
      lastSenderId: 'stu_001',
      unreadCountForTeacher: 1,
      unreadCountForStudent: 0,
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final testConversation2 = AcademicConversation(
      id: 'conv_02',
      academyId: testAcademyId,
      courseId: 'course_physics_12',
      courseName: 'Physics 12',
      studentId: 'stu_002',
      studentName: 'Ayesha Malik',
      studentRollNumber: '100002',
      teacherId: 'staff_ayesha_02',
      teacherName: 'Prof. Ayesha Siddiqua',
      lastMessage: 'Yes Ayesha, both the bridge principle and meter bridge experiment are included.',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 12)),
      lastSenderRole: 'teacher',
      lastSenderId: 'staff_ayesha_02',
      unreadCountForTeacher: 0,
      unreadCountForStudent: 1,
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
    );

    const adminUser = AppUser(
      id: 'admin_01',
      email: 'admin@apex.edu',
      displayName: 'Academy Admin',
      role: AppRole.academyAdmin,
      academyId: testAcademyId,
    );

    const staff1 = Staff(
      id: 'staff_tariq_01',
      academyId: testAcademyId,
      staffId: 'STF-101',
      fullName: 'Dr. Tariq Mehmood',
      phone: '+92 300 1234567',
      email: 'tariq@apex.edu',
      jobTitle: 'Senior Mathematics Lecturer',
      branchId: 'branch_main_01',
      status: 'active',
    );

    const staff2 = Staff(
      id: 'staff_ayesha_02',
      academyId: testAcademyId,
      staffId: 'STF-102',
      fullName: 'Prof. Ayesha Siddiqua',
      phone: '+92 300 7654321',
      email: 'ayesha@apex.edu',
      jobTitle: 'Physics Professor',
      branchId: 'branch_main_01',
      status: 'active',
    );

    const student1 = Student(
      id: 'stu_001',
      academyId: testAcademyId,
      branchId: 'branch_main_01',
      fullName: 'Hamza Farooq',
      rollNumber: '100001',
      academicSession: '2026-Pre-Eng',
      fatherName: 'Farooq Ahmed',
      guardianPhone: '+92 321 9876543',
      guardianRelation: 'Father',
      gender: 'Male',
      address: 'Gulberg III, Lahore',
      status: 'active',
    );

    const student2 = Student(
      id: 'stu_002',
      academyId: testAcademyId,
      branchId: 'branch_main_01',
      fullName: 'Ayesha Malik',
      rollNumber: '100002',
      academicSession: '2026-Pre-Med',
      fatherName: 'Malik Tariq',
      guardianPhone: '+92 322 1122334',
      guardianRelation: 'Father',
      gender: 'Female',
      address: 'DHA Phase 5, Lahore',
      status: 'active',
    );

    test('Conversations module is registered in academyAdminModules', () {
      final module = academyAdminModules.where((m) => m.route == AppRoutes.academyConversations);
      expect(module, isNotEmpty);
      expect(module.first.label, 'Conversations');
      expect(module.first.icon, Icons.forum_outlined);
    });

    testWidgets(
      'AcademyConversationsScreen renders KPI summary cards and lists staff and student tabs',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final commRepo = _FakeCommunicationRepository();
        addTearDown(commRepo.dispose);
        commRepo.addConversations([testConversation1, testConversation2]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_FakeAuthRepo(adminUser)),
              currentAcademyIdProvider.overrideWithValue(testAcademyId),
              academyAccessProvider.overrideWith(
                (ref) => Stream.value(
                  const AcademyAccessInfo(
                    state: AcademyAccessState.active,
                    academyId: testAcademyId,
                    academyName: 'Apex Academic Institute',
                  ),
                ),
              ),
              communicationRepositoryProvider.overrideWithValue(commRepo),
              staffStreamProvider.overrideWith(
                (ref, id) => Stream.value([staff1, staff2]),
              ),
              studentsStreamProvider.overrideWith(
                (ref, id) => Stream.value([student1, student2]),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AcademyConversationsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify title & KPIs
        expect(find.text('Teacher & Student Conversations'), findsOneWidget);
        expect(find.text('Total Chats'), findsOneWidget);
        expect(find.text('2'), findsWidgets); // Total count
        expect(find.text('Faculty Pending'), findsOneWidget);
        expect(find.text('Student Unread'), findsOneWidget);

        // Verify Staff tab by default displays both staff members
        expect(find.text('Dr. Tariq Mehmood'), findsOneWidget);
        expect(find.text('Prof. Ayesha Siddiqua'), findsOneWidget);

        // Switch to Students tab
        await tester.tap(find.textContaining('Students'));
        await tester.pumpAndSettle();

        // Verify Student tab displays both students
        expect(find.text('Hamza Farooq'), findsOneWidget);
        expect(find.text('Roll #100001'), findsWidgets);
        expect(find.text('Ayesha Malik'), findsOneWidget);
        expect(find.text('Roll #100002'), findsWidgets);
      },
    );

    testWidgets(
      'AcademyConversationsScreen drill-down: click teacher shows teacher chats screen, audit opens transcript',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final commRepo = _FakeCommunicationRepository();
        addTearDown(commRepo.dispose);
        commRepo.addConversations([testConversation1, testConversation2]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_FakeAuthRepo(adminUser)),
              currentAcademyIdProvider.overrideWithValue(testAcademyId),
              academyAccessProvider.overrideWith(
                (ref) => Stream.value(
                  const AcademyAccessInfo(
                    state: AcademyAccessState.active,
                    academyId: testAcademyId,
                    academyName: 'Apex Academic Institute',
                  ),
                ),
              ),
              communicationRepositoryProvider.overrideWithValue(commRepo),
              staffStreamProvider.overrideWith(
                (ref, id) => Stream.value([staff1, staff2]),
              ),
              studentsStreamProvider.overrideWith(
                (ref, id) => Stream.value([student1, student2]),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AcademyConversationsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Filter by searching 'Tariq' in Staff Directory
        await tester.enterText(find.byType(TextField).first, 'Tariq');
        await tester.pumpAndSettle();

        expect(find.text('Dr. Tariq Mehmood'), findsOneWidget);
        expect(find.text('Prof. Ayesha Siddiqua'), findsNothing);

        // Tap on Dr. Tariq's card to navigate to TeacherConversationsAuditScreen
        await tester.tap(find.text('Dr. Tariq Mehmood'));
        await tester.pumpAndSettle();

        // Verify we are on TeacherConversationsAuditScreen (Direct WhatsApp chat view)
        expect(find.byType(TeacherConversationsAuditScreen), findsOneWidget);
        expect(find.textContaining('Dr. Tariq Mehmood'), findsWidgets);
        expect(find.textContaining('Hamza Farooq'), findsWidgets);
        expect(find.textContaining('Supervisory Audit Mode'), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);
        expect(find.byIcon(Icons.print_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'AcademyConversationsScreen drill-down: click student shows student chats screen, audit opens transcript',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final commRepo = _FakeCommunicationRepository();
        addTearDown(commRepo.dispose);
        commRepo.addConversations([testConversation1, testConversation2]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_FakeAuthRepo(adminUser)),
              currentAcademyIdProvider.overrideWithValue(testAcademyId),
              academyAccessProvider.overrideWith(
                (ref) => Stream.value(
                  const AcademyAccessInfo(
                    state: AcademyAccessState.active,
                    academyId: testAcademyId,
                    academyName: 'Apex Academic Institute',
                  ),
                ),
              ),
              communicationRepositoryProvider.overrideWithValue(commRepo),
              staffStreamProvider.overrideWith(
                (ref, id) => Stream.value([staff1, staff2]),
              ),
              studentsStreamProvider.overrideWith(
                (ref, id) => Stream.value([student1, student2]),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AcademyConversationsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Students tab
        await tester.tap(find.textContaining('Students'));
        await tester.pumpAndSettle();

        // Filter by searching 'Hamza' in Student Directory
        await tester.enterText(find.byType(TextField).first, 'Hamza');
        await tester.pumpAndSettle();

        expect(find.text('Hamza Farooq'), findsOneWidget);
        expect(find.text('Ayesha Malik'), findsNothing);

        // Tap on Hamza's card to navigate to StudentConversationsAuditScreen
        await tester.tap(find.text('Hamza Farooq'));
        await tester.pumpAndSettle();

        // Verify we are on StudentConversationsAuditScreen (Direct WhatsApp chat view)
        expect(find.byType(StudentConversationsAuditScreen), findsOneWidget);
        expect(find.textContaining('Hamza Farooq'), findsWidgets);
        expect(find.textContaining('Dr. Tariq Mehmood'), findsWidgets);
        expect(find.textContaining('Supervisory Audit Mode'), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);
        expect(find.byIcon(Icons.print_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'Two-Way WhatsApp-style text chat: Student and Teacher exchange messages with anti-echo notifications',
      (tester) async {
        final commRepo = _FakeCommunicationRepository();
        addTearDown(commRepo.dispose);

        const chatStaff = Staff(
          id: 'staff_tariq_01',
          academyId: testAcademyId,
          staffId: 'STF-101',
          fullName: 'Dr. Tariq Mehmood',
          phone: '+92 300 1234567',
          email: 'tariq@apex.edu',
          jobTitle: 'Senior Mathematics Lecturer',
          branchId: 'branch_main_01',
          status: 'active',
        );

        const chatStudent = Student(
          id: 'stu_001',
          academyId: testAcademyId,
          branchId: 'branch_main_01',
          fullName: 'Hamza Farooq',
          rollNumber: '100001',
          academicSession: '2026-Pre-Eng',
          fatherName: 'Farooq Ahmed',
          guardianPhone: '+92 321 9876543',
          guardianRelation: 'Father',
          gender: 'Male',
          address: 'Gulberg III, Lahore',
          status: 'active',
        );

        final teacherUser = AppUser(
          id: chatStaff.id,
          email: chatStaff.email,
          displayName: chatStaff.fullName,
          role: AppRole.staff,
          academyId: testAcademyId,
        );

        // 1. Get or create conversation between teacher and student
        final conv = await commRepo.getOrCreateConversation(
          academyId: testAcademyId,
          teacherId: chatStaff.id,
          teacherName: chatStaff.fullName,
          studentId: chatStudent.id,
          studentName: chatStudent.fullName,
          studentRollNumber: chatStudent.rollNumber,
          courseId: 'course_math_12',
          courseName: 'Mathematics 12',
        );

        // 2. Open chat as Teacher
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_FakeAuthRepo(teacherUser)),
              communicationRepositoryProvider.overrideWithValue(commRepo),
            ],
            child: MaterialApp(
              home: AcademicChatScreen(
                academyId: testAcademyId,
                conversationId: conv.id,
                otherPartyName: chatStudent.fullName,
                otherPartyRole: 'student',
                recipientId: chatStudent.id,
                recipientRole: 'student',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify chat screen UI
        expect(find.text(chatStudent.fullName), findsOneWidget);
        expect(find.text('Online • Academic Chat'), findsOneWidget);

        // Type teacher message and send
        await tester.enterText(
          find.byType(TextField),
          'Hello Hamza, did you review the theorem?',
        );
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        // Verify message rendered in chat
        expect(
          find.text('Hello Hamza, did you review the theorem?'),
          findsOneWidget,
        );

        // Verify notification dispatched to Student, NOT to Teacher (anti-echo)
        expect(commRepo._notifications, isNotEmpty);
        final studentNotif = commRepo._notifications.last;
        expect(studentNotif.recipientId, chatStudent.id);
        expect(studentNotif.recipientRole, 'student');
        expect(studentNotif.body, 'Hello Hamza, did you review the theorem?');
        expect(
            commRepo._notifications.where((n) => n.recipientId == chatStaff.id),
            isEmpty);

        // 3. Now send reply as Student
        final studentReply = ChatMessage(
          id: 'msg_stu_reply_01',
          conversationId: conv.id,
          academyId: testAcademyId,
          senderId: chatStudent.id,
          senderName: chatStudent.fullName,
          senderRole: 'student',
          text: 'Yes Sir, I reviewed it and understood!',
          createdAt: DateTime.now(),
        );

        await commRepo.sendChatMessage(
          studentReply,
          recipientId: chatStaff.id,
          recipientRole: 'staff',
        );
        await tester.pumpAndSettle();

        // Verify student reply appears in chat
        expect(
          find.text('Yes Sir, I reviewed it and understood!'),
          findsOneWidget,
        );

        // Verify notification was sent to Teacher, NOT to Student (anti-echo)
        final teacherNotif = commRepo._notifications.last;
        expect(teacherNotif.recipientId, chatStaff.id);
        expect(teacherNotif.recipientRole, 'staff');
        expect(teacherNotif.body, 'Yes Sir, I reviewed it and understood!');
      },
    );

    testWidgets(
      'Academy Admin audits live WhatsApp text chat in supervisory read-only mode',
      (tester) async {
        final commRepo = _FakeCommunicationRepository();
        addTearDown(commRepo.dispose);

        const chatStaff = Staff(
          id: 'staff_tariq_01',
          academyId: testAcademyId,
          staffId: 'STF-101',
          fullName: 'Dr. Tariq Mehmood',
          phone: '+92 300 1234567',
          email: 'tariq@apex.edu',
          jobTitle: 'Senior Mathematics Lecturer',
          branchId: 'branch_main_01',
          status: 'active',
        );

        const chatStudent = Student(
          id: 'stu_001',
          academyId: testAcademyId,
          branchId: 'branch_main_01',
          fullName: 'Hamza Farooq',
          rollNumber: '100001',
          academicSession: '2026-Pre-Eng',
          fatherName: 'Farooq Ahmed',
          guardianPhone: '+92 321 9876543',
          guardianRelation: 'Father',
          gender: 'Male',
          address: 'Gulberg III, Lahore',
          status: 'active',
        );

        final conv = await commRepo.getOrCreateConversation(
          academyId: testAcademyId,
          teacherId: chatStaff.id,
          teacherName: chatStaff.fullName,
          studentId: chatStudent.id,
          studentName: chatStudent.fullName,
          studentRollNumber: chatStudent.rollNumber,
          courseId: 'course_math_12',
          courseName: 'Mathematics 12',
        );

        await commRepo.sendChatMessage(
          ChatMessage(
            id: 'msg_01',
            conversationId: conv.id,
            academyId: testAcademyId,
            senderId: chatStaff.id,
            senderName: chatStaff.fullName,
            senderRole: 'teacher',
            text: 'Please submit your calculus assignment.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          recipientId: chatStudent.id,
          recipientRole: 'student',
        );

        await commRepo.sendChatMessage(
          ChatMessage(
            id: 'msg_02',
            conversationId: conv.id,
            academyId: testAcademyId,
            senderId: chatStudent.id,
            senderName: chatStudent.fullName,
            senderRole: 'student',
            text: 'I have uploaded it to the portal, thank you Sir!',
            createdAt: DateTime.now(),
          ),
          recipientId: chatStaff.id,
          recipientRole: 'staff',
        );

        // Academy Admin visits AcademyConversationsScreen
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_FakeAuthRepo(adminUser)),
              currentAcademyIdProvider.overrideWithValue(testAcademyId),
              academyAccessProvider.overrideWith(
                (ref) => Stream.value(
                  const AcademyAccessInfo(
                    state: AcademyAccessState.active,
                    academyId: testAcademyId,
                    academyName: 'Apex Academic Institute',
                  ),
                ),
              ),
              communicationRepositoryProvider.overrideWithValue(commRepo),
              staffStreamProvider.overrideWith(
                (ref, id) => Stream.value([chatStaff]),
              ),
              studentsStreamProvider.overrideWith(
                (ref, id) => Stream.value([chatStudent]),
              ),
              coursesStreamProvider.overrideWith((ref, id) => Stream.value([])),
            ],
            child: const MaterialApp(
              home: Scaffold(body: AcademyConversationsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Staff tab renders chatStaff
        expect(find.text('Teacher & Student Conversations'), findsOneWidget);
        expect(find.text('Dr. Tariq Mehmood'), findsOneWidget);

        // Tap Dr. Tariq to open TeacherConversationsAuditScreen (Direct WhatsApp chat view)
        await tester.tap(find.text('Dr. Tariq Mehmood'));
        await tester.pumpAndSettle();

        // Verify supervisory audit mode warning banner
        expect(find.textContaining('Supervisory Audit Mode'), findsOneWidget);
        expect(find.textContaining('Hamza Farooq'), findsWidgets);
        expect(find.textContaining('Mathematics 12'), findsWidgets);

        // Verify both messages are rendered in WhatsApp chat bubbles
        expect(
          find.text('Please submit your calculus assignment.'),
          findsOneWidget,
        );
        expect(
          find.text('I have uploaded it to the portal, thank you Sir!'),
          findsOneWidget,
        );

        // Verify PDF transcript export options are present
        expect(find.byIcon(Icons.print_outlined), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);
      },
    );
  });
}

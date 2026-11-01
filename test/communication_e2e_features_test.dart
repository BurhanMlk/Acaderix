import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:academy_management/core/constants/roles.dart';
import 'package:academy_management/features/academics/application/course_repository_provider.dart';
import 'package:academy_management/features/academics/domain/course.dart';
import 'package:academy_management/features/academics/domain/course_repository.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/app_user.dart';
import 'package:academy_management/features/auth/domain/auth_repository.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/branches/application/branch_repository_provider.dart';
import 'package:academy_management/features/branches/domain/branch.dart';
import 'package:academy_management/features/branches/domain/branch_repository.dart';
import 'package:academy_management/features/communication/application/communication_providers.dart';
import 'package:academy_management/features/communication/domain/announcement.dart';
import 'package:academy_management/features/communication/domain/app_notification.dart';
import 'package:academy_management/features/communication/domain/communication_repository.dart';
import 'package:academy_management/features/communication/domain/inquiry.dart';
import 'package:academy_management/features/communication/presentation/screens/announcements_screen.dart';
import 'package:academy_management/features/communication/presentation/screens/ask_teacher_modal.dart';
import 'package:academy_management/features/communication/presentation/screens/student_inquiries_screen.dart';
import 'package:academy_management/features/communication/presentation/widgets/announcement_card.dart';
import 'package:academy_management/features/communication/presentation/widgets/notification_bell_button.dart';
import 'package:academy_management/features/communication/presentation/widgets/notification_center_modal.dart';
import 'package:academy_management/features/staff/application/staff_providers.dart';
import 'package:academy_management/features/staff/domain/staff.dart';
import 'package:academy_management/features/student/application/student_providers.dart';
import 'package:academy_management/features/admissions/domain/student.dart';

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

class _FakeBranchRepo implements BranchRepository {
  final List<Branch> _branches = [];
  void addBranches(List<Branch> branches) => _branches.addAll(branches);

  @override
  Stream<List<Branch>> watchAll(String academyId) => Stream.value(_branches);

  @override
  Future<void> create(Branch branch) async => _branches.add(branch);

  @override
  Future<void> update(Branch branch) async {
    final idx = _branches.indexWhere((b) => b.id == branch.id);
    if (idx != -1) _branches[idx] = branch;
  }

  @override
  Future<void> delete(String academyId, String branchId) async {
    _branches.removeWhere((b) => b.id == branchId);
  }
}

class _FakeCourseRepo implements CourseRepository {
  final List<Course> _courses = [];
  void addCourses(List<Course> courses) => _courses.addAll(courses);

  @override
  Stream<List<Course>> watchAll(String academyId) => Stream.value(_courses);

  @override
  Stream<List<Course>> watchByBranch(String academyId, String branchId) =>
      Stream.value(_courses.where((c) => c.branchId == branchId).toList());

  @override
  Stream<List<Course>> watchByTeacher(String academyId, String teacherId) =>
      Stream.value(_courses.where((c) => c.teacherId == teacherId).toList());

  @override
  Future<Course?> getById(String academyId, String courseId) async =>
      _courses.where((c) => c.id == courseId).firstOrNull;

  @override
  Future<void> saveCourse(Course course) async => _courses.add(course);

  @override
  Future<void> deleteCourse(String academyId, String courseId) async =>
      _courses.removeWhere((c) => c.id == courseId);

  @override
  Future<void> enrollStudents(
    String academyId,
    String courseId,
    List<String> studentIds,
  ) async {}

  @override
  Future<void> unenrollStudent(
    String academyId,
    String courseId,
    String studentId,
  ) async {}
}

class _FakeCommunicationRepo implements CommunicationRepository {
  _FakeCommunicationRepo({
    List<Announcement>? announcements,
    List<StudentInquiry>? inquiries,
    List<AppNotification>? notifications,
  })  : _announcements = announcements ?? [],
        _inquiries = inquiries ?? [],
        _notifications = notifications ?? [] {
    _announcementsCtrl = StreamController<List<Announcement>>.broadcast();
    _inquiriesCtrl = StreamController<List<StudentInquiry>>.broadcast();
    _notificationsCtrl = StreamController<List<AppNotification>>.broadcast();
  }

  final List<Announcement> _announcements;
  final List<StudentInquiry> _inquiries;
  final List<AppNotification> _notifications;

  late final StreamController<List<Announcement>> _announcementsCtrl;
  late final StreamController<List<StudentInquiry>> _inquiriesCtrl;
  late final StreamController<List<AppNotification>> _notificationsCtrl;

  void dispose() {
    _announcementsCtrl.close();
    _inquiriesCtrl.close();
    _notificationsCtrl.close();
  }

  void _emitAnnouncements() => _announcementsCtrl.add(List.from(_announcements));
  void _emitInquiries() => _inquiriesCtrl.add(List.from(_inquiries));
  void _emitNotifications() => _notificationsCtrl.add(List.from(_notifications));

  @override
  Stream<List<Announcement>> watchAnnouncements(
    String academyId, {
    String? audience,
    String? branchId,
    String? courseId,
  }) async* {
    yield _filterAnnouncements(audience: audience);
    yield* _announcementsCtrl.stream
        .map((_) => _filterAnnouncements(audience: audience));
  }

  List<Announcement> _filterAnnouncements({String? audience}) {
    if (audience == null || audience == 'all') return List.from(_announcements);
    return _announcements
        .where((a) => a.audience == 'all' || a.audience == audience)
        .toList();
  }

  Future<String> createAnnouncement(Announcement announcement) async {
    final id = announcement.id.isNotEmpty
        ? announcement.id
        : 'ann_${DateTime.now().millisecondsSinceEpoch}';
    final saved = announcement.copyWith(id: id);
    _announcements.insert(0, saved);

    // Auto-generate fan-out in-app notification
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        academyId: saved.academyId,
        recipientRole: saved.audience,
        title: '📢 Notice: ${saved.title}',
        body: saved.content,
        type: 'announcement',
        relatedId: saved.id,
        createdAt: DateTime.now(),
      ),
    );

    _emitAnnouncements();
    _emitNotifications();
    return id;
  }

  @override
  Future<void> sendAnnouncement(Announcement announcement) async {
    await createAnnouncement(announcement);
  }

  @override
  Future<void> deleteAnnouncement(
      String academyId, String announcementId) async {
    _announcements.removeWhere((a) => a.id == announcementId);
    _emitAnnouncements();
  }

  @override
  Stream<List<StudentInquiry>> watchInquiriesForStudent(
    String academyId,
    String studentId,
  ) async* {
    yield _inquiries.where((i) => i.studentId == studentId).toList();
    yield* _inquiriesCtrl.stream
        .map((list) => list.where((i) => i.studentId == studentId).toList());
  }

  @override
  Stream<List<StudentInquiry>> watchInquiriesForTeacher(
    String academyId,
    String teacherId,
  ) async* {
    yield _inquiries.where((i) => i.teacherId == teacherId).toList();
    yield* _inquiriesCtrl.stream
        .map((list) => list.where((i) => i.teacherId == teacherId).toList());
  }

  @override
  Stream<List<StudentInquiry>> watchAllInquiries(String academyId) async* {
    yield List.from(_inquiries);
    yield* _inquiriesCtrl.stream.map((list) => List.from(list));
  }

  @override
  Future<void> submitInquiry(StudentInquiry inquiry) async {
    final id = inquiry.id.isNotEmpty
        ? inquiry.id
        : 'inq_${DateTime.now().millisecondsSinceEpoch}';
    final saved = inquiry.copyWith(id: id);
    _inquiries.insert(0, saved);

    // Auto-notify teacher
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        academyId: saved.academyId,
        recipientId: saved.teacherId,
        recipientRole: 'staff',
        title: '❓ Question: ${saved.courseName}',
        body: '${saved.studentName}: ${saved.subject}',
        type: 'inquiry_question',
        relatedId: saved.id,
        createdAt: DateTime.now(),
      ),
    );

    _emitInquiries();
    _emitNotifications();
  }

  @override
  Future<void> answerInquiry({
    required String academyId,
    required String inquiryId,
    required String reply,
    String status = 'answered',
  }) async {
    final idx = _inquiries.indexWhere((i) => i.id == inquiryId);
    if (idx != -1) {
      final updated = _inquiries[idx].copyWith(
        reply: reply,
        status: status,
        answeredAt: DateTime.now(),
      );
      _inquiries[idx] = updated;

      // Auto-notify student
      _notifications.insert(
        0,
        AppNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          academyId: academyId,
          recipientId: updated.studentId,
          recipientRole: 'student',
          title: '✅ Reply from ${updated.teacherName}',
          body: reply,
          type: 'inquiry_reply',
          relatedId: updated.id,
          createdAt: DateTime.now(),
        ),
      );

      _emitInquiries();
      _emitNotifications();
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications(
    String academyId, {
    required String recipientId,
    required String recipientRole,
  }) async* {
    yield _filterNotifications(
      recipientId: recipientId,
      recipientRole: recipientRole,
    );
    yield* _notificationsCtrl.stream.map((_) => _filterNotifications(
          recipientId: recipientId,
          recipientRole: recipientRole,
        ));
  }

  List<AppNotification> _filterNotifications({
    required String recipientId,
    required String recipientRole,
  }) {
    return _notifications.where((n) {
      if (n.recipientId != 'broadcast' &&
          n.recipientId.isNotEmpty &&
          n.recipientId != recipientId) {
        return false;
      }
      if (recipientRole != 'all' &&
          n.recipientRole != 'all' &&
          n.recipientRole != recipientRole) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> sendNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    _emitNotifications();
  }

  @override
  Future<void> markNotificationAsRead(
      String academyId, String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _emitNotifications();
    }
  }

  @override
  Future<void> markAllNotificationsAsRead(
    String academyId,
    String recipientId,
  ) async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _emitNotifications();
  }
}

void main() {
  const testAcademyId = 'acad_test_101';

  const sampleBranch = Branch(
    id: 'br_main',
    academyId: testAcademyId,
    name: 'Main Campus',
    city: 'City Centre',
    phone: '042-111-222',
  );

  final sampleCourse = Course(
    id: 'crs_math_10',
    academyId: testAcademyId,
    branchId: 'br_main',
    name: 'Advanced Mathematics',
    courseCode: 'MTH-101',
    description: 'Calculus, trigonometry, and algebra',
    teacherId: 'staff_t1',
    teacherName: 'Prof. Tariq',
    room: 'Lab-A',
    schedule: 'Mon, Wed 09:00 AM - 10:30 AM',
    enrolledStudentIds: ['stu_1'],
    isActive: true,
  );

  const sampleStudent = Student(
    id: 'stu_1',
    academyId: testAcademyId,
    branchId: 'br_main',
    fullName: 'Hamza Khan',
    rollNumber: '100001',
    phone: '0300-1111111',
    gender: 'Male',
    academicSession: '2026-2027',
  );

  final sampleTeacher = Staff(
    id: 'staff_t1',
    academyId: testAcademyId,
    branchId: 'br_main',
    fullName: 'Prof. Tariq',
    email: 'tariq@test.com',
    phone: '0300-2222222',
    jobTitle: 'Senior Math Faculty',
    staffId: 'STAFF-101',
  );

  const studentUser = AppUser(
    id: 'u_student_1',
    email: 'hamza@test.com',
    displayName: 'Hamza Khan',
    role: AppRole.student,
    academyId: testAcademyId,
  );

  const teacherUser = AppUser(
    id: 'u_teacher_1',
    email: 'tariq@test.com',
    displayName: 'Prof. Tariq',
    role: AppRole.staff,
    academyId: testAcademyId,
  );

  const adminUser = AppUser(
    id: 'u_admin_1',
    email: 'admin@test.com',
    displayName: 'Academy Principal',
    role: AppRole.academyAdmin,
    academyId: testAcademyId,
  );

  group('Communication Domain Models Unit Tests', () {
    test('Announcement serialization and copyWith', () {
      final ann = Announcement(
        id: 'ann_1',
        academyId: testAcademyId,
        title: 'Exam Guidelines',
        content: 'Please arrive 15 minutes before the exam begins.',
        audience: 'students',
        priority: 'urgent',
        category: 'academic',
        authorName: 'Admin Desk',
        createdAt: DateTime(2026, 11, 1, 10, 0),
        isPinned: true,
      );

      final json = ann.toJson();
      expect(json['title'], 'Exam Guidelines');
      expect(json['priority'], 'urgent');
      expect(json['isPinned'], true);

      final restored = Announcement.fromJson(json);
      expect(restored.id, 'ann_1');
      expect(restored.audience, 'students');
      expect(restored.isPinned, true);

      final updated = restored.copyWith(priority: 'normal');
      expect(updated.priority, 'normal');
    });

    test('Inquiry serialization and status transitions', () {
      final inq = StudentInquiry(
        id: 'inq_1',
        academyId: testAcademyId,
        studentId: 'stu_1',
        studentName: 'Hamza Khan',
        studentRollNumber: '100001',
        teacherId: 'staff_t1',
        teacherName: 'Prof. Tariq',
        courseId: 'crs_math_10',
        courseName: 'Advanced Mathematics',
        subject: 'Derivative of polynomial',
        question: 'Should we use power rule or quotient rule for problem 4?',
        status: 'open',
        createdAt: DateTime(2026, 11, 1, 12, 0),
      );

      expect(inq.status, 'open');
      expect(inq.reply, isEmpty);

      final answered = inq.copyWith(
        reply: 'Use the standard power rule after factoring out the constant.',
        status: 'answered',
        answeredAt: DateTime(2026, 11, 1, 13, 0),
      );

      expect(answered.status, 'answered');
      expect(answered.reply, contains('power rule'));
      expect(answered.answeredAt, isNotNull);
    });

    test('AppNotification serialization and reading', () {
      final notif = AppNotification(
        id: 'notif_1',
        academyId: testAcademyId,
        recipientId: 'stu_1',
        recipientRole: 'student',
        title: 'New Announcement',
        body: 'Check the bulletin board',
        type: 'announcement',
        relatedId: 'ann_1',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(notif.isRead, false);
      final read = notif.copyWith(isRead: true);
      expect(read.isRead, true);
    });
  });

  group('Communication Repository & Notification Fanout E2E', () {
    test('Admin publishes announcement -> generates in-app notification',
        () async {
      final repo = _FakeCommunicationRepo();

      final id = await repo.createAnnouncement(
        Announcement(
          id: 'ann_test',
          academyId: testAcademyId,
          title: 'Campus Winter Break Notice',
          content: 'Classes will remain suspended from Dec 24 through Jan 2.',
          audience: 'all',
          priority: 'urgent',
          authorName: 'Principal',
        ),
      );

      expect(id, isNotEmpty);

      // Verify announcement in stream
      final announcements =
          await repo.watchAnnouncements(testAcademyId).first;
      expect(announcements.length, 1);
      expect(announcements.first.title, 'Campus Winter Break Notice');

      // Verify fan-out in-app notification generated
      final notifications = await repo
          .watchNotifications(
            testAcademyId,
            recipientId: 'stu_1',
            recipientRole: 'student',
          )
          .first;
      expect(notifications.length, 1);
      expect(notifications.first.type, 'announcement');
      expect(notifications.first.title,
          contains('Campus Winter Break Notice'));

      repo.dispose();
    });

    test('Student asks teacher -> teacher answers -> student notified',
        () async {
      final repo = _FakeCommunicationRepo();

      // 1. Student submits inquiry
      await repo.submitInquiry(
        StudentInquiry(
          id: 'inq_1',
          academyId: testAcademyId,
          studentId: 'stu_1',
          studentName: 'Hamza Khan',
          studentRollNumber: '100001',
          teacherId: 'staff_t1',
          teacherName: 'Prof. Tariq',
          courseId: 'crs_math_10',
          courseName: 'Advanced Mathematics',
          subject: 'Integration by Parts',
          question: 'Can you provide another worked example for homework?',
          createdAt: DateTime.now(),
        ),
      );

      // Verify teacher received question notification
      var notifications = await repo
          .watchNotifications(
            testAcademyId,
            recipientId: 'staff_t1',
            recipientRole: 'staff',
          )
          .first;
      expect(notifications.length, 1);
      expect(notifications.first.type, 'inquiry_question');
      expect(notifications.first.title, contains('Advanced Mathematics'));

      // 2. Teacher replies
      await repo.answerInquiry(
        academyId: testAcademyId,
        inquiryId: 'inq_1',
        reply: 'Refer to textbook Chapter 7, Page 142, Examples 3 and 4.',
      );

      // Verify inquiry updated to answered
      final inquiries =
          await repo.watchInquiriesForStudent(testAcademyId, 'stu_1').first;
      expect(inquiries.first.status, 'answered');
      expect(inquiries.first.reply, contains('Page 142'));

      // Verify student received answer notification
      notifications = await repo
          .watchNotifications(
            testAcademyId,
            recipientId: 'stu_1',
            recipientRole: 'student',
          )
          .first;
      expect(notifications.any((n) => n.type == 'inquiry_reply'), isTrue);

      // 3. Student marks notification as read
      final notifId =
          notifications.firstWhere((n) => n.type == 'inquiry_reply').id;
      await repo.markNotificationAsRead(testAcademyId, notifId);

      final updatedNotifs = await repo
          .watchNotifications(
            testAcademyId,
            recipientId: 'stu_1',
            recipientRole: 'student',
          )
          .first;
      expect(
          updatedNotifs.firstWhere((n) => n.id == notifId).isRead, isTrue);

      repo.dispose();
    });
  });

  group('Communication UI Components Widget Tests', () {
    testWidgets('AnnouncementCard renders urgent badge and pinned star',
        (tester) async {
      final announcement = Announcement(
        id: 'ann_test',
        academyId: testAcademyId,
        title: 'Emergency Weather Advisory',
        content: 'Campus will close at 1:00 PM today due to heavy snowfall.',
        audience: 'all',
        priority: 'urgent',
        category: 'general',
        authorName: 'Principal Office',
        createdAt: DateTime.now(),
        isPinned: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementCard(
              announcement: announcement,
            ),
          ),
        ),
      );

      expect(find.text('Emergency Weather Advisory'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.textContaining('Principal Office'), findsOneWidget);
    });

    testWidgets('NotificationBellButton displays red badge on unread alerts',
        (tester) async {
      final repo = _FakeCommunicationRepo(
        notifications: [
          AppNotification(
            id: 'n1',
            academyId: testAcademyId,
            recipientId: 'broadcast',
            recipientRole: 'all',
            title: 'Urgent Alert',
            body: 'Meeting in auditorium',
            type: 'announcement',
            isRead: false,
          ),
          AppNotification(
            id: 'n2',
            academyId: testAcademyId,
            recipientId: 'broadcast',
            recipientRole: 'all',
            title: 'Assignment Graded',
            body: 'Your scores are posted',
            type: 'inquiry_reply',
            isRead: false,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo(adminUser)),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  NotificationBellButton(
                    academyId: testAcademyId,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge count "2" should be rendered
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      // Tapping bell opens notification center modal
      await tester.tap(find.byType(NotificationBellButton));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Urgent Alert'), findsOneWidget);
      expect(find.text('Assignment Graded'), findsOneWidget);

      repo.dispose();
    });

    testWidgets('NotificationCenterModal filters and marks all as read',
        (tester) async {
      final repo = _FakeCommunicationRepo(
        notifications: [
          AppNotification(
            id: 'n1',
            academyId: testAcademyId,
            recipientId: 'broadcast',
            recipientRole: 'all',
            title: 'Campus Notice 1',
            body: 'Body text',
            type: 'broadcast',
            isRead: false,
          ),
          AppNotification(
            id: 'n2',
            academyId: testAcademyId,
            recipientId: 'broadcast',
            recipientRole: 'all',
            title: 'Teacher Reply 1',
            body: 'Body text',
            type: 'inquiry_reply',
            isRead: false,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo(adminUser)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenterModal(
                academyId: testAcademyId,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both notifications visible initially
      expect(find.text('Campus Notice 1'), findsOneWidget);
      expect(find.text('Teacher Reply 1'), findsOneWidget);

      // Filter by 'Inquiries'
      await tester.tap(find.textContaining('Inquiries'));
      await tester.pumpAndSettle();

      expect(find.text('Teacher Reply 1'), findsOneWidget);
      expect(find.text('Campus Notice 1'), findsNothing);

      // Filter by 'Announcements'
      await tester.tap(find.textContaining('Announcements'));
      await tester.pumpAndSettle();

      expect(find.text('Campus Notice 1'), findsOneWidget);
      expect(find.text('Teacher Reply 1'), findsNothing);

      // Mark all as read
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      // All unread badges cleared
      expect(find.text('UNREAD'), findsNothing);

      repo.dispose();
    });

    testWidgets(
        'AskTeacherModal submits student question with auto-filled faculty',
        (tester) async {
      final repo = _FakeCommunicationRepo();
      final authRepo = _FakeAuthRepo(studentUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(authRepo),
            currentStudentProfileProvider.overrideWithValue(sampleStudent),
            currentStudentCoursesProvider.overrideWithValue([sampleCourse]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAskTeacherModal(
                    context,
                    academyId: testAcademyId,
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Ask Teacher a Question'), findsOneWidget);

      // Enter topic/subject
      final subjectFinder = find.byType(TextField).at(0);
      await tester.enterText(subjectFinder, 'Need help with Integration problem');
      await tester.pump();

      // Enter detailed question
      final questionFinder = find.byType(TextField).at(1);
      await tester.enterText(
          questionFinder, 'Could you please explain step 3 of the theorem derivation?');
      await tester.pump();

      // Tap submit
      await tester.tap(find.text('Send Question to Teacher'));
      await tester.pumpAndSettle();

      // Verify question stored in repository
      final inquiries =
          await repo.watchInquiriesForStudent(testAcademyId, 'stu_1').first;
      expect(inquiries.length, 1);
      expect(inquiries.first.subject, 'Need help with Integration problem');
      expect(inquiries.first.teacherName, 'Prof. Tariq');
      expect(inquiries.first.courseName, 'Advanced Mathematics');

      repo.dispose();
    });

    testWidgets(
        'StudentInquiriesScreen displays inquiries and enables teacher replies',
        (tester) async {
      final repo = _FakeCommunicationRepo(
        inquiries: [
          StudentInquiry(
            id: 'inq_test_1',
            academyId: testAcademyId,
            studentId: 'stu_1',
            studentName: 'Hamza Khan',
            studentRollNumber: '100001',
            teacherId: 'staff_t1',
            teacherName: 'Prof. Tariq',
            courseId: 'crs_math_10',
            courseName: 'Advanced Mathematics',
            subject: 'Trigonometry identities',
            question: 'Is sin^2(x) + cos^2(x) = 1 true for all radians?',
            status: 'open',
            createdAt: DateTime.now(),
          ),
        ],
      );

      final authRepo = _FakeAuthRepo(teacherUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(authRepo),
            currentStaffMemberProvider.overrideWithValue(sampleTeacher),
          ],
          child: const MaterialApp(
            home: StudentInquiriesScreen(
              academyId: testAcademyId,
              teacherId: 'staff_t1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Student Q&A Desk'), findsOneWidget);
      expect(find.text('Trigonometry identities'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Teacher taps "Reply to Student"
      await tester.tap(find.text('Reply to Student'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Reply to Hamza Khan'), findsOneWidget);

      // Type reply
      final replyInput =
          find.widgetWithText(TextFormField, 'Type your explanation or guidance here...');
      await tester.enterText(replyInput,
          'Yes, it is the fundamental Pythagorean trigonometric identity for all real radians.');
      await tester.pump();

      // Submit reply
      await tester.tap(find.text('Send Reply & Notify Student'));
      await tester.pumpAndSettle();

      // Verify updated status
      expect(find.text('Answered'), findsWidgets);
      expect(find.textContaining('Pythagorean trigonometric identity'),
          findsOneWidget);

      repo.dispose();
    });

    testWidgets(
        'AnnouncementsScreen creates message cast announcement with push notification',
        (tester) async {
      final repo = _FakeCommunicationRepo();
      final authRepo = _FakeAuthRepo(adminUser);
      final branchRepo = _FakeBranchRepo()..addBranches([sampleBranch]);
      final courseRepo = _FakeCourseRepo()..addCourses([sampleCourse]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(authRepo),
            courseRepositoryProvider.overrideWithValue(courseRepo),
            branchRepositoryProvider.overrideWithValue(branchRepo),
            coursesStreamProvider.overrideWith(
                (ref, arg) => Stream.value([sampleCourse])),
          ],
          child: const MaterialApp(
            home: AnnouncementsScreen(academyId: testAcademyId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Noticeboard & Broadcasts'), findsOneWidget);
      expect(find.text('Broadcast Announcement'), findsOneWidget);

      // Open broadcast modal
      await tester.tap(find.text('Broadcast Announcement'));
      await tester.pumpAndSettle();

      expect(find.text('Broadcast New Message'), findsOneWidget);

      // Select Urgent priority while visible near top
      await tester.tap(find.text('Urgent Alert'));
      await tester.pumpAndSettle();

      // Fill title
      final titleFinder = find.byType(TextField).first;
      await tester.enterText(titleFinder, 'Annual Sports Gala Next Month');
      await tester.pump();

      // Scroll modal sheet down to bring content field and broadcast button into view
      await tester.drag(find.byType(ListView).last, const Offset(0, -350));
      await tester.pumpAndSettle();

      final contentFinder = find.byType(TextField).last;
      await tester.enterText(contentFinder,
          'All branch teams will compete in athletics, badminton, and cricket.');
      await tester.pump();

      // Tap Send Broadcast
      await tester.tap(find.text('Broadcast & Send Push Alert'));
      await tester.pumpAndSettle();

      // Verify announcement and alert created
      expect(find.text('Annual Sports Gala Next Month'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);

      final announcements =
          await repo.watchAnnouncements(testAcademyId).first;
      expect(announcements.length, 1);
      expect(announcements.first.title, 'Annual Sports Gala Next Month');
      expect(announcements.first.priority, 'urgent');

      repo.dispose();
    });
  });

  group('Narrow Viewport Responsiveness (320px width)', () {
    testWidgets('Zero overflow on 320x640 mobile screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeCommunicationRepo(
        announcements: [
          Announcement(
            id: 'ann_narrow',
            academyId: testAcademyId,
            title:
                'Very Long Headline That Should Wrap Properly Without Causing Overflow',
            content: 'Full broadcast text for mobile testing',
            audience: 'all',
            priority: 'urgent',
            category: 'academic',
            authorName: 'Administration Principal',
            courseName: 'Advanced Mathematics',
            createdAt: DateTime.now(),
            isPinned: true,
          ),
        ],
        inquiries: [
          StudentInquiry(
            id: 'inq_narrow',
            academyId: testAcademyId,
            studentId: 'stu_1',
            studentName: 'Hamza Khan Full Student Name',
            studentRollNumber: '100001',
            teacherId: 'staff_t1',
            teacherName: 'Prof. Tariq Mathematics Faculty',
            courseId: 'crs_math_10',
            courseName: 'Advanced Mathematics Grade 10',
            subject:
                'A very detailed subject title that spans multiple lines on narrow screens',
            question: 'This is the question content.',
            status: 'answered',
            reply: 'This is the teacher reply with full guidance.',
            createdAt: DateTime.now(),
            answeredAt: DateTime.now(),
          ),
        ],
        notifications: [
          AppNotification(
            id: 'n_narrow',
            academyId: testAcademyId,
            title: 'Long Notification Title Here',
            body: 'Long notification body description here',
            type: 'broadcast',
            isRead: false,
          ),
        ],
      );

      final authRepo = _FakeAuthRepo(studentUser);
      final branchRepo = _FakeBranchRepo()..addBranches([sampleBranch]);
      final courseRepo = _FakeCourseRepo()..addCourses([sampleCourse]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(authRepo),
            currentStaffMemberProvider.overrideWithValue(sampleTeacher),
            currentStudentProfileProvider.overrideWithValue(sampleStudent),
            courseRepositoryProvider.overrideWithValue(courseRepo),
            branchRepositoryProvider.overrideWithValue(branchRepo),
            coursesStreamProvider.overrideWith(
                (ref, arg) => Stream.value([sampleCourse])),
          ],
          child: const MaterialApp(
            home: StudentInquiriesScreen(academyId: testAcademyId),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Also render AnnouncementsScreen on 320px
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('announcements_scope'),
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(authRepo),
            courseRepositoryProvider.overrideWithValue(courseRepo),
            branchRepositoryProvider.overrideWithValue(branchRepo),
            coursesStreamProvider.overrideWith(
                (ref, arg) => Stream.value([sampleCourse])),
          ],
          child: const MaterialApp(
            home: AnnouncementsScreen(academyId: testAcademyId),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Also render NotificationCenterModal on 320px
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('notif_scope'),
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenterModal(academyId: testAcademyId),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      repo.dispose();
    });
  });
}

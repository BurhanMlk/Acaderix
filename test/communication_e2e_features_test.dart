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
import 'package:academy_management/features/communication/domain/chat_message.dart';
import 'package:academy_management/features/communication/domain/communication_repository.dart';
import 'package:academy_management/features/communication/domain/inquiry.dart';
import 'package:academy_management/features/communication/presentation/screens/academic_chat_screen.dart';
import 'package:academy_management/features/communication/presentation/screens/announcements_screen.dart';
import 'package:academy_management/features/communication/presentation/screens/student_inquiries_screen.dart';
import 'package:academy_management/features/communication/presentation/screens/teacher_initiate_chat_modal.dart';
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
    List<AcademicConversation>? conversations,
  })  : _announcements = announcements ?? [],
        _inquiries = inquiries ?? [],
        _notifications = notifications ?? [],
        _conversations = conversations ?? [] {
    _announcementsCtrl = StreamController<List<Announcement>>.broadcast();
    _inquiriesCtrl = StreamController<List<StudentInquiry>>.broadcast();
    _notificationsCtrl = StreamController<List<AppNotification>>.broadcast();
    _conversationsCtrl = StreamController<List<AcademicConversation>>.broadcast();
    _messagesCtrl = StreamController<Map<String, List<ChatMessage>>>.broadcast();
  }

  final List<Announcement> _announcements;
  final List<StudentInquiry> _inquiries;
  final List<AppNotification> _notifications;
  final List<AcademicConversation> _conversations;
  final Map<String, List<ChatMessage>> _messages = {};

  late final StreamController<List<Announcement>> _announcementsCtrl;
  late final StreamController<List<StudentInquiry>> _inquiriesCtrl;
  late final StreamController<List<AppNotification>> _notificationsCtrl;
  late final StreamController<List<AcademicConversation>> _conversationsCtrl;
  late final StreamController<Map<String, List<ChatMessage>>> _messagesCtrl;

  void dispose() {
    _announcementsCtrl.close();
    _inquiriesCtrl.close();
    _notificationsCtrl.close();
    _conversationsCtrl.close();
    _messagesCtrl.close();
  }

  void _emitAnnouncements() => _announcementsCtrl.add(List.from(_announcements));
  void _emitInquiries() => _inquiriesCtrl.add(List.from(_inquiries));
  void _emitNotifications() => _notificationsCtrl.add(List.from(_notifications));
  void _emitConversations() => _conversationsCtrl.add(List.from(_conversations));
  void _emitMessages() => _messagesCtrl.add(Map.from(_messages));

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
    String studentId, {
    String? studentRollNumber,
  }) async* {
    yield _filterStudentInquiries(studentId, studentRollNumber);
    yield* _inquiriesCtrl.stream.map(
        (_) => _filterStudentInquiries(studentId, studentRollNumber));
  }

  List<StudentInquiry> _filterStudentInquiries(
      String studentId, String? studentRollNumber) {
    return _inquiries.where((i) {
      if (i.studentId == studentId) return true;
      if (studentRollNumber != null &&
          studentRollNumber.isNotEmpty &&
          i.studentRollNumber == studentRollNumber) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Stream<List<StudentInquiry>> watchInquiriesForTeacher(
    String academyId,
    String teacherId, {
    String? teacherStaffId,
    String? teacherName,
    List<String>? teacherCourseIds,
  }) async* {
    yield _filterTeacherInquiries(
      teacherId,
      teacherStaffId: teacherStaffId,
      teacherName: teacherName,
      teacherCourseIds: teacherCourseIds,
    );
    yield* _inquiriesCtrl.stream.map((_) => _filterTeacherInquiries(
          teacherId,
          teacherStaffId: teacherStaffId,
          teacherName: teacherName,
          teacherCourseIds: teacherCourseIds,
        ));
  }

  List<StudentInquiry> _filterTeacherInquiries(
    String teacherId, {
    String? teacherStaffId,
    String? teacherName,
    List<String>? teacherCourseIds,
  }) {
    return _inquiries.where((i) {
      if (i.teacherId == teacherId) return true;
      if (teacherStaffId != null &&
          teacherStaffId.isNotEmpty &&
          i.teacherId.toLowerCase() == teacherStaffId.toLowerCase()) {
        return true;
      }
      if (teacherName != null &&
          teacherName.isNotEmpty &&
          i.teacherName.toLowerCase() == teacherName.toLowerCase()) {
        return true;
      }
      if (teacherCourseIds != null &&
          teacherCourseIds.contains(i.courseId)) {
        return true;
      }
      return false;
    }).toList();
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
    String? replierRole,
    String? replierId,
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
    List<String>? alternativeRecipientIds,
  }) async* {
    yield _filterNotifications(
      recipientId: recipientId,
      recipientRole: recipientRole,
      alternativeRecipientIds: alternativeRecipientIds,
    );
    yield* _notificationsCtrl.stream.map((_) => _filterNotifications(
          recipientId: recipientId,
          recipientRole: recipientRole,
          alternativeRecipientIds: alternativeRecipientIds,
        ));
  }

  List<AppNotification> _filterNotifications({
    required String recipientId,
    required String recipientRole,
    List<String>? alternativeRecipientIds,
  }) {
    return _notifications.where((n) {
      if (n.recipientId != 'broadcast' &&
          n.recipientId.isNotEmpty &&
          n.recipientId != recipientId &&
          !(alternativeRecipientIds != null &&
              alternativeRecipientIds.contains(n.recipientId))) {
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

  @override
  Stream<List<ChatMessage>> watchChatMessages(
    String academyId,
    String conversationId,
  ) async* {
    yield List.from(_messages[conversationId] ?? []);
    yield* _messagesCtrl.stream.map((m) => List.from(m[conversationId] ?? []));
  }

  @override
  Future<void> sendChatMessage(
    ChatMessage message, {
    required String recipientId,
    required String recipientRole,
  }) async {
    _messages.putIfAbsent(message.conversationId, () => []).add(message);
    final convIdx =
        _conversations.indexWhere((c) => c.id == message.conversationId);
    if (convIdx != -1) {
      _conversations[convIdx] = _conversations[convIdx].copyWith(
        lastMessage: message.text,
        lastMessageAt: message.createdAt,
      );
    }
    if (recipientId.isNotEmpty && recipientId != message.senderId) {
      _notifications.insert(
        0,
        AppNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          academyId: message.academyId,
          recipientId: recipientId,
          recipientRole: recipientRole,
          title: 'New message from ${message.senderName}',
          body: message.text,
          type: 'chat_message',
          relatedId: message.conversationId,
          createdAt: DateTime.now(),
        ),
      );
      _emitNotifications();
    }
    _emitMessages();
    _emitConversations();
  }

  @override
  Stream<List<AcademicConversation>> watchAcademicConversations(
    String academyId, {
    String? teacherId,
    String? studentId,
  }) async* {
    yield _filterConversations(teacherId: teacherId, studentId: studentId);
    yield* _conversationsCtrl.stream.map((_) =>
        _filterConversations(teacherId: teacherId, studentId: studentId));
  }

  List<AcademicConversation> _filterConversations({
    String? teacherId,
    String? studentId,
  }) {
    return _conversations.where((c) {
      if (teacherId != null &&
          teacherId.isNotEmpty &&
          c.teacherId != teacherId &&
          c.teacherStaffId != teacherId) {
        return false;
      }
      if (studentId != null &&
          studentId.isNotEmpty &&
          c.studentId != studentId &&
          c.studentRollNumber != studentId) {
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
    final convId = 'conv_${teacherId}_$studentId';
    final existing = _conversations.where((c) => c.id == convId).firstOrNull;
    if (existing != null) return existing;
    final conv = AcademicConversation(
      id: convId,
      academyId: academyId,
      teacherId: teacherId,
      teacherName: teacherName,
      teacherStaffId: teacherStaffId,
      studentId: studentId,
      studentName: studentName,
      studentRollNumber: studentRollNumber,
      courseId: courseId,
      courseName: courseName,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      lastSenderRole: 'teacher',
      lastSenderId: teacherId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _conversations.insert(0, conv);
    _emitConversations();
    return conv;
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

    test('StudentInquiry handles ISO strings, DateTimes, and raw data gracefully', () {
      final jsonMap = {
        'id': 'inq_dyn',
        'academyId': testAcademyId,
        'courseId': 'crs_1',
        'courseName': 'Physics',
        'studentId': 's_1',
        'studentName': 'Ali',
        'studentRollNumber': '101',
        'teacherId': 't_1',
        'teacherName': 'Dr. Tariq',
        'subject': 'Quantum physics',
        'question': 'Wave particle duality',
        'createdAt': '2026-11-01T15:30:00.000Z',
        'answeredAt': '2026-11-01T16:00:00.000Z',
      };
      final inquiry = StudentInquiry.fromJson(jsonMap);
      expect(inquiry.createdAt.year, 2026);
      expect(inquiry.answeredAt?.year, 2026);
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

      // Filter by 'Direct Chats'
      await tester.tap(find.textContaining('Direct Chats'));
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
        'Student initiates direct 1-to-1 chat with teacher without asking for topic/description',
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
                  onPressed: () => showStudentInitiateChatModal(
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

      expect(find.text('Message Instructor'), findsOneWidget);
      expect(find.text('Prof. Tariq'), findsOneWidget);
      expect(find.text('Advanced Mathematics'), findsOneWidget);

      // Student taps instructor -> directly opens AcademicChatScreen without any topic/description forms
      await tester.tap(find.text('Prof. Tariq'));
      await tester.pumpAndSettle();

      expect(find.byType(AcademicChatScreen), findsOneWidget);
      expect(find.text('Prof. Tariq'), findsWidgets);

      // Type and send message inside AcademicChatScreen input bar
      final chatInput = find.byType(TextField).last;
      await tester.enterText(
          chatInput, 'Hello Professor! When is our next tutorial?');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify message saved in repository
      final messages = await repo
          .watchChatMessages(testAcademyId, 'conv_staff_t1_stu_1')
          .first;
      expect(messages.length, 1);
      expect(messages.first.text, 'Hello Professor! When is our next tutorial?');
      expect(messages.first.senderRole, 'student');

      repo.dispose();
    });

    testWidgets(
        'StudentInquiriesScreen displays unified 1-to-1 conversations list and opens chat',
        (tester) async {
      final repo = _FakeCommunicationRepo(
        conversations: [
          AcademicConversation(
            id: 'conv_staff_t1_stu_1',
            academyId: testAcademyId,
            teacherId: 'staff_t1',
            teacherName: 'Prof. Tariq',
            teacherStaffId: 'T-1001',
            studentId: 'stu_1',
            studentName: 'Hamza Khan',
            studentRollNumber: '100001',
            courseId: 'crs_math_10',
            courseName: 'Advanced Mathematics',
            lastMessage: 'Class will start at 10:00 AM tomorrow.',
            lastMessageAt: DateTime.now(),
            lastSenderRole: 'teacher',
            lastSenderId: 'staff_t1',
            unreadCountForTeacher: 0,
            unreadCountForStudent: 1,
            status: 'active',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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

      expect(find.text('Student Messages'), findsOneWidget);
      expect(find.text('Hamza Khan'), findsOneWidget);
      expect(find.textContaining('Roll #100001'), findsOneWidget);
      expect(find.text('Class will start at 10:00 AM tomorrow.'), findsOneWidget);

      // Teacher taps conversation card to open AcademicChatScreen
      await tester.tap(find.text('Hamza Khan'));
      await tester.pumpAndSettle();

      expect(find.byType(AcademicChatScreen), findsOneWidget);
      expect(find.text('Hamza Khan'), findsWidgets);

      repo.dispose();
    });

    testWidgets(
        'End-to-End 1-to-1 conversation lifecycle: Teacher initiates -> Student replies in real time',
        (tester) async {
      final repo = _FakeCommunicationRepo();
      final studentAuthRepo = _FakeAuthRepo(studentUser);
      final teacherAuthRepo = _FakeAuthRepo(teacherUser);

      // 1. Teacher initiates chat with student via fast student picker
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('teacher_initiate_scope'),
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(teacherAuthRepo),
            currentStaffMemberProvider.overrideWithValue(sampleTeacher),
            staffBranchStudentsProvider.overrideWithValue([sampleStudent]),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showTeacherInitiateChatModal(
                    context,
                    academyId: testAcademyId,
                  ),
                  child: const Text('Start Student Chat'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start Student Chat'));
      await tester.pumpAndSettle();

      expect(find.text('Start Direct Chat'), findsOneWidget);
      expect(find.text('Hamza Khan'), findsOneWidget);

      // Tap student row -> immediately opens AcademicChatScreen
      await tester.tap(find.text('Hamza Khan'));
      await tester.pumpAndSettle();

      expect(find.byType(AcademicChatScreen), findsOneWidget);

      // Teacher sends initial message
      final teacherMsgInput = find.byType(TextField).last;
      await tester.enterText(
          teacherMsgInput, 'Please submit assignment 3 by Friday.');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify notification delivered to student (Anti-echo: teacher does NOT receive it)
      var notifs = await repo
          .watchNotifications(
            testAcademyId,
            recipientId: 'stu_1',
            recipientRole: 'student',
          )
          .first;
      expect(notifs.length, 1);
      expect(notifs.first.type, 'chat_message');
      expect(notifs.first.body, 'Please submit assignment 3 by Friday.');

      // 2. Student opens AcademicChatScreen and replies
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('student_chat_scope'),
          overrides: [
            communicationRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(studentAuthRepo),
            currentStudentProfileProvider.overrideWithValue(sampleStudent),
          ],
          child: const MaterialApp(
            home: AcademicChatScreen(
              academyId: testAcademyId,
              conversationId: 'conv_staff_t1_stu_1',
              otherPartyName: 'Prof. Tariq',
              otherPartySubtitle: 'Advanced Mathematics',
              otherPartyRole: 'teacher',
              recipientId: 'staff_t1',
              recipientRole: 'staff',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Please submit assignment 3 by Friday.'), findsOneWidget);

      // Student replies
      final studentMsgInput = find.byType(TextField).last;
      await tester.enterText(
          studentMsgInput, 'Noted, thank you Sir! Will submit on time.');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify conversation has both messages
      final chatMessages = await repo
          .watchChatMessages(testAcademyId, 'conv_staff_t1_stu_1')
          .first;
      expect(chatMessages.length, 2);
      expect(chatMessages.first.text, 'Please submit assignment 3 by Friday.');
      expect(chatMessages.last.text,
          'Noted, thank you Sir! Will submit on time.');

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

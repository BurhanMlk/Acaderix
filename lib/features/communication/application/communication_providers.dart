import 'package:academy_management/core/network/firebase_services.dart';
import 'package:academy_management/features/auth/application/auth_controller.dart';
import 'package:academy_management/features/auth/domain/auth_state.dart';
import 'package:academy_management/features/staff/application/staff_providers.dart';
import 'package:academy_management/features/student/application/student_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_communication_repository.dart';
import '../domain/announcement.dart';
import '../domain/app_notification.dart';
import '../domain/communication_repository.dart';
import '../domain/inquiry.dart';

/// Provider for the [CommunicationRepository].
final communicationRepositoryProvider = Provider<CommunicationRepository>((ref) {
  return FirestoreCommunicationRepository(ref.watch(firestoreProvider));
});

/// Streams announcements for a specific academy with optional audience and branch filters.
final announcementsStreamProvider = StreamProvider.family<
    List<Announcement>,
    ({String academyId, String? audience, String? branchId})>(
  (ref, params) {
    if (params.academyId.isEmpty) return const Stream.empty();
    return ref.watch(communicationRepositoryProvider).watchAnnouncements(
          params.academyId,
          audience: params.audience,
          branchId: params.branchId,
        );
  },
);

/// Streams announcements tailored for the currently logged in student.
final studentAnnouncementsProvider =
    StreamProvider.family<List<Announcement>, String>((ref, academyId) {
  if (academyId.isEmpty) return const Stream.empty();
  final student = ref.watch(currentStudentProfileProvider);
  return ref.watch(communicationRepositoryProvider).watchAnnouncements(
        academyId,
        audience: 'students',
        branchId: student?.branchId,
      );
});

/// Streams announcements tailored for the currently logged in staff member.
final staffAnnouncementsProvider =
    StreamProvider.family<List<Announcement>, String>((ref, academyId) {
  if (academyId.isEmpty) return const Stream.empty();
  final staff = ref.watch(currentStaffMemberProvider);
  return ref.watch(communicationRepositoryProvider).watchAnnouncements(
        academyId,
        audience: 'staff',
        branchId: staff?.branchId,
      );
});

/// Streams all announcements for the academy admin.
final academyAdminAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return const [];
  final academyId = auth.user.academyId ?? '';
  if (academyId.isEmpty) return const [];

  final asyncList = ref.watch(
    announcementsStreamProvider((
      academyId: academyId,
      audience: null,
      branchId: null,
    )),
  );
  return asyncList.value ?? const [];
});

/// Streams student-submitted inquiries for the current student.
final studentInquiriesProvider = Provider<List<StudentInquiry>>((ref) {
  final student = ref.watch(currentStudentProfileProvider);
  if (student == null || student.academyId.isEmpty) return const [];

  final repo = ref.watch(communicationRepositoryProvider);
  final asyncVal = ref.watch(
    StreamProvider<List<StudentInquiry>>((r) {
      return repo.watchInquiriesForStudent(student.academyId, student.id);
    }),
  );
  return asyncVal.value ?? const [];
});

/// Streams inquiries assigned to the current staff / teacher member.
final teacherInquiriesProvider = Provider<List<StudentInquiry>>((ref) {
  final staff = ref.watch(currentStaffMemberProvider);
  if (staff == null || staff.academyId.isEmpty) return const [];

  final repo = ref.watch(communicationRepositoryProvider);
  final asyncVal = ref.watch(
    StreamProvider<List<StudentInquiry>>((r) {
      return repo.watchInquiriesForTeacher(staff.academyId, staff.id);
    }),
  );
  return asyncVal.value ?? const [];
});

/// Streams all inquiries for the academy admin audit overview.
final academyAdminAllInquiriesProvider = Provider<List<StudentInquiry>>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return const [];
  final academyId = auth.user.academyId ?? '';
  if (academyId.isEmpty) return const [];

  final repo = ref.watch(communicationRepositoryProvider);
  final asyncVal = ref.watch(
    StreamProvider<List<StudentInquiry>>((r) {
      return repo.watchAllInquiries(academyId);
    }),
  );
  return asyncVal.value ?? const [];
});

/// Streams live in-app notifications for the currently authenticated user.
final userNotificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return const Stream.empty();
  final user = auth.user;
  final academyId = user.academyId ?? '';
  if (academyId.isEmpty) return const Stream.empty();

  final roleStr = user.role.name;
  final recipientId = user.rollNumber != null && user.rollNumber!.isNotEmpty
      ? user.rollNumber!
      : user.id;

  return ref.watch(communicationRepositoryProvider).watchNotifications(
        academyId,
        recipientId: recipientId,
        recipientRole: roleStr,
      );
});

/// Provides unread notification count for the active session user.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(userNotificationsStreamProvider);
  final list = notifsAsync.value ?? const [];
  return list.where((n) => !n.isRead).length;
});

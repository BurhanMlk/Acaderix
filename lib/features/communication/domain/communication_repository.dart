import 'announcement.dart';
import 'app_notification.dart';
import 'inquiry.dart';

/// Contract for broadcasts, student-teacher inquiries, and notifications.
abstract interface class CommunicationRepository {
  // Announcements
  Stream<List<Announcement>> watchAnnouncements(
    String academyId, {
    String? audience,
    String? branchId,
  });

  Future<void> sendAnnouncement(Announcement announcement);

  Future<void> deleteAnnouncement(String academyId, String announcementId);

  // Student Inquiries (Q&A)
  Stream<List<StudentInquiry>> watchInquiriesForStudent(
    String academyId,
    String studentId, {
    String? studentRollNumber,
  });

  Stream<List<StudentInquiry>> watchInquiriesForTeacher(
    String academyId,
    String teacherId, {
    String? teacherStaffId,
    String? teacherName,
    List<String>? teacherCourseIds,
  });

  Stream<List<StudentInquiry>> watchAllInquiries(String academyId);

  Future<void> submitInquiry(StudentInquiry inquiry);

  Future<void> answerInquiry({
    required String academyId,
    required String inquiryId,
    required String reply,
    String status = 'answered',
  });

  // Notifications
  Stream<List<AppNotification>> watchNotifications(
    String academyId, {
    required String recipientId,
    required String recipientRole,
  });

  Future<void> sendNotification(AppNotification notification);

  Future<void> markNotificationAsRead(
    String academyId,
    String notificationId,
  );

  Future<void> markAllNotificationsAsRead(
    String academyId,
    String recipientId,
  );
}

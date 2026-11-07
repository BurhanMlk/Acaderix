import 'announcement.dart';
import 'app_notification.dart';
import 'chat_message.dart';
import 'inquiry.dart';

/// Contract for broadcasts, student-teacher inquiries, real-time chat, and notifications.
abstract interface class CommunicationRepository {
  // Real-time WhatsApp-style Two-Way Academic Chat
  Stream<List<ChatMessage>> watchChatMessages(
    String academyId,
    String conversationId,
  );

  Future<void> sendChatMessage(
    ChatMessage message, {
    required String recipientId,
    required String recipientRole,
  });

  Stream<List<AcademicConversation>> watchAcademicConversations(
    String academyId, {
    String? teacherId,
    String? studentId,
  });

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
  });
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
    String? replierRole,
    String? replierId,
  });

  // Notifications
  Stream<List<AppNotification>> watchNotifications(
    String academyId, {
    required String recipientId,
    required String recipientRole,
    List<String>? alternativeRecipientIds,
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

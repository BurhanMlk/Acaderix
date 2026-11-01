import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/announcement.dart';
import '../domain/app_notification.dart';
import '../domain/communication_repository.dart';
import '../domain/inquiry.dart';

/// Firestore implementation of [CommunicationRepository].
final class FirestoreCommunicationRepository
    implements CommunicationRepository {
  FirestoreCommunicationRepository(this._firestore);

  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _announcementsRef(
    String academyId,
  ) =>
      _firestore.collection(FirestorePaths.announcements(academyId));

  CollectionReference<Map<String, dynamic>> _inquiriesRef(String academyId) =>
      _firestore.collection(FirestorePaths.inquiries(academyId));

  CollectionReference<Map<String, dynamic>> _notificationsRef(
    String academyId,
  ) =>
      _firestore.collection(FirestorePaths.notifications(academyId));

  // --- Announcements ---

  @override
  Stream<List<Announcement>> watchAnnouncements(
    String academyId, {
    String? audience,
    String? branchId,
  }) {
    return _announcementsRef(academyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = mapQueryDocs(snapshot, (id, data) {
        return Announcement.fromJson({'id': id, ...data});
      });

      return list.where((a) {
        if (audience != null && audience != 'all') {
          if (a.audience != 'all' && a.audience != audience) return false;
        }
        if (branchId != null &&
            branchId.isNotEmpty &&
            a.branchId.isNotEmpty) {
          if (a.branchId != branchId) return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Future<void> sendAnnouncement(Announcement announcement) async {
    final docId =
        announcement.id.isEmpty ? _uuid.v4() : announcement.id;
    final finalAnnouncement = announcement.copyWith(id: docId);
    final data = toFirestoreData(finalAnnouncement.toJson())..remove('id');

    await _announcementsRef(announcement.academyId)
        .doc(docId)
        .set(data, SetOptions(merge: true));

    // Also dispatch an AppNotification for in-app / push delivery
    final notifId = _uuid.v4();
    final notif = AppNotification(
      id: notifId,
      academyId: announcement.academyId,
      recipientId: 'broadcast',
      recipientRole: announcement.audience,
      title: announcement.isUrgent
          ? 'URGENT: ${announcement.title}'
          : announcement.title,
      body: announcement.content,
      type: 'broadcast',
      relatedId: docId,
      createdAt: DateTime.now(),
    );
    await sendNotification(notif);
  }

  @override
  Future<void> deleteAnnouncement(
    String academyId,
    String announcementId,
  ) {
    return _announcementsRef(academyId).doc(announcementId).delete();
  }

  // --- Student Inquiries (Q&A) ---

  @override
  Stream<List<StudentInquiry>> watchInquiriesForStudent(
    String academyId,
    String studentId,
  ) {
    return _inquiriesRef(academyId)
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => mapQueryDocs(snapshot, (id, data) {
              return StudentInquiry.fromJson({'id': id, ...data});
            }));
  }

  @override
  Stream<List<StudentInquiry>> watchInquiriesForTeacher(
    String academyId,
    String teacherId,
  ) {
    return _inquiriesRef(academyId)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => mapQueryDocs(snapshot, (id, data) {
              return StudentInquiry.fromJson({'id': id, ...data});
            }));
  }

  @override
  Stream<List<StudentInquiry>> watchAllInquiries(String academyId) {
    return _inquiriesRef(academyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => mapQueryDocs(snapshot, (id, data) {
              return StudentInquiry.fromJson({'id': id, ...data});
            }));
  }

  @override
  Future<void> submitInquiry(StudentInquiry inquiry) async {
    final docId = inquiry.id.isEmpty ? _uuid.v4() : inquiry.id;
    final finalInquiry = inquiry.copyWith(id: docId);
    final data = toFirestoreData(finalInquiry.toJson())..remove('id');

    await _inquiriesRef(inquiry.academyId)
        .doc(docId)
        .set(data, SetOptions(merge: true));

    // Dispatch notification to instructor
    final notifId = _uuid.v4();
    final notif = AppNotification(
      id: notifId,
      academyId: inquiry.academyId,
      recipientId: inquiry.teacherId,
      recipientRole: 'staff',
      title: 'New Student Question: ${inquiry.courseName}',
      body: '${inquiry.studentName} asked: "${inquiry.subject}"',
      type: 'inquiry_question',
      relatedId: docId,
      createdAt: DateTime.now(),
    );
    await sendNotification(notif);
  }

  @override
  Future<void> answerInquiry({
    required String academyId,
    required String inquiryId,
    required String reply,
    String status = 'answered',
  }) async {
    final docRef = _inquiriesRef(academyId).doc(inquiryId);
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return;

    final existing =
        StudentInquiry.fromJson({'id': doc.id, ...doc.data()!});

    final now = DateTime.now();
    await docRef.update({
      'reply': reply,
      'status': status,
      'answeredAt': now.toIso8601String(),
    });

    // Dispatch notification to student
    final notifId = _uuid.v4();
    final notif = AppNotification(
      id: notifId,
      academyId: academyId,
      recipientId: existing.studentId,
      recipientRole: 'student',
      title: 'Instructor Answered: ${existing.courseName}',
      body: '${existing.teacherName} replied to: "${existing.subject}"',
      type: 'inquiry_reply',
      relatedId: inquiryId,
      createdAt: now,
    );
    await sendNotification(notif);
  }

  // --- Notifications ---

  @override
  Stream<List<AppNotification>> watchNotifications(
    String academyId, {
    required String recipientId,
    required String recipientRole,
  }) {
    return _notificationsRef(academyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = mapQueryDocs<AppNotification>(snapshot, (id, data) {
        return AppNotification.fromJson(data, id: id);
      });

      return list.where((n) {
        // Direct match to user id or roll number
        if (n.recipientId == recipientId) return true;
        // Broadcast matches role or 'all'
        if (n.recipientId == 'broadcast') {
          return n.recipientRole == 'all' ||
              n.recipientRole == recipientRole;
        }
        return false;
      }).toList();
    });
  }

  @override
  Future<void> sendNotification(AppNotification notification) {
    final docId =
        notification.id.isEmpty ? _uuid.v4() : notification.id;
    final finalNotif = notification.copyWith(id: docId);
    final data = toFirestoreData(finalNotif.toJson())..remove('id');
    return _notificationsRef(notification.academyId)
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<void> markNotificationAsRead(
    String academyId,
    String notificationId,
  ) {
    return _notificationsRef(academyId)
        .doc(notificationId)
        .update({'isRead': true});
  }

  @override
  Future<void> markAllNotificationsAsRead(
    String academyId,
    String recipientId,
  ) async {
    final snapshot = await _notificationsRef(academyId)
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

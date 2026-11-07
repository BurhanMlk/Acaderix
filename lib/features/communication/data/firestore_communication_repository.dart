import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/network/firestore_ext.dart';
import '../domain/announcement.dart';
import '../domain/app_notification.dart';
import '../domain/chat_message.dart';
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

  CollectionReference<Map<String, dynamic>> _conversationsRef(
          String academyId) =>
      _firestore.collection(FirestorePaths.conversations(academyId));

  CollectionReference<Map<String, dynamic>> _messagesRef(
          String academyId, String conversationId) =>
      _firestore.collection(
          FirestorePaths.conversationMessages(academyId, conversationId));

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
    String studentId, {
    String? studentRollNumber,
  }) {
    return _inquiriesRef(academyId).snapshots().map((snapshot) {
      final list = mapQueryDocs(snapshot, (id, data) {
        return StudentInquiry.fromJson({'id': id, ...data});
      });

      final filtered = list.where((inq) {
        if (inq.studentId == studentId) return true;
        if (studentRollNumber != null &&
            studentRollNumber.isNotEmpty &&
            inq.studentRollNumber == studentRollNumber) {
          return true;
        }
        return false;
      }).toList();

      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  @override
  Stream<List<StudentInquiry>> watchInquiriesForTeacher(
    String academyId,
    String teacherId, {
    String? teacherStaffId,
    String? teacherName,
    List<String>? teacherCourseIds,
  }) {
    return _inquiriesRef(academyId).snapshots().map((snapshot) {
      final list = mapQueryDocs(snapshot, (id, data) {
        return StudentInquiry.fromJson({'id': id, ...data});
      });

      final filtered = list.where((inq) {
        if (inq.teacherId == teacherId) return true;
        if (teacherStaffId != null &&
            teacherStaffId.isNotEmpty &&
            inq.teacherId.toLowerCase() == teacherStaffId.toLowerCase()) {
          return true;
        }
        if (teacherName != null &&
            teacherName.isNotEmpty &&
            inq.teacherName.toLowerCase() == teacherName.toLowerCase()) {
          return true;
        }
        if (teacherCourseIds != null &&
            teacherCourseIds.contains(inq.courseId)) {
          return true;
        }
        return false;
      }).toList();

      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  @override
  Stream<List<StudentInquiry>> watchAllInquiries(String academyId) {
    return _inquiriesRef(academyId).snapshots().map((snapshot) {
      final list = mapQueryDocs(snapshot, (id, data) {
        return StudentInquiry.fromJson({'id': id, ...data});
      });
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> submitInquiry(StudentInquiry inquiry) async {
    final docId = inquiry.id.isEmpty ? _uuid.v4() : inquiry.id;
    final finalInquiry = inquiry.copyWith(id: docId);
    final data = toFirestoreData(finalInquiry.toJson())..remove('id');

    await _inquiriesRef(inquiry.academyId)
        .doc(docId)
        .set(data, SetOptions(merge: true));

    // Determine notification directionality
    final isTeacherSender = inquiry.isSentByTeacher;
    final String recipientId;
    final String recipientRole;
    final String notifTitle;
    final String notifBody;
    final String notifType;

    if (isTeacherSender) {
      recipientId = inquiry.studentId;
      recipientRole = 'student';
      notifTitle = 'Message from ${inquiry.teacherName}';
      notifBody = inquiry.subject.isNotEmpty
          ? '${inquiry.subject}: ${inquiry.question}'
          : inquiry.question;
      notifType = 'teacher_message';
    } else {
      recipientId = inquiry.teacherId;
      recipientRole = 'staff';
      notifTitle = 'New Student Question: ${inquiry.courseName}';
      notifBody = '${inquiry.studentName} asked: "${inquiry.subject}"';
      notifType = 'inquiry_question';
    }

    // STRICT INVARIANT: Sender must NEVER be the recipient!
    final actualSenderId = inquiry.senderId ??
        (isTeacherSender ? inquiry.teacherId : inquiry.studentId);
    if (recipientId.isNotEmpty && recipientId != actualSenderId) {
      final notifId = _uuid.v4();
      final notif = AppNotification(
        id: notifId,
        academyId: inquiry.academyId,
        recipientId: recipientId,
        recipientRole: recipientRole,
        title: notifTitle,
        body: notifBody,
        type: notifType,
        relatedId: docId,
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
    final docRef = _inquiriesRef(academyId).doc(inquiryId);
    final doc = await docRef.get();
    if (!doc.exists || doc.data() == null) return;

    final existing = StudentInquiry.fromJson(
      {'id': doc.id, ...fromFirestoreData(doc.data()!)},
    );

    final now = DateTime.now();
    await docRef.update({
      'reply': reply,
      'status': status,
      'answeredAt': now.toIso8601String(),
    });

    // Determine who replied: if student replied or teacher replied
    final isStudentReplier = replierRole == 'student' ||
        (replierId != null &&
            (replierId == existing.studentId ||
                replierId == existing.studentRollNumber));

    final String recipientId;
    final String recipientRole;
    final String notifTitle;
    final String notifBody;

    if (isStudentReplier) {
      recipientId = existing.teacherId;
      recipientRole = 'staff';
      notifTitle = 'Student Replied: ${existing.courseName}';
      notifBody = '${existing.studentName} replied to: "${existing.subject}"';
    } else {
      recipientId = existing.studentId;
      recipientRole = 'student';
      notifTitle = 'Instructor Answered: ${existing.courseName}';
      notifBody = '${existing.teacherName} replied to: "${existing.subject}"';
    }

    // STRICT INVARIANT: Replier must NEVER be recipient!
    final actualReplierId = replierId ??
        (isStudentReplier ? existing.studentId : existing.teacherId);
    if (recipientId.isNotEmpty && recipientId != actualReplierId) {
      final notifId = _uuid.v4();
      final notif = AppNotification(
        id: notifId,
        academyId: academyId,
        recipientId: recipientId,
        recipientRole: recipientRole,
        title: notifTitle,
        body: notifBody,
        type: 'inquiry_reply',
        relatedId: inquiryId,
        createdAt: now,
      );
      await sendNotification(notif);
    }
  }

  // --- Notifications ---

  @override
  Stream<List<AppNotification>> watchNotifications(
    String academyId, {
    required String recipientId,
    required String recipientRole,
    List<String>? alternativeRecipientIds,
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
        if (alternativeRecipientIds != null &&
            alternativeRecipientIds.contains(n.recipientId)) {
          return true;
        }
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

  // --- Real-time WhatsApp-style Two-Way Academic Chat ---

  @override
  Stream<List<ChatMessage>> watchChatMessages(
    String academyId,
    String conversationId,
  ) {
    return _messagesRef(academyId, conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return mapQueryDocs(snapshot, (id, data) {
        return ChatMessage.fromJson(data, id: id);
      });
    });
  }

  @override
  Future<void> sendChatMessage(
    ChatMessage message, {
    required String recipientId,
    required String recipientRole,
  }) async {
    final docId = message.id.isEmpty ? _uuid.v4() : message.id;
    final finalMsg = message.copyWith(id: docId);
    final data = toFirestoreData(finalMsg.toJson())..remove('id');

    // 1. Write message to messages subcollection
    await _messagesRef(message.academyId, message.conversationId)
        .doc(docId)
        .set(data, SetOptions(merge: true));

    // 2. Atomically update parent conversation header
    final isTeacher = message.isFromTeacher;
    final convRef =
        _conversationsRef(message.academyId).doc(message.conversationId);
    await convRef.set({
      'lastMessage': message.text,
      'lastMessageAt': message.createdAt.toIso8601String(),
      'lastSenderRole': message.senderRole,
      'lastSenderId': message.senderId,
      'updatedAt': DateTime.now().toIso8601String(),
      if (isTeacher)
        'unreadCountForStudent': FieldValue.increment(1)
      else
        'unreadCountForTeacher': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // 3. Dispatch push notification to recipient (Anti-echo invariant: NEVER to sender!)
    if (recipientId.isNotEmpty && recipientId != message.senderId) {
      final notifId = _uuid.v4();
      final notif = AppNotification(
        id: notifId,
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
  }) {
    return _conversationsRef(academyId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = mapQueryDocs(snapshot, (id, data) {
        return AcademicConversation.fromJson(data, id: id);
      });
      return list.where((c) {
        if (teacherId != null && teacherId.isNotEmpty) {
          final t = teacherId.trim().toLowerCase();
          final matchesId = c.teacherId.toLowerCase() == t;
          final matchesStaffId = c.teacherStaffId.toLowerCase() == t;
          final matchesName = c.teacherName.toLowerCase() == t;
          if (!matchesId && !matchesStaffId && !matchesName) {
            return false;
          }
        }
        if (studentId != null && studentId.isNotEmpty) {
          final s = studentId.trim().toLowerCase();
          final matchesId = c.studentId.toLowerCase() == s;
          final matchesRoll = c.studentRollNumber.toLowerCase() == s;
          final matchesName = c.studentName.toLowerCase() == s;
          if (!matchesId && !matchesRoll && !matchesName) {
            return false;
          }
        }
        return true;
      }).toList();
    });
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
    // Generate deterministic conversation key based on teacher and student
    final rawKey = 'conv_${teacherId}_$studentId';
    final convId = rawKey.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final docRef = _conversationsRef(academyId).doc(convId);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      return AcademicConversation.fromJson(doc.data()!, id: doc.id);
    }

    final now = DateTime.now();
    final newConv = AcademicConversation(
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
      lastMessage: 'Conversation opened',
      lastMessageAt: now,
      lastSenderRole: 'teacher',
      lastSenderId: teacherId,
      createdAt: now,
      updatedAt: now,
    );

    final data = toFirestoreData(newConv.toJson())..remove('id');
    await docRef.set(data, SetOptions(merge: true));
    return newConv;
  }
}

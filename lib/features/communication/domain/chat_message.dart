/// Represents a single real-time text message within a two-way academic conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.academyId,
    required this.senderId,
    required this.senderName,
    required this.senderRole, // 'teacher' | 'student' | 'staff' | 'admin'
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String conversationId;
  final String academyId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  bool get isFromTeacher => senderRole == 'teacher' || senderRole == 'staff';
  bool get isFromStudent => senderRole == 'student';

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? academyId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      academyId: academyId ?? this.academyId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'academyId': academyId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? id}) {
    return ChatMessage(
      id: id ?? json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'User',
      senderRole: json['senderRole'] as String? ?? 'student',
      text: json['text'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic dyn = value;
      if (dyn.toDate != null) return dyn.toDate() as DateTime;
    } catch (_) {}
    return null;
  }
}

/// Represents an ongoing two-way conversation thread between a teacher and student.
class AcademicConversation {
  const AcademicConversation({
    required this.id,
    required this.academyId,
    required this.teacherId,
    required this.teacherName,
    this.teacherStaffId = '',
    required this.studentId,
    required this.studentName,
    required this.studentRollNumber,
    this.courseId = '',
    this.courseName = 'Academic Guidance',
    this.lastMessage = '',
    required this.lastMessageAt,
    this.lastSenderRole = 'student',
    this.lastSenderId = '',
    this.unreadCountForTeacher = 0,
    this.unreadCountForStudent = 0,
    this.status = 'active', // 'active' | 'resolved'
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String academyId;
  final String teacherId;
  final String teacherName;
  final String teacherStaffId;
  final String studentId;
  final String studentName;
  final String studentRollNumber;
  final String courseId;
  final String courseName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderRole;
  final String lastSenderId;
  final int unreadCountForTeacher;
  final int unreadCountForStudent;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';

  AcademicConversation copyWith({
    String? id,
    String? academyId,
    String? teacherId,
    String? teacherName,
    String? teacherStaffId,
    String? studentId,
    String? studentName,
    String? studentRollNumber,
    String? courseId,
    String? courseName,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderRole,
    String? lastSenderId,
    int? unreadCountForTeacher,
    int? unreadCountForStudent,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcademicConversation(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      teacherStaffId: teacherStaffId ?? this.teacherStaffId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRollNumber: studentRollNumber ?? this.studentRollNumber,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderRole: lastSenderRole ?? this.lastSenderRole,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      unreadCountForTeacher:
          unreadCountForTeacher ?? this.unreadCountForTeacher,
      unreadCountForStudent:
          unreadCountForStudent ?? this.unreadCountForStudent,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academyId': academyId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherStaffId': teacherStaffId,
      'studentId': studentId,
      'studentName': studentName,
      'studentRollNumber': studentRollNumber,
      'courseId': courseId,
      'courseName': courseName,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'lastSenderRole': lastSenderRole,
      'lastSenderId': lastSenderId,
      'unreadCountForTeacher': unreadCountForTeacher,
      'unreadCountForStudent': unreadCountForStudent,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AcademicConversation.fromJson(Map<String, dynamic> json,
      {String? id}) {
    return AcademicConversation(
      id: id ?? json['id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      teacherStaffId: json['teacherStaffId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      studentRollNumber: json['studentRollNumber'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseName: json['courseName'] as String? ?? 'Academic Guidance',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt:
          _parseDateTime(json['lastMessageAt']) ?? DateTime.now(),
      lastSenderRole: json['lastSenderRole'] as String? ?? 'student',
      lastSenderId: json['lastSenderId'] as String? ?? '',
      unreadCountForTeacher: json['unreadCountForTeacher'] as int? ?? 0,
      unreadCountForStudent: json['unreadCountForStudent'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic dyn = value;
      if (dyn.toDate != null) return dyn.toDate() as DateTime;
    } catch (_) {}
    return null;
  }
}

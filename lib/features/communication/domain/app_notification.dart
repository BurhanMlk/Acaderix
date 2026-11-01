/// A notification delivered in-app and via push messaging to a user or group.
class AppNotification {
  AppNotification({
    required this.id,
    required this.academyId,
    this.recipientId = 'broadcast', // user ID, roll number, or 'broadcast'
    this.recipientRole = 'all', // 'all', 'staff', 'student', 'academyAdmin'
    required this.title,
    required this.body,
    this.type = 'broadcast', // 'broadcast', 'inquiry_question', 'inquiry_reply', 'exam_result', 'fee_alert'
    this.relatedId = '',
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String academyId;
  final String recipientId;
  final String recipientRole;
  final String title;
  final String body;
  final String type;
  final String relatedId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({
    String? id,
    String? academyId,
    String? recipientId,
    String? recipientRole,
    String? title,
    String? body,
    String? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'academyId': academyId,
      'recipientId': recipientId,
      'recipientRole': recipientRole,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    String? id,
  }) {
    return AppNotification(
      id: id ?? json['id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? 'broadcast',
      recipientRole: json['recipientRole'] as String? ?? 'all',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'broadcast',
      relatedId: json['relatedId'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

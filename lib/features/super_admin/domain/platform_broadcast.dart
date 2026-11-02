import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a platform-wide broadcast issued by the Super Admin to all academies.
class PlatformBroadcast {
  PlatformBroadcast({
    required this.id,
    required this.title,
    required this.message,
    this.category = 'system', // 'system', 'maintenance', 'billing', 'feature', 'general'
    this.priority = 'normal', // 'normal', 'high', 'urgent'
    this.targetAudience = 'all', // 'all', 'active', 'past_due', 'trial'
    DateTime? createdAt,
    this.expiresAt,
    this.isActive = true,
    this.authorEmail = 'admin@acadrix.com',
    this.sentPushNotification = false,
    this.deliveryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String message;
  final String category;
  final String priority;
  final String targetAudience;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String authorEmail;
  final bool sentPushNotification;
  final int deliveryCount;

  bool get isUrgent => priority.toLowerCase() == 'urgent';
  bool get isHighPriority => priority.toLowerCase() == 'high';

  String get audienceLabel => switch (targetAudience) {
        'active' => 'Active Subscribers',
        'past_due' => 'Past Due / Unpaid',
        'trial' => 'Trial Academies',
        _ => 'All Academies',
      };

  String get categoryLabel => switch (category.toLowerCase()) {
        'maintenance' => 'Maintenance Notice',
        'billing' => 'Billing & Invoicing',
        'feature' => 'Feature Release',
        'general' => 'Announcement',
        _ => 'System Notice',
      };

  PlatformBroadcast copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    String? priority,
    String? targetAudience,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    String? authorEmail,
    bool? sentPushNotification,
    int? deliveryCount,
  }) {
    return PlatformBroadcast(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      authorEmail: authorEmail ?? this.authorEmail,
      sentPushNotification:
          sentPushNotification ?? this.sentPushNotification,
      deliveryCount: deliveryCount ?? this.deliveryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'priority': priority,
      'targetAudience': targetAudience,
      'createdAt': Timestamp.fromDate(createdAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'isActive': isActive,
      'authorEmail': authorEmail,
      'sentPushNotification': sentPushNotification,
      'deliveryCount': deliveryCount,
    };
  }

  factory PlatformBroadcast.fromJson(Map<String, dynamic> json, String docId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return PlatformBroadcast(
      id: json['id'] as String? ?? docId,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? 'system',
      priority: json['priority'] as String? ?? 'normal',
      targetAudience: json['targetAudience'] as String? ?? 'all',
      createdAt: parseDate(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? parseDate(json['expiresAt']) : null,
      isActive: json['isActive'] as bool? ?? true,
      authorEmail: json['authorEmail'] as String? ?? 'admin@acadrix.com',
      sentPushNotification: json['sentPushNotification'] as bool? ?? false,
      deliveryCount: (json['deliveryCount'] as num?)?.toInt() ?? 0,
    );
  }
}

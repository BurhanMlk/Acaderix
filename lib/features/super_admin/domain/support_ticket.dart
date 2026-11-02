import 'package:cloud_firestore/cloud_firestore.dart';

/// A conversation entry in a support ticket.
class SupportTicketMessage {
  SupportTicketMessage({
    required this.id,
    required this.senderName,
    required this.senderRole, // 'superAdmin', 'academyAdmin', 'system'
    required this.message,
    DateTime? createdAt,
    this.isStaffReply = false,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime createdAt;
  final bool isStaffReply;

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'senderRole': senderRole,
        'message': message,
        'createdAt': Timestamp.fromDate(createdAt),
        'isStaffReply': isStaffReply,
      };

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return SupportTicketMessage(
      id: json['id'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Support Agent',
      senderRole: json['senderRole'] as String? ?? 'superAdmin',
      message: json['message'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      isStaffReply: json['isStaffReply'] as bool? ?? false,
    );
  }
}

/// A support ticket opened by or on behalf of an academy.
class SupportTicket {
  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.academyId,
    required this.academyName,
    required this.academyCode,
    required this.contactName,
    required this.contactEmail,
    this.contactPhone = '',
    required this.subject,
    required this.description,
    this.category = 'technical', // 'billing', 'technical', 'account', 'feature_request'
    this.priority = 'medium', // 'urgent', 'high', 'medium', 'low'
    this.status = 'open', // 'open', 'in_progress', 'resolved', 'closed'
    DateTime? createdAt,
    DateTime? updatedAt,
    this.resolutionNote,
    List<SupportTicketMessage>? messages,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        messages = messages ?? [];

  final String id;
  final String ticketNumber;
  final String academyId;
  final String academyName;
  final String academyCode;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? resolutionNote;
  final List<SupportTicketMessage> messages;

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';

  String get categoryLabel => switch (category.toLowerCase()) {
        'billing' => 'Billing & Payment',
        'account' => 'Account & Access',
        'feature_request' => 'Feature Request',
        _ => 'Technical Support',
      };

  String get statusLabel => switch (status.toLowerCase()) {
        'in_progress' => 'In Progress',
        'resolved' => 'Resolved',
        'closed' => 'Closed',
        _ => 'Open',
      };

  String get priorityLabel => switch (priority.toLowerCase()) {
        'urgent' => 'Urgent',
        'high' => 'High',
        'low' => 'Low',
        _ => 'Medium',
      };

  SupportTicket copyWith({
    String? id,
    String? ticketNumber,
    String? academyId,
    String? academyName,
    String? academyCode,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? subject,
    String? description,
    String? category,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? resolutionNote,
    List<SupportTicketMessage>? messages,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      academyId: academyId ?? this.academyId,
      academyName: academyName ?? this.academyName,
      academyCode: academyCode ?? this.academyCode,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'academyId': academyId,
      'academyName': academyName,
      'academyCode': academyCode,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json, String docId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final parsedMessages = rawMessages
        .map((m) => SupportTicketMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return SupportTicket(
      id: json['id'] as String? ?? docId,
      ticketNumber: json['ticketNumber'] as String? ?? 'TICK-1001',
      academyId: json['academyId'] as String? ?? '',
      academyName: json['academyName'] as String? ?? '',
      academyCode: json['academyCode'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'technical',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      resolutionNote: json['resolutionNote'] as String?,
      messages: parsedMessages,
    );
  }
}

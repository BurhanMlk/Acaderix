/// Represents a broadcast message cast or institutional announcement.
class Announcement {
  Announcement({
    required this.id,
    required this.academyId,
    required this.title,
    required this.content,
    this.audience = 'all', // 'all', 'staff', 'students'
    this.priority = 'normal', // 'normal', 'urgent', 'notice'
    this.category = 'General', // 'General', 'Exam Alert', 'Holiday', 'Fee Notice', 'Event', 'Emergency'
    this.branchId = '',
    this.courseId = '',
    this.courseName = '',
    this.authorId = '',
    this.authorName = 'Academy Administration',
    this.authorRole = 'academyAdmin',
    DateTime? createdAt,
    this.isPinned = false,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String academyId;
  final String title;
  final String content;
  final String audience;
  final String priority;
  final String category;
  final String branchId;
  final String courseId;
  final String courseName;
  final String authorId;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;
  final bool isPinned;

  bool get isUrgent => priority.toLowerCase() == 'urgent';

  bool appliesToStaff() => audience == 'all' || audience == 'staff';

  bool appliesToStudents() => audience == 'all' || audience == 'students';

  Announcement copyWith({
    String? id,
    String? academyId,
    String? title,
    String? content,
    String? audience,
    String? priority,
    String? category,
    String? branchId,
    String? courseId,
    String? courseName,
    String? authorId,
    String? authorName,
    String? authorRole,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return Announcement(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      title: title ?? this.title,
      content: content ?? this.content,
      audience: audience ?? this.audience,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      branchId: branchId ?? this.branchId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academyId': academyId,
      'title': title,
      'content': content,
      'audience': audience,
      'priority': priority,
      'category': category,
      'branchId': branchId,
      'courseId': courseId,
      'courseName': courseName,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      audience: json['audience'] as String? ?? 'all',
      priority: json['priority'] as String? ?? 'normal',
      category: json['category'] as String? ?? 'General',
      branchId: json['branchId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Academy Administration',
      authorRole: json['authorRole'] as String? ?? 'academyAdmin',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }
}

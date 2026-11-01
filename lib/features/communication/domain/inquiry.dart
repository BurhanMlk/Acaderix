/// A student-to-teacher academic inquiry/question and answer thread.
class StudentInquiry {
  const StudentInquiry({
    required this.id,
    required this.academyId,
    required this.courseId,
    required this.courseName,
    required this.studentId,
    required this.studentName,
    required this.studentRollNumber,
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.question,
    this.reply = '',
    this.status = 'open', // 'open', 'answered', 'resolved'
    required this.createdAt,
    this.answeredAt,
  });

  final String id;
  final String academyId;
  final String courseId;
  final String courseName;
  final String studentId;
  final String studentName;
  final String studentRollNumber;
  final String teacherId;
  final String teacherName;
  final String subject;
  final String question;
  final String reply;
  final String status;
  final DateTime createdAt;
  final DateTime? answeredAt;

  bool get isOpen => status == 'open';
  bool get isAnswered => status == 'answered';
  bool get isResolved => status == 'resolved';

  StudentInquiry copyWith({
    String? id,
    String? academyId,
    String? courseId,
    String? courseName,
    String? studentId,
    String? studentName,
    String? studentRollNumber,
    String? teacherId,
    String? teacherName,
    String? subject,
    String? question,
    String? reply,
    String? status,
    DateTime? createdAt,
    DateTime? answeredAt,
  }) {
    return StudentInquiry(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRollNumber: studentRollNumber ?? this.studentRollNumber,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      subject: subject ?? this.subject,
      question: question ?? this.question,
      reply: reply ?? this.reply,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academyId': academyId,
      'courseId': courseId,
      'courseName': courseName,
      'studentId': studentId,
      'studentName': studentName,
      'studentRollNumber': studentRollNumber,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subject': subject,
      'question': question,
      'reply': reply,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'answeredAt': answeredAt?.toIso8601String(),
    };
  }

  factory StudentInquiry.fromJson(Map<String, dynamic> json) {
    return StudentInquiry(
      id: json['id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      studentRollNumber: json['studentRollNumber'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      question: json['question'] as String? ?? '',
      reply: json['reply'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      answeredAt: _parseDateTime(json['answeredAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Support Cloud Firestore Timestamp dynamically without hard import
    try {
      final dynamic dyn = value;
      if (dyn.toDate != null) return dyn.toDate() as DateTime;
    } catch (_) {}
    return null;
  }
}

/// Alias for [StudentInquiry]
typedef Inquiry = StudentInquiry;

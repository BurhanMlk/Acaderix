/// Centralized Firestore collection/document paths.
///
/// Every academy-scoped path derives from `academies/{academyId}` so tenant
/// isolation is expressed consistently in code and mirrored in security rules.
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String academyCodes = 'academy_codes';
  static const String academies = 'academies';
  static const String subscriptionPlans = 'subscription_plans';
  static const String subscriptions = 'subscriptions';
  static const String subscriptionPayments = 'subscription_payments';
  static const String supportTickets = 'support_tickets';
  static const String broadcasts = 'broadcasts';
  static const String platformSettings = 'platform_settings';

  static String academy(String academyId) => '$academies/$academyId';

  static String branches(String academyId) => '${academy(academyId)}/branches';
  static String staff(String academyId) => '${academy(academyId)}/staff';
  static String students(String academyId) => '${academy(academyId)}/students';
  static String guardians(String academyId) =>
      '${academy(academyId)}/guardians';
  static String classes(String academyId) => '${academy(academyId)}/classes';
  static String courses(String academyId) => '${academy(academyId)}/courses';
  static String subjects(String academyId) => '${academy(academyId)}/subjects';
  static String batches(String academyId) => '${academy(academyId)}/batches';
  static String enrollments(String academyId) =>
      '${academy(academyId)}/enrollments';
  static String attendance(String academyId) =>
      '${academy(academyId)}/attendance';
  static String staffAttendance(String academyId) =>
      '${academy(academyId)}/staff_attendance';
  static String feeStructures(String academyId) =>
      '${academy(academyId)}/fee_structures';
  static String feeInvoices(String academyId) =>
      '${academy(academyId)}/fee_invoices';
  static String feePayments(String academyId) =>
      '${academy(academyId)}/fee_payments';
  static String exams(String academyId) => '${academy(academyId)}/exams';
  static String results(String academyId) => '${academy(academyId)}/results';
  static String homework(String academyId) => '${academy(academyId)}/homework';
  static String timetables(String academyId) =>
      '${academy(academyId)}/timetables';
  static String salaries(String academyId) => '${academy(academyId)}/salaries';
  static String expenses(String academyId) => '${academy(academyId)}/expenses';
  static String announcements(String academyId) =>
      '${academy(academyId)}/announcements';
  static String inquiries(String academyId) =>
      '${academy(academyId)}/inquiries';
  static String notifications(String academyId) =>
      '${academy(academyId)}/notifications';
  static String auditLogs(String academyId) =>
      '${academy(academyId)}/audit_logs';
  static String counters(String academyId) => '${academy(academyId)}/counters';
}

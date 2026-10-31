import '../../../core/constants/app_constants.dart';

/// States that govern an academy admin's access to their academy.
enum AcademyAccessState {
  active,
  pending,
  suspended,
  expired, // or subscription payment overdue
  notFound,
}

/// Comprehensive information regarding an academy's account and subscription status.
class AcademyAccessInfo {
  const AcademyAccessInfo({
    required this.state,
    required this.academyId,
    this.academyName = '',
    this.academyCode = '',
    this.rawStatus = 'pending',
    this.renewalDate,
    this.paymentStatus = 'paid',
    this.planName = 'Standard',
    this.supportPhone = AppConstants.superAdminSupportPhone,
    this.supportEmail = AppConstants.superAdminSupportEmail,
    this.statusReason = '',
  });

  final AcademyAccessState state;
  final String academyId;
  final String academyName;
  final String academyCode;
  final String rawStatus; // 'active', 'suspended', 'pending'
  final DateTime? renewalDate;
  final String paymentStatus; // 'paid', 'unpaid', 'overdue'
  final String planName;
  final String supportPhone;
  final String supportEmail;
  final String statusReason;

  bool get isActive => state == AcademyAccessState.active;
  bool get isSuspended => state == AcademyAccessState.suspended;
  bool get isPending => state == AcademyAccessState.pending;
  bool get isExpired => state == AcademyAccessState.expired;
  bool get isNotFound => state == AcademyAccessState.notFound;

  int? get daysRemaining {
    if (renewalDate == null) return null;
    final now = DateTime.now();
    return renewalDate!
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }
}

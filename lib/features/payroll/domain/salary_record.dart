import 'package:cloud_firestore/cloud_firestore.dart';

/// A monthly salary / payroll record for a staff member.
class SalaryRecord {
  const SalaryRecord({
    required this.id,
    required this.academyId,
    required this.staffId,
    this.staffCode = '',
    this.staffName = '',
    this.jobTitle = '',
    this.branchId = '',
    required this.monthKey,
    required this.monthLabel,
    this.baseSalary = 0,
    this.bonus = 0,
    this.deductions = 0,
    this.status = 'pending',
    this.paymentMethod = 'bank_transfer',
    this.notes = '',
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final String academyId;
  final String staffId;
  final String staffCode;
  final String staffName;
  final String jobTitle;
  final String branchId;

  /// Sortable month key, e.g. `2026-11`.
  final String monthKey;

  /// Human-readable month label, e.g. `November 2026`.
  final String monthLabel;

  final double baseSalary;
  final double bonus;
  final double deductions;

  /// `'pending'` or `'paid'`.
  final String status;

  /// `'cash'`, `'bank_transfer'`, `'cheque'`, or `'online'`.
  final String paymentMethod;

  final String notes;
  final DateTime? paidAt;
  final DateTime? createdAt;

  double get netSalary {
    final net = baseSalary + bonus - deductions;
    return net < 0 ? 0 : net;
  }

  bool get isPaid => status == 'paid';

  SalaryRecord copyWith({
    String? id,
    String? academyId,
    String? staffId,
    String? staffCode,
    String? staffName,
    String? jobTitle,
    String? branchId,
    String? monthKey,
    String? monthLabel,
    double? baseSalary,
    double? bonus,
    double? deductions,
    String? status,
    String? paymentMethod,
    String? notes,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return SalaryRecord(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      staffId: staffId ?? this.staffId,
      staffCode: staffCode ?? this.staffCode,
      staffName: staffName ?? this.staffName,
      jobTitle: jobTitle ?? this.jobTitle,
      branchId: branchId ?? this.branchId,
      monthKey: monthKey ?? this.monthKey,
      monthLabel: monthLabel ?? this.monthLabel,
      baseSalary: baseSalary ?? this.baseSalary,
      bonus: bonus ?? this.bonus,
      deductions: deductions ?? this.deductions,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'academyId': academyId,
      'staffId': staffId,
      'staffCode': staffCode,
      'staffName': staffName,
      'jobTitle': jobTitle,
      'branchId': branchId,
      'monthKey': monthKey,
      'monthLabel': monthLabel,
      'baseSalary': baseSalary,
      'bonus': bonus,
      'deductions': deductions,
      'netSalary': netSalary,
      'status': status,
      'paymentMethod': paymentMethod,
      'notes': notes,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  factory SalaryRecord.fromJson(Map<String, dynamic> json, {String? id}) {
    return SalaryRecord(
      id: id ?? json['id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      staffId: json['staffId'] as String? ?? '',
      staffCode: json['staffCode'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      monthKey: json['monthKey'] as String? ?? '',
      monthLabel: json['monthLabel'] as String? ?? '',
      baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'bank_transfer',
      notes: json['notes'] as String? ?? '',
      paidAt: _parseDate(json['paidAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

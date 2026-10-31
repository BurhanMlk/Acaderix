import 'package:cloud_firestore/cloud_firestore.dart';

/// A platform subscription plan tier.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    this.billingPeriod = 'month',
    this.maxStudents = 200,
    this.maxBranches = 1,
    this.features = const [],
    this.isPopular = false,
  });

  final String id;
  final String name;
  final int price;
  final String billingPeriod;
  final int maxStudents;
  final int maxBranches;
  final List<String> features;
  final bool isPopular;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'billingPeriod': billingPeriod,
        'maxStudents': maxStudents,
        'maxBranches': maxBranches,
        'features': features,
        'isPopular': isPopular,
      };

  factory SubscriptionPlan.fromJson(String id, Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: id,
        name: json['name'] as String? ?? 'Standard',
        price: (json['price'] as num?)?.toInt() ?? 15000,
        billingPeriod: json['billingPeriod'] as String? ?? 'month',
        maxStudents: (json['maxStudents'] as num?)?.toInt() ?? 200,
        maxBranches: (json['maxBranches'] as num?)?.toInt() ?? 1,
        features: (json['features'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        isPopular: json['isPopular'] as bool? ?? false,
      );

  static const List<SubscriptionPlan> defaultPlans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Basic',
      price: 10000,
      maxStudents: 200,
      maxBranches: 1,
      features: [
        'Up to 200 Students',
        'Single Campus / Branch',
        'Student Attendance Tracking',
        'Monthly Fee Invoices & Receipts',
        'Basic Academic Performance Reports',
      ],
    ),
    SubscriptionPlan(
      id: 'standard',
      name: 'Standard',
      price: 15000,
      maxStudents: 500,
      maxBranches: 3,
      isPopular: true,
      features: [
        'Up to 500 Students',
        'Up to 3 Campus Branches',
        'Exams & Gradebook Management',
        'Staff & Teacher Attendance',
        'Salaries & Expense Tracking',
        'Automated Invoicing & SMS Alerts',
      ],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Premium',
      price: 20000,
      maxStudents: -1,
      maxBranches: -1,
      features: [
        'Unlimited Students & Teachers',
        'Unlimited Campus Branches',
        'Full Academic & Financial Suite',
        'Multi-Campus Centralized Reporting',
        'Priority Technical Support 24/7',
        'Data Backups & Audit Trail',
      ],
    ),
  ];
}

/// An academy's platform subscription status and billing information.
class AcademySubscription {
  const AcademySubscription({
    required this.id,
    required this.academyId,
    required this.academyName,
    required this.academyCode,
    this.logoUrl = '',
    required this.planId,
    required this.planName,
    required this.price,
    required this.status, // 'active', 'grace_period', 'expired', 'cancelled'
    required this.startDate,
    required this.renewalDate,
    this.billingCycle = 'monthly',
    this.paymentStatus = 'paid', // 'paid', 'unpaid', 'overdue'
    this.ownerEmail = '',
    this.ownerPhone = '',
  });

  final String id;
  final String academyId;
  final String academyName;
  final String academyCode;
  final String logoUrl;
  final String planId;
  final String planName;
  final int price;
  final String status;
  final DateTime startDate;
  final DateTime renewalDate;
  final String billingCycle;
  final String paymentStatus;
  final String ownerEmail;
  final String ownerPhone;

  int get daysRemaining {
    final now = DateTime.now();
    return renewalDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  bool get isExpired => daysRemaining < 0;
  bool get isExpiringSoon => daysRemaining >= 0 && daysRemaining <= 7;

  Map<String, dynamic> toJson() => {
        'academyId': academyId,
        'academyName': academyName,
        'academyCode': academyCode,
        'logoUrl': logoUrl,
        'planId': planId,
        'planName': planName,
        'price': price,
        'status': status,
        'startDate': startDate.toIso8601String(),
        'renewalDate': renewalDate.toIso8601String(),
        'billingCycle': billingCycle,
        'paymentStatus': paymentStatus,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
      };

  factory AcademySubscription.fromJson(
      String id, Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    final start = parseDate(json['startDate'], DateTime.now());
    final renewal = parseDate(
      json['renewalDate'],
      start.add(const Duration(days: 30)),
    );

    return AcademySubscription(
      id: id,
      academyId: json['academyId'] as String? ?? id,
      academyName: json['academyName'] as String? ?? '',
      academyCode: json['academyCode'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      planId: json['planId'] as String? ?? 'standard',
      planName: json['planName'] as String? ?? 'Standard',
      price: (json['price'] as num?)?.toInt() ?? 15000,
      status: json['status'] as String? ?? 'active',
      startDate: start,
      renewalDate: renewal,
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      paymentStatus: json['paymentStatus'] as String? ?? 'paid',
      ownerEmail: json['ownerEmail'] as String? ?? '',
      ownerPhone: json['ownerPhone'] as String? ?? '',
    );
  }

  AcademySubscription copyWith({
    String? academyName,
    String? academyCode,
    String? planId,
    String? planName,
    int? price,
    String? status,
    DateTime? startDate,
    DateTime? renewalDate,
    String? billingCycle,
    String? paymentStatus,
    String? logoUrl,
    String? ownerEmail,
    String? ownerPhone,
  }) {
    return AcademySubscription(
      id: id,
      academyId: academyId,
      academyName: academyName ?? this.academyName,
      academyCode: academyCode ?? this.academyCode,
      logoUrl: logoUrl ?? this.logoUrl,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      price: price ?? this.price,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      renewalDate: renewalDate ?? this.renewalDate,
      billingCycle: billingCycle ?? this.billingCycle,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }
}

/// A recorded subscription payment receipt.
class SubscriptionPayment {
  const SubscriptionPayment({
    required this.id,
    required this.academyId,
    required this.academyName,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNumber = '',
    this.notes = '',
    this.status = 'completed',
  });

  final String id;
  final String academyId;
  final String academyName;
  final int amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String referenceNumber;
  final String notes;
  final String status;

  Map<String, dynamic> toJson() => {
        'academyId': academyId,
        'academyName': academyName,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'notes': notes,
        'status': status,
      };

  factory SubscriptionPayment.fromJson(
      String id, Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    return SubscriptionPayment(
      id: id,
      academyId: json['academyId'] as String? ?? '',
      academyName: json['academyName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      paymentDate: parseDate(json['paymentDate'], DateTime.now()),
      paymentMethod: json['paymentMethod'] as String? ?? 'Bank Transfer',
      referenceNumber: json['referenceNumber'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
    );
  }
}

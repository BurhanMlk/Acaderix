import 'package:freezed_annotation/freezed_annotation.dart';

part 'fee_structure.freezed.dart';
part 'fee_structure.g.dart';

/// A reusable fee structure template for generating invoices.
///
/// Academy admins create fee structures per course/class (e.g. "Class 10 Monthly Fee").
/// These templates are used to bulk-generate invoices for all enrolled students.
@freezed
abstract class FeeStructure with _$FeeStructure {
  const factory FeeStructure({
    required String id,
    required String academyId,
    @Default('') String title,
    @Default('') String description,
    @Default(0) double amount,
    @Default('monthly')
    String frequency, // monthly, quarterly, annual, one-time
    @Default(15) int dueDayOfMonth, // day of month when payment is due
    @Default(0) double lateFinePerDay, // PKR per day after due date
    @Default(500) double lateFineMax, // max late fine cap
    @Default('') String branchId, // empty = all branches
    @Default('') String courseId, // empty = all courses
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _FeeStructure;

  factory FeeStructure.fromJson(Map<String, dynamic> json) =>
      _$FeeStructureFromJson(json);
}

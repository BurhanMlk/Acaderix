import 'dart:math' as math;

/// Immutable, auditable fee calculations.
///
/// Financial records are modeled as invoices + payments + adjustments, never
/// by overwriting a single amount. These helpers compute derived values only;
/// posting is done by trusted code (Cloud Functions).
abstract final class FeeCalculator {
  /// Invoice total = base + fine − discount − scholarship (never negative).
  static double invoiceTotal({
    required double baseAmount,
    double fine = 0,
    double discount = 0,
    double scholarship = 0,
  }) {
    final additions = baseAmount + fine;
    final reductions = discount + scholarship;
    return math.max(0, additions - reductions);
  }

  /// Outstanding amount = total − payments received (never negative).
  static double outstanding(double invoiceTotal, double paid) {
    return math.max(0, invoiceTotal - paid);
  }

  /// Whether an invoice is fully settled within a small tolerance.
  static bool isSettled(double invoiceTotal, double paid) {
    return outstanding(invoiceTotal, paid) < 0.01;
  }

  /// Calculates accumulated late fine based on days overdue.
  /// Returns 0 if not overdue or fine rate is 0.
  static double lateFine({
    required DateTime dueDate,
    required double finePerDay,
    double maxFine = 0,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    if (now.isBefore(dueDate) || finePerDay <= 0) return 0;
    final daysLate = now.difference(dueDate).inDays;
    final fine = daysLate * finePerDay;
    return maxFine > 0 ? math.min(fine, maxFine) : fine;
  }
}

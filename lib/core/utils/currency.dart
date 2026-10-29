import 'package:intl/intl.dart';

/// Deterministic PKR currency formatting.
///
/// Uses the always-available `en_US` number data so formatting never depends
/// on runtime locale initialization.
abstract final class CurrencyFormatter {
  static final NumberFormat _number = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimal = NumberFormat('#,##0.00', 'en_US');

  /// Formats an integer PKR amount, e.g. `Rs. 25,000`.
  static String pkr(num amount) => 'Rs. ${_number.format(amount)}';

  /// Formats an amount with two decimal places, e.g. `Rs. 25,000.00`.
  static String pkrDecimal(num amount) => 'Rs. ${_decimal.format(amount)}';

  /// Formats a plain number without a currency symbol.
  static String plain(num amount) => _number.format(amount);
}

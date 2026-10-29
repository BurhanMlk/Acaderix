import 'package:intl/intl.dart';

/// Reusable synchronous form validators.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _digits = RegExp(r'^\d+$');

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? digits(String? value, {int? length, String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    if (!_digits.hasMatch(value.trim())) {
      return '$label must contain digits only';
    }
    if (length != null && value.trim().length != length) {
      return '$label must be $length digits';
    }
    return null;
  }

  static String? rollNumber(String? value) =>
      digits(value, length: 6, label: 'Roll number');

  static String? pin(String? value) => digits(value, length: 4, label: 'PIN');

  /// Validates an optional 13-digit Pakistani CNIC.
  ///
  /// Returns null when the field is empty so callers can treat it as optional.
  static String? cnic(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll('-', '').replaceAll(' ', '');
    if (!RegExp(r'^\d{13}$').hasMatch(cleaned)) {
      return 'Enter a valid 13-digit CNIC';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? date(String? value, {String label = 'Date'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final parsed = DateFormat('yyyy-MM-dd').tryParse(value.trim());
    if (parsed == null) return 'Enter a valid date';
    return null;
  }
}

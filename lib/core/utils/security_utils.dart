import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cryptographic utilities for secure password and PIN hashing and verification.
///
/// Ensures credentials are never persisted as plain text in Firestore.
abstract final class SecurityUtils {
  static const String _passwordSalt = 'acaderix_salt_pwd_v2026_#984!';
  static const String _pinSalt = 'acaderix_salt_pin_v2026_#412!';

  /// Returns a salted SHA-256 cryptographic hash of a staff/user password.
  static String hashPassword(String password) {
    final clean = password.trim();
    if (clean.isEmpty) return '';
    final bytes = utf8.encode('$_passwordSalt:$clean');
    return sha256.convert(bytes).toString();
  }

  /// Verifies an input plain-text password against a stored hash.
  /// Also permits plain-text equality for backward compatibility with existing records.
  static bool verifyPassword(String inputPassword, String stored) {
    final cleanInput = inputPassword.trim();
    final cleanStored = stored.trim();
    if (cleanInput.isEmpty || cleanStored.isEmpty) return false;

    final computedHash = hashPassword(cleanInput);
    if (computedHash == cleanStored) return true;

    // Backward-compatible fallback for legacy plain-text records
    return cleanInput == cleanStored;
  }

  /// Returns a salted SHA-256 cryptographic hash of a student PIN.
  static String hashPin(String pin) {
    final clean = pin.trim();
    if (clean.isEmpty) return '';
    final bytes = utf8.encode('$_pinSalt:$clean');
    return sha256.convert(bytes).toString();
  }

  /// Verifies an input student PIN against a stored hash.
  /// Also permits plain-text equality for backward compatibility with existing records.
  static bool verifyPin(String inputPin, String stored) {
    final cleanInput = inputPin.trim();
    final cleanStored = stored.trim();
    if (cleanInput.isEmpty || cleanStored.isEmpty) return false;

    final computedHash = hashPin(cleanInput);
    if (computedHash == cleanStored) return true;

    // Backward-compatible fallback for legacy plain-text records
    return cleanInput == cleanStored;
  }
}

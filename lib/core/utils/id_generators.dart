import 'dart:math';

/// Generators for academy codes, student roll numbers and temporary PINs.
///
/// These are pure functions: callers are responsible for enforcing uniqueness
/// through a Firestore transaction or a trusted Cloud Function (e.g. the
/// roll-number counter under `academies/{academyId}/counters`).
abstract final class IdGenerators {
  static const int rollNumberMin = 100001;
  static const int rollNumberMax = 999999;

  static const String _academyCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Returns the next roll number after [current], clamped to the valid range.
  ///
  /// The very first roll number is [rollNumberMin] (100001).
  static int nextRollNumber(int current) {
    if (current < rollNumberMin) return rollNumberMin;
    if (current >= rollNumberMax) return rollNumberMax;
    return current + 1;
  }

  /// Whether [value] is a valid six-digit roll number within range.
  static bool isValidRollNumber(String value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return false;
    final parsed = int.parse(value);
    return parsed >= rollNumberMin && parsed <= rollNumberMax;
  }

  /// Generates a random four-digit temporary PIN (0000-9999).
  ///
  /// Prefer [Random.secure]. The PIN is temporary: it must be hashed before
  /// storage, expire, and never be re-exposed after initial delivery.
  static String generatePin([Random? random]) {
    final rng = random ?? Random.secure();
    return rng.nextInt(10000).toString().padLeft(4, '0');
  }

  /// Generates a human-friendly, unique-looking academy code (e.g. `ACD-7F3K2`).
  ///
  /// Uniqueness is enforced at write time via a transaction on the
  /// `academy_codes` collection.
  static String generateAcademyCode([Random? random]) {
    final rng = random ?? Random.secure();
    final buffer = StringBuffer('ACD-');
    for (var i = 0; i < 5; i++) {
      buffer.write(
        _academyCodeAlphabet[rng.nextInt(_academyCodeAlphabet.length)],
      );
    }
    return buffer.toString();
  }
}

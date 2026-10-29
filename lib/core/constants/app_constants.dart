/// Application-wide constants shared across the codebase.
abstract final class AppConstants {
  /// Display name of the product.
  static const String appName = 'Academy Management System';

  /// Default currency for the platform (PKR).
  static const String currencyCode = 'PKR';

  /// Default locale used for formatting when device locale is unavailable.
  static const String defaultLocale = 'en_US';

  /// Number of items fetched per page in paginated Firestore queries.
  static const int pageSize = 25;

  /// Six-digit roll number range.
  static const int rollNumberMin = 100001;
  static const int rollNumberMax = 999999;

  /// Length of the temporary student PIN.
  static const int temporaryPinLength = 4;
}

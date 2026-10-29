/// Base class for all expected application errors.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  /// User-safe message suitable for display.
  final String message;

  /// Optional stable machine-readable code.
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

final class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

final class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message, {super.code});
}

final class ConfigurationException extends AppException {
  const ConfigurationException(super.message, {super.code});
}

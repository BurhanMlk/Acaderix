/// Presentation-friendly failure envelope.
///
/// Repositories translate platform and domain exceptions into [Failure]s so
/// that UI layers never depend on exception types directly.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

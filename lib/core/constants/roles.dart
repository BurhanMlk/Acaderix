import 'package:json_annotation/json_annotation.dart';

/// The set of roles understood across the platform.
///
/// A single user may hold academy-specific permissions, but a user's top-level
/// experience is determined by exactly one of these roles.
enum AppRole {
  unauthenticated('unauthenticated', 'Guest'),
  superAdmin('super_admin', 'Super Admin'),
  academyAdmin('academy_admin', 'Academy Admin'),
  staff('staff', 'Staff'),
  student('student', 'Student');

  const AppRole(this.id, this.label);

  /// Stable identifier persisted in Firestore (`users/{uid}` documents).
  final String id;

  /// Human readable label for the UI.
  final String label;

  /// Resolves a persisted role id to an [AppRole].
  ///
  /// Unknown values fall back to [AppRole.unauthenticated] so that a bad or
  /// tampered value can never grant an authenticated experience.
  static AppRole fromId(String? id) => AppRole.values.firstWhere(
    (role) => role.id == id,
    orElse: () => AppRole.unauthenticated,
  );

  /// Whether this role represents a signed-in user.
  bool get isAuthenticated => this != AppRole.unauthenticated;
}

/// JSON converter for [AppRole] used by typed Freezed models.
class AppRoleConverter implements JsonConverter<AppRole, String> {
  const AppRoleConverter();

  @override
  AppRole fromJson(String json) => AppRole.fromId(json);

  @override
  String toJson(AppRole role) => role.id;
}

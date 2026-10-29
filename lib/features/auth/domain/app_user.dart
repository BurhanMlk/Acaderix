import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/constants/roles.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// A signed-in platform user.
///
/// A single physical user may belong to multiple academies; the fields
/// [academyId], [branchId] and [rollNumber] capture the context the user is
/// currently operating within.
@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String id,
    @Default('') String email,
    @Default('') String displayName,
    String? academyId,
    String? branchId,
    @AppRoleConverter() @Default(AppRole.unauthenticated) AppRole role,
    String? rollNumber,
    @Default(true) bool isActive,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  bool get isStudent => role == AppRole.student;

  bool get isStaff => role == AppRole.staff;

  bool get isAcademyAdmin => role == AppRole.academyAdmin;

  bool get isSuperAdmin => role == AppRole.superAdmin;
}

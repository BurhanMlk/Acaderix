// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: json['id'] as String,
  email: json['email'] as String? ?? '',
  displayName: json['displayName'] as String? ?? '',
  academyId: json['academyId'] as String?,
  branchId: json['branchId'] as String?,
  role: json['role'] == null
      ? AppRole.unauthenticated
      : const AppRoleConverter().fromJson(json['role'] as String),
  rollNumber: json['rollNumber'] as String?,
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'displayName': instance.displayName,
  'academyId': instance.academyId,
  'branchId': instance.branchId,
  'role': const AppRoleConverter().toJson(instance.role),
  'rollNumber': instance.rollNumber,
  'isActive': instance.isActive,
};

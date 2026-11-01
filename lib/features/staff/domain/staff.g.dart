// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Staff _$StaffFromJson(Map<String, dynamic> json) => _Staff(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  staffId: json['staffId'] as String? ?? '',
  fullName: json['fullName'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  email: json['email'] as String? ?? '',
  address: json['address'] as String? ?? '',
  photoUrl: json['photoUrl'] as String? ?? '',
  jobTitle: json['jobTitle'] as String? ?? '',
  branchId: json['branchId'] as String? ?? '',
  joiningDate: json['joiningDate'] == null
      ? null
      : DateTime.parse(json['joiningDate'] as String),
  salary: (json['salary'] as num?)?.toDouble() ?? 0,
  status: json['status'] as String? ?? 'active',
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  leaveBalance: (json['leaveBalance'] as num?)?.toInt() ?? 0,
  password: json['password'] as String? ?? '',
);

Map<String, dynamic> _$StaffToJson(_Staff instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'staffId': instance.staffId,
  'fullName': instance.fullName,
  'phone': instance.phone,
  'email': instance.email,
  'address': instance.address,
  'photoUrl': instance.photoUrl,
  'jobTitle': instance.jobTitle,
  'branchId': instance.branchId,
  'joiningDate': instance.joiningDate?.toIso8601String(),
  'salary': instance.salary,
  'status': instance.status,
  'permissions': instance.permissions,
  'leaveBalance': instance.leaveBalance,
  'password': instance.password,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Student _$StudentFromJson(Map<String, dynamic> json) => _Student(
  id: json['id'] as String,
  academyId: json['academyId'] as String,
  fullName: json['fullName'] as String? ?? '',
  fatherName: json['fatherName'] as String? ?? '',
  motherName: json['motherName'] as String? ?? '',
  dateOfBirth: json['dateOfBirth'] == null
      ? null
      : DateTime.parse(json['dateOfBirth'] as String),
  gender: json['gender'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  guardianPhone: json['guardianPhone'] as String? ?? '',
  guardianRelation: json['guardianRelation'] as String? ?? '',
  address: json['address'] as String? ?? '',
  photoUrl: json['photoUrl'] as String? ?? '',
  admissionDate: json['admissionDate'] == null
      ? null
      : DateTime.parse(json['admissionDate'] as String),
  previousInstitute: json['previousInstitute'] as String? ?? '',
  academicSession: json['academicSession'] as String? ?? '',
  rollNumber: json['rollNumber'] as String? ?? '',
  status: json['status'] as String? ?? 'active',
  notes: json['notes'] as String? ?? '',
  branchId: json['branchId'] as String? ?? '',
);

Map<String, dynamic> _$StudentToJson(_Student instance) => <String, dynamic>{
  'id': instance.id,
  'academyId': instance.academyId,
  'fullName': instance.fullName,
  'fatherName': instance.fatherName,
  'motherName': instance.motherName,
  'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
  'gender': instance.gender,
  'phone': instance.phone,
  'guardianPhone': instance.guardianPhone,
  'guardianRelation': instance.guardianRelation,
  'address': instance.address,
  'photoUrl': instance.photoUrl,
  'admissionDate': instance.admissionDate?.toIso8601String(),
  'previousInstitute': instance.previousInstitute,
  'academicSession': instance.academicSession,
  'rollNumber': instance.rollNumber,
  'status': instance.status,
  'notes': instance.notes,
  'branchId': instance.branchId,
};

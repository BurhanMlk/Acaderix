// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Academy _$AcademyFromJson(Map<String, dynamic> json) => _Academy(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String? ?? '',
  logoUrl: json['logoUrl'] as String? ?? '',
  ownerName: json['ownerName'] as String? ?? '',
  ownerEmail: json['ownerEmail'] as String? ?? '',
  ownerPhone: json['ownerPhone'] as String? ?? '',
  address: json['address'] as String? ?? '',
  city: json['city'] as String? ?? '',
  province: json['province'] as String? ?? '',
  branchCount: (json['branchCount'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? 'pending',
  registrationDate: json['registrationDate'] == null
      ? null
      : DateTime.parse(json['registrationDate'] as String),
);

Map<String, dynamic> _$AcademyToJson(_Academy instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'logoUrl': instance.logoUrl,
  'ownerName': instance.ownerName,
  'ownerEmail': instance.ownerEmail,
  'ownerPhone': instance.ownerPhone,
  'address': instance.address,
  'city': instance.city,
  'province': instance.province,
  'branchCount': instance.branchCount,
  'status': instance.status,
  'registrationDate': instance.registrationDate?.toIso8601String(),
};

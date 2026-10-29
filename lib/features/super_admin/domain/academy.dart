import 'package:freezed_annotation/freezed_annotation.dart';

part 'academy.freezed.dart';
part 'academy.g.dart';

/// A registered academy (tenant).
@freezed
abstract class Academy with _$Academy {
  const factory Academy({
    required String id,
    required String code,
    @Default('') String name,
    @Default('') String logoUrl,
    @Default('') String ownerName,
    @Default('') String ownerEmail,
    @Default('') String ownerPhone,
    @Default('') String address,
    @Default('') String city,
    @Default('') String province,
    @Default(0) int branchCount,
    @Default('pending') String status,
    DateTime? registrationDate,
  }) = _Academy;

  factory Academy.fromJson(Map<String, dynamic> json) =>
      _$AcademyFromJson(json);
}

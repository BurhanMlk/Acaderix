import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch.freezed.dart';
part 'branch.g.dart';

/// A physical branch of an academy.
@freezed
abstract class Branch with _$Branch {
  const factory Branch({
    required String id,
    required String academyId,
    @Default('') String name,
    @Default('') String address,
    @Default('') String city,
    @Default('') String phone,
    @Default(true) bool isActive,
  }) = _Branch;

  factory Branch.fromJson(Map<String, dynamic> json) => _$BranchFromJson(json);
}

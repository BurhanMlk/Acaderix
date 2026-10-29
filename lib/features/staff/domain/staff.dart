import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff.freezed.dart';
part 'staff.g.dart';

/// A staff member of an academy.
@freezed
abstract class Staff with _$Staff {
  const factory Staff({
    required String id,
    required String academyId,
    @Default('') String fullName,
    @Default('') String phone,
    @Default('') String email,
    @Default('') String address,
    @Default('') String photoUrl,
    @Default('') String jobTitle,
    @Default('') String branchId,
    DateTime? joiningDate,
    @Default(0) double salary,
    @Default('active') String status,
    @Default(<String>[]) List<String> permissions,
    @Default(0) int leaveBalance,
  }) = _Staff;

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
}

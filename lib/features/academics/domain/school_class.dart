import 'package:freezed_annotation/freezed_annotation.dart';

part 'school_class.freezed.dart';
part 'school_class.g.dart';

/// A class level (e.g. "Class 9", "Class 10").
@freezed
abstract class SchoolClass with _$SchoolClass {
  const factory SchoolClass({
    required String id,
    required String academyId,
    @Default('') String name,
    @Default('') String courseId,
    @Default(true) bool isActive,
  }) = _SchoolClass;

  factory SchoolClass.fromJson(Map<String, dynamic> json) =>
      _$SchoolClassFromJson(json);
}

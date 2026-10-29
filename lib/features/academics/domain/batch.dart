import 'package:freezed_annotation/freezed_annotation.dart';

part 'batch.freezed.dart';
part 'batch.g.dart';

/// A teaching batch (section) with capacity and timings.
@freezed
abstract class Batch with _$Batch {
  const factory Batch({
    required String id,
    required String academyId,
    @Default('') String name,
    @Default('') String classId,
    @Default('') String branchId,
    @Default(0) int capacity,
    @Default('') String timing,
    @Default('') String classroom,
    @Default(true) bool isActive,
  }) = _Batch;

  factory Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);
}

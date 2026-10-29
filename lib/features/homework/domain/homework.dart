import 'package:freezed_annotation/freezed_annotation.dart';

part 'homework.freezed.dart';
part 'homework.g.dart';

/// A homework assignment for a batch.
@freezed
abstract class Homework with _$Homework {
  const factory Homework({
    required String id,
    required String academyId,
    @Default('') String title,
    @Default('') String description,
    @Default('') String subjectId,
    @Default('') String batchId,
    DateTime? dueDate,
    @Default(<String>[]) List<String> attachmentUrls,
    @Default('') String assignedById,
  }) = _Homework;

  factory Homework.fromJson(Map<String, dynamic> json) =>
      _$HomeworkFromJson(json);
}

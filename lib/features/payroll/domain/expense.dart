import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

/// An academy expense entry.
@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String academyId,
    @Default('') String category,
    @Default(0) double amount,
    @Default('') String description,
    DateTime? date,
    @Default('') String recordedById,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

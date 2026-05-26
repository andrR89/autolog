import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String vehicleId,
    required DateTime date,
    @ExpenseCategoryConverter() required ExpenseCategory category,
    required String description,
    @DecimalJsonConverter() required Decimal amount,
    int? odometer,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    @SyncStatusConverter() required SyncStatus syncStatus,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

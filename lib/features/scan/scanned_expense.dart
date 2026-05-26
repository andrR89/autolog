import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/json_converters.dart';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanned_expense.freezed.dart';
part 'scanned_expense.g.dart';

/// Dados extraídos pela IA a partir de um comprovante de despesa veicular.
///
/// Todos os campos são nullable: a IA pode falhar em extrair campos individuais.
/// O usuário revisa e confirma antes de salvar (Regra de Ouro #3).
@freezed
abstract class ScannedExpense with _$ScannedExpense {
  const factory ScannedExpense({
    @DecimalJsonConverter() Decimal? amount,
    DateTime? date,
    @ExpenseCategoryNullableConverter() ExpenseCategory? category,
    String? description,
    String? documentType,
  }) = _ScannedExpense;

  factory ScannedExpense.fromJson(Map<String, dynamic> json) =>
      _$ScannedExpenseFromJson(json);
}

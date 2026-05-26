import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

class MonthlyTotal {
  const MonthlyTotal({required this.month, required this.total});

  /// Primeiro dia do mês em UTC, à meia-noite. Identifica o "bucket".
  final DateTime month;

  /// Soma de fuel_entries.totalCost + expenses.amount do mês.
  final Decimal total;
}

/// Agrega gasto total (combustível + despesas) por mês.
/// Retorna lista ordenada por mês ASC. Meses sem dados não aparecem.
/// Soft-deleted devem vir já filtrados pelos repositórios.
List<MonthlyTotal> computeMonthlySpending({
  required List<FuelEntry> fuelEntries,
  required List<Expense> expenses,
}) {
  final Map<DateTime, Decimal> acc = {};
  DateTime bucketOf(DateTime d) => DateTime.utc(d.year, d.month, 1);

  for (final e in fuelEntries) {
    final b = bucketOf(e.date);
    acc[b] = (acc[b] ?? Decimal.zero) + e.totalCost;
  }
  for (final x in expenses) {
    final b = bucketOf(x.date);
    acc[b] = (acc[b] ?? Decimal.zero) + x.amount;
  }

  final keys = acc.keys.toList()..sort();
  return [for (final k in keys) MonthlyTotal(month: k, total: acc[k]!)];
}

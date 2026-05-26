// Mapper privado da camada de dados — não exportar fora de lib/data/repositories/.
// Converte entre ExpenseRow (Drift) e Expense (domínio).

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:drift/drift.dart';

/// Converte uma linha do banco para o modelo de domínio.
///
/// Aplica [toUtc()] em todos os [DateTime] lidos do banco (Drift armazena
/// como unix timestamp e pode retornar hora local dependendo da plataforma).
/// Decimal flui direto do [DecimalConverter] — sem tocar em double.
Expense expenseToDomain(ExpenseRow row) {
  return Expense(
    id: row.id,
    vehicleId: row.vehicleId,
    date: row.date.toUtc(),
    category: row.category,
    description: row.description,
    // Decimal vem do DecimalConverter (TEXT → Decimal.parse); apenas repassa.
    amount: row.amount,
    odometer: row.odometer,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    syncStatus: row.syncStatus,
  );
}

/// Converte o modelo de domínio para o companion do Drift.
///
/// Todos os campos são embrulhados em [Value]. Decimal passa diretamente para
/// o [DecimalConverter] — sem conversão para double.
ExpensesCompanion expenseToCompanion(Expense e) {
  return ExpensesCompanion(
    id: Value(e.id),
    vehicleId: Value(e.vehicleId),
    date: Value(e.date),
    category: Value(e.category),
    description: Value(e.description),
    amount: Value(e.amount),
    odometer: Value(e.odometer),
    createdAt: Value(e.createdAt),
    updatedAt: Value(e.updatedAt),
    deletedAt: Value(e.deletedAt),
    syncStatus: Value(e.syncStatus),
  );
}

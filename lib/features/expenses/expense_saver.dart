import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/repositories/expense_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Orquestra criação, edição e exclusão de despesas via [ExpenseRepository].
///
/// Espelha o padrão de [FuelEntrySaver] (Sprint 2.3).
/// Recebe o repositório e um gerador de IDs injetáveis para facilitar testes.
class ExpenseSaver {
  ExpenseSaver(this._repo, {required String Function() generateId})
    : _generateId = generateId;

  final ExpenseRepository _repo;
  final String Function() _generateId;

  /// Cria uma despesa.
  ///
  /// O id é gerado por [generateId]. O repositório define timestamps e sync_status.
  Future<Expense> create({
    required String vehicleId,
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    required Decimal amount,
    int? odometer,
  }) {
    final now = DateTime.now().toUtc();
    final expense = Expense(
      id: _generateId(),
      vehicleId: vehicleId,
      date: date,
      category: category,
      description: description,
      amount: amount,
      odometer: odometer,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    return _repo.create(expense);
  }

  /// Atualiza uma despesa existente, preservando campos de identidade.
  ///
  /// Preserva: [Expense.id], [Expense.vehicleId], [Expense.createdAt].
  /// O repositório bumpa updated_at e sync_status.
  Future<Expense> update(
    Expense existing, {
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    required Decimal amount,
    int? odometer,
  }) {
    final updated = existing.copyWith(
      date: date,
      category: category,
      description: description,
      amount: amount,
      odometer: odometer,
      // id, vehicleId, createdAt → intocados pelo copyWith.
    );
    return _repo.update(updated);
  }

  /// Soft delete via [ExpenseRepository.softDelete]. Nunca hard delete.
  Future<void> delete(String id) {
    return _repo.softDelete(id);
  }
}

/// Provider Riverpod que expõe o [ExpenseSaver] configurado para produção.
final expenseSaverProvider = Provider<ExpenseSaver>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return ExpenseSaver(repo, generateId: () => const Uuid().v4());
});

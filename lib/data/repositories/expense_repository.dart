import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_expense_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/repositories/expense_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// DriftExpenseRepository
// ---------------------------------------------------------------------------

/// Implementação local de [ExpenseRepository] sobre Drift.
///
/// Recebe [AppDatabase] e um relógio opcional [now] para facilitar testes
/// determinísticos. Toda mutação grava localmente, marca sync_status=pending
/// e bumpa updated_at (Regra de Ouro: offline-first).
DateTime _utcNow() => DateTime.now().toUtc();

class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(this._db, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  // -------------------------------------------------------------------------
  // create
  // -------------------------------------------------------------------------

  @override
  Future<Expense> create(Expense expense) async {
    final timestamp = _now();
    // Repositório sempre controla createdAt, updatedAt e sync_status.
    final companion = expenseToCompanion(
      expense.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
        deletedAt: null,
      ),
    );

    await _db.into(_db.expenses).insert(companion);

    final row = await (_db.select(
      _db.expenses,
    )..where((t) => t.id.equals(expense.id))).getSingle();

    return expenseToDomain(row);
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  @override
  Future<Expense> update(Expense expense) async {
    // Busca a linha incluindo soft-deleted para distinguir "não existe" de "deletado".
    final existing = await (_db.select(
      _db.expenses,
    )..where((t) => t.id.equals(expense.id))).getSingleOrNull();

    if (existing == null) {
      throw StateError('Despesa não encontrada: ${expense.id}');
    }
    if (existing.deletedAt != null) {
      throw StateError(
        'Despesa soft-deletada não pode ser atualizada: ${expense.id}',
      );
    }

    final timestamp = _now();
    final companion = expenseToCompanion(
      expense.copyWith(
        // Preserva createdAt original do banco.
        createdAt: existing.createdAt,
        // Repositório controla updated_at.
        updatedAt: timestamp,
        // Toda escrita local vira pending.
        syncStatus: SyncStatus.pending,
      ),
    );

    await (_db.update(
      _db.expenses,
    )..where((t) => t.id.equals(expense.id))).write(companion);

    final row = await (_db.select(
      _db.expenses,
    )..where((t) => t.id.equals(expense.id))).getSingle();

    return expenseToDomain(row);
  }

  // -------------------------------------------------------------------------
  // softDelete
  // -------------------------------------------------------------------------

  @override
  Future<void> softDelete(String id) async {
    // Idempotente: se já deletado, preserva o deleted_at original.
    final existing = await (_db.select(
      _db.expenses,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing == null) return; // Não existe — nada a fazer.
    if (existing.deletedAt != null) return; // Já deletado — idempotente.

    final timestamp = _now();
    await (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(
        deletedAt: Value(timestamp),
        updatedAt: Value(timestamp),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  @override
  Future<Expense?> getById(String id) async {
    final row = await (_db.select(
      _db.expenses,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

    return row == null ? null : expenseToDomain(row);
  }

  // -------------------------------------------------------------------------
  // listByVehicle
  // -------------------------------------------------------------------------

  @override
  Future<List<Expense>> listByVehicle(String vehicleId) async {
    final rows =
        await (_db.select(_db.expenses)
              ..where(
                (t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.date),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();

    return rows.map(expenseToDomain).toList();
  }

  // -------------------------------------------------------------------------
  // watchByVehicle
  // -------------------------------------------------------------------------

  @override
  Stream<List<Expense>> watchByVehicle(String vehicleId) {
    return (_db.select(_db.expenses)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map(expenseToDomain).toList());
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Expõe [DriftExpenseRepository] para o app.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftExpenseRepository(db);
});

import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_expense_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Fachada de sync para expenses — separa as operações de sincronização da
/// API user-facing do [ExpenseRepository].
///
/// Esta interface bypassa a regra "toda escrita marca pending" — é exclusiva
/// do SyncService.
abstract class ExpenseSyncFacade {
  /// Lista todos os expenses pending do [userId], incluindo soft-deletados
  /// (também precisam ser enviados ao remoto).
  /// Filtra por user via JOIN com vehicles (expenses não tem user_id).
  Future<List<Expense>> listPending(String userId);

  /// Cursor de pull: max(updated_at) entre os synced do [userId].
  /// Retorna null se não houver nenhuma linha synced.
  /// Filtra por user via JOIN com vehicles.
  Future<DateTime?> latestSyncedUpdatedAt(String userId);

  /// Marca o expense como synced sem alterar [updatedAt] nem qualquer outro campo.
  Future<void> markSynced(String id);

  /// Aplica o row vindo do remoto exatamente como veio (todos os campos,
  /// incluindo [updatedAt]), e marca como synced. Cria se não existir; atualiza
  /// se existir — nunca mantém valores velhos (campo-completeness garantida).
  Future<void> upsertFromRemote(Expense remote);

  /// Lê o expense bruto por [id] **incluindo soft-deletados**, para o
  /// SyncService comparar updated_at sem o filtro `deleted_at IS NULL` que o
  /// [ExpenseRepository] aplica. Retorna null se não existir.
  Future<Expense?> getById(String id);

  /// Conta os pending do [userId].
  /// Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
  /// Filtra por user via JOIN com vehicles.
  Future<int> countPending(String userId);

  /// Conta os pending do [userId] de forma reativa.
  /// Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
  /// Filtra por user via JOIN com vehicles.
  Stream<int> watchPendingCount(String userId);
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

/// Implementação de [ExpenseSyncFacade] sobre [AppDatabase].
class DriftExpenseSyncFacade implements ExpenseSyncFacade {
  DriftExpenseSyncFacade(this._db);

  final AppDatabase _db;

  // -----------------------------------------------------------------------
  // listPending
  // -----------------------------------------------------------------------

  @override
  Future<List<Expense>> listPending(String userId) async {
    // JOIN com vehicles pra filtrar por userId — expenses não tem user_id.
    // Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
    final query =
        _db.select(_db.expenses).join([
          innerJoin(
            _db.vehicles,
            _db.vehicles.id.equalsExp(_db.expenses.vehicleId),
          ),
        ])..where(
          _db.vehicles.userId.equals(userId) &
              _db.expenses.syncStatus.equalsValue(SyncStatus.pending),
        );
    final rows = await query.get();
    return rows
        .map((row) => expenseToDomain(row.readTable(_db.expenses)))
        .toList();
  }

  // -----------------------------------------------------------------------
  // latestSyncedUpdatedAt
  // -----------------------------------------------------------------------

  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async {
    // SELECT max(updated_at) FROM expenses
    // JOIN vehicles ON vehicles.id = expenses.vehicle_id
    // WHERE vehicles.user_id = ? AND expenses.sync_status = 'synced'
    final updatedAtCol = _db.expenses.updatedAt.max();
    final query =
        _db.selectOnly(_db.expenses).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.expenses.vehicleId),
            ),
          ])
          ..addColumns([updatedAtCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.expenses.syncStatus.equalsValue(SyncStatus.synced),
          );
    final row = await query.getSingleOrNull();
    return row?.read(updatedAtCol)?.toUtc();
  }

  // -----------------------------------------------------------------------
  // markSynced
  // -----------------------------------------------------------------------

  @override
  Future<void> markSynced(String id) async {
    await (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
      const ExpensesCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  // -----------------------------------------------------------------------
  // upsertFromRemote
  // -----------------------------------------------------------------------

  @override
  Future<void> upsertFromRemote(Expense remote) async {
    // Garante campo-completeness: todos os campos explícitos — nenhum
    // Value.absent() — para que INSERT e UPDATE não mantenham valores velhos.
    final companion = ExpensesCompanion.insert(
      id: remote.id,
      vehicleId: remote.vehicleId,
      date: remote.date,
      category: remote.category,
      description: remote.description,
      amount: remote.amount,
      odometer: Value(remote.odometer),
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      deletedAt: Value(remote.deletedAt),
      syncStatus: const Value(SyncStatus.synced),
    );
    await _db.into(_db.expenses).insertOnConflictUpdate(companion);
  }

  // -----------------------------------------------------------------------
  // getById
  // -----------------------------------------------------------------------

  @override
  Future<Expense?> getById(String id) async {
    // Sem filtro de deleted_at: o SyncService precisa enxergar soft-deletados
    // para o cálculo de last-write-wins.
    final row = await (_db.select(
      _db.expenses,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : expenseToDomain(row);
  }

  // -----------------------------------------------------------------------
  // countPending
  // -----------------------------------------------------------------------

  @override
  Future<int> countPending(String userId) async {
    // SELECT count(id) FROM expenses
    // JOIN vehicles ON vehicles.id = expenses.vehicle_id
    // WHERE vehicles.user_id = ? AND expenses.sync_status = 'pending'
    // Sem filtro de deleted_at — soft-deletados pending também contam.
    final countCol = _db.expenses.id.count();
    final query =
        _db.selectOnly(_db.expenses).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.expenses.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.expenses.syncStatus.equalsValue(SyncStatus.pending),
          );
    final row = await query.getSingleOrNull();
    return row?.read(countCol) ?? 0;
  }

  // -----------------------------------------------------------------------
  // watchPendingCount
  // -----------------------------------------------------------------------

  @override
  Stream<int> watchPendingCount(String userId) {
    // SELECT count(id) FROM expenses
    // JOIN vehicles ON vehicles.id = expenses.vehicle_id
    // WHERE vehicles.user_id = ? AND expenses.sync_status = 'pending'
    // Sem filtro de deleted_at — soft-deletados pending também contam.
    final countCol = _db.expenses.id.count();
    final query =
        _db.selectOnly(_db.expenses).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.expenses.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.expenses.syncStatus.equalsValue(SyncStatus.pending),
          );
    return query.watchSingle().map((row) => row.read(countCol) ?? 0);
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final expenseSyncFacadeProvider = Provider<ExpenseSyncFacade>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftExpenseSyncFacade(db);
});

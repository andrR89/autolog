import 'package:autolog/data/sync/expense_sync_facade.dart';
import 'package:autolog/data/sync/remote_expense_source.dart';
import 'package:autolog/data/sync/vehicle_sync_service.dart' show SyncResult;
import 'package:autolog/domain/models/expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// ExpenseSyncService
// ---------------------------------------------------------------------------

/// Motor de sincronização para expenses.
///
/// Ordem: **push primeiro** (envia o que ainda não subiu), **pull depois**
/// (recebe do servidor). Falhas em push não abortam o pull e vice-versa.
/// [sync] NUNCA lança exceção — sempre retorna [SyncResult].
///
/// [SyncResult] é reusado de [vehicle_sync_service.dart] — não duplicar.
class ExpenseSyncService {
  ExpenseSyncService({
    required ExpenseSyncFacade facade,
    required RemoteExpenseSource remote,
  }) : _facade = facade,
       _remote = remote;

  final ExpenseSyncFacade _facade;
  final RemoteExpenseSource _remote;

  /// Executa push → pull para o [userId].
  Future<SyncResult> sync(String userId) async {
    int pushed = 0;
    int pushFailures = 0;
    int pulled = 0;
    Object? pullError;

    // ------------------------------------------------------------------
    // Push: enviar todos os pending (incluindo soft-deletados).
    // ------------------------------------------------------------------
    final pending = await _facade.listPending(userId);
    for (final entry in pending) {
      try {
        await _remote.upsert(entry);
        await _facade.markSynced(entry.id);
        pushed++;
      } catch (_) {
        // Mantém pending — será reenviado no próximo sync.
        pushFailures++;
      }
    }

    // ------------------------------------------------------------------
    // Pull: buscar do remoto o que é mais novo que o cursor local.
    // ------------------------------------------------------------------
    final since = await _facade.latestSyncedUpdatedAt(userId);
    try {
      final remoteRows = await _remote.fetchUpdatedSince(
        userId: userId,
        since: since,
      );

      for (final remote in remoteRows) {
        // Lê o expense local incluindo soft-deletados, para comparar updated_at.
        final Expense? local = await _facade.getById(remote.id);

        final bool shouldApply;
        if (local == null) {
          // Não existe localmente — insert.
          shouldApply = true;
        } else {
          // last-write-wins: remoto vence apenas se estritamente mais novo.
          // Empate → local vence (não sobrescreve à toa).
          shouldApply = remote.updatedAt.isAfter(local.updatedAt);
        }

        if (shouldApply) {
          await _facade.upsertFromRemote(remote);
          pulled++;
        }
      }
    } catch (e) {
      pullError = e;
    }

    return SyncResult(
      pushed: pushed,
      pulled: pulled,
      pushFailures: pushFailures,
      pullError: pullError,
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final expenseSyncServiceProvider = Provider<ExpenseSyncService>((ref) {
  final facade = ref.watch(expenseSyncFacadeProvider);
  final remote = ref.watch(remoteExpenseSourceProvider);
  return ExpenseSyncService(facade: facade, remote: remote);
});

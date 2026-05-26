import 'package:autolog/data/sync/fine_sync_facade.dart';
import 'package:autolog/data/sync/remote_fine_source.dart';
import 'package:autolog/data/sync/vehicle_sync_service.dart' show SyncResult;
import 'package:autolog/domain/models/fine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// FineSyncService
// ---------------------------------------------------------------------------

/// Motor de sincronização para fines.
///
/// Ordem: **push primeiro** (envia o que ainda não subiu), **pull depois**
/// (recebe do servidor). Falhas em push não abortam o pull e vice-versa.
/// [sync] NUNCA lança exceção — sempre retorna [SyncResult].
class FineSyncService {
  FineSyncService({
    required FineSyncFacade facade,
    required RemoteFineSource remote,
  }) : _facade = facade,
       _remote = remote;

  final FineSyncFacade _facade;
  final RemoteFineSource _remote;

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
        final Fine? local = await _facade.getById(remote.id);

        final bool shouldApply;
        if (local == null) {
          shouldApply = true;
        } else {
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

final fineSyncServiceProvider = Provider<FineSyncService>((ref) {
  final facade = ref.watch(fineSyncFacadeProvider);
  final remote = ref.watch(remoteFineSourceProvider);
  return FineSyncService(facade: facade, remote: remote);
});

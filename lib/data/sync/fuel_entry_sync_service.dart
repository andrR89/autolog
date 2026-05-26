import 'package:autolog/data/sync/fuel_entry_sync_facade.dart';
import 'package:autolog/data/sync/remote_fuel_entry_source.dart';
import 'package:autolog/data/sync/vehicle_sync_service.dart' show SyncResult;
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// FuelEntrySyncService
// ---------------------------------------------------------------------------

/// Motor de sincronização para fuel_entries.
///
/// Ordem: **push primeiro** (envia o que ainda não subiu), **pull depois**
/// (recebe do servidor). Falhas em push não abortam o pull e vice-versa.
/// [sync] NUNCA lança exceção — sempre retorna [SyncResult].
///
/// [SyncResult] é reusado de [vehicle_sync_service.dart] — não duplicar.
class FuelEntrySyncService {
  FuelEntrySyncService({
    required FuelEntrySyncFacade facade,
    required RemoteFuelEntrySource remote,
  }) : _facade = facade,
       _remote = remote;

  final FuelEntrySyncFacade _facade;
  final RemoteFuelEntrySource _remote;

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
        // Lê o fuel_entry local incluindo soft-deletados, para comparar updated_at.
        final FuelEntry? local = await _facade.getRawById(remote.id);

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

final fuelEntrySyncServiceProvider = Provider<FuelEntrySyncService>((ref) {
  final facade = ref.watch(fuelEntrySyncFacadeProvider);
  final remote = ref.watch(remoteFuelEntrySourceProvider);
  return FuelEntrySyncService(facade: facade, remote: remote);
});

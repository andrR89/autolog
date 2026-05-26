import 'package:autolog/data/sync/remote_vehicle_source.dart';
import 'package:autolog/data/sync/vehicle_sync_facade.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// SyncResult
// ---------------------------------------------------------------------------

/// Resultado de uma execução de [VehicleSyncService.sync].
class SyncResult {
  const SyncResult({
    required this.pushed,
    required this.pulled,
    required this.pushFailures,
    this.pullError,
  });

  /// Rows enviados ao remoto com sucesso.
  final int pushed;

  /// Rows aplicados do remoto localmente.
  final int pulled;

  /// Upserts que falharam (mantidos pending para próximo sync).
  final int pushFailures;

  /// Erro durante o pull, ou null se o pull foi bem-sucedido.
  final Object? pullError;

  @override
  String toString() =>
      'SyncResult(pushed=$pushed, pulled=$pulled, '
      'pushFailures=$pushFailures, pullError=$pullError)';
}

// ---------------------------------------------------------------------------
// VehicleSyncService
// ---------------------------------------------------------------------------

/// Motor de sincronização para veículos.
///
/// Ordem: **push primeiro** (envia o que ainda não subiu), **pull depois**
/// (recebe do servidor). Falhas em push não abortam o pull e vice-versa.
/// [sync] NUNCA lança exceção — sempre retorna [SyncResult].
class VehicleSyncService {
  VehicleSyncService({
    required VehicleSyncFacade facade,
    required RemoteVehicleSource remote,
  }) : _facade = facade,
       _remote = remote;

  final VehicleSyncFacade _facade;
  final RemoteVehicleSource _remote;

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
    for (final vehicle in pending) {
      try {
        await _remote.upsert(vehicle);
        await _facade.markSynced(vehicle.id);
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
        // Lê o veículo local incluindo soft-deletados, para comparar updated_at.
        final Vehicle? local = await _facade.getRawById(remote.id);

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

final vehicleSyncServiceProvider = Provider<VehicleSyncService>((ref) {
  final facade = ref.watch(vehicleSyncFacadeProvider);
  final remote = ref.watch(remoteVehicleSourceProvider);
  return VehicleSyncService(facade: facade, remote: remote);
});

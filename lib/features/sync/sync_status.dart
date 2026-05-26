import 'package:autolog/data/sync/vehicle_sync_service.dart';

/// Quatro estados de sync exibidos na UI.
///
/// Derivados de fatos observáveis: [pendingCount], [lastResult] e [isSyncing].
/// Não usa `connectivity_plus` — "offline" é inferido de falhas reais de sync.
enum SyncDisplayStatus { synced, pending, offline, syncing }

/// Função pura que deriva o status de sync a ser exibido na UI.
///
/// Prioridade (decrescente):
/// 1. [isSyncing] == true → [SyncDisplayStatus.syncing] (vence tudo).
/// 2. [lastResult] com pullError != null ou pushFailures > 0 → [SyncDisplayStatus.offline].
/// 3. [pendingCount] > 0 → [SyncDisplayStatus.pending].
/// 4. Caso contrário → [SyncDisplayStatus.synced].
SyncDisplayStatus deriveSyncStatus({
  required int pendingCount,
  SyncResult? lastResult,
  required bool isSyncing,
}) {
  if (isSyncing) return SyncDisplayStatus.syncing;

  if (lastResult != null &&
      (lastResult.pullError != null || lastResult.pushFailures > 0)) {
    return SyncDisplayStatus.offline;
  }

  if (pendingCount > 0) return SyncDisplayStatus.pending;

  return SyncDisplayStatus.synced;
}

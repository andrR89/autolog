import 'package:autolog/data/sync/vehicle_sync_service.dart';
import 'package:autolog/features/sync/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 1.4 — derivação pura do status de sync exibido na UI.
/// Spec: docs/specs/sprint-1.4-sync-indicator.md
void main() {
  group('deriveSyncStatus', () {
    test('isSyncing vence tudo', () {
      expect(
        deriveSyncStatus(pendingCount: 0, lastResult: null, isSyncing: true),
        SyncDisplayStatus.syncing,
      );
      expect(
        deriveSyncStatus(
          pendingCount: 5,
          lastResult: const SyncResult(pushed: 0, pulled: 0, pushFailures: 3),
          isSyncing: true,
        ),
        SyncDisplayStatus.syncing,
      );
    });

    test('pullError → offline', () {
      expect(
        deriveSyncStatus(
          pendingCount: 0,
          lastResult: SyncResult(
            pushed: 0,
            pulled: 0,
            pushFailures: 0,
            pullError: Exception('rede caiu'),
          ),
          isSyncing: false,
        ),
        SyncDisplayStatus.offline,
      );
    });

    test('pushFailures > 0 → offline', () {
      expect(
        deriveSyncStatus(
          pendingCount: 0,
          lastResult: const SyncResult(pushed: 0, pulled: 0, pushFailures: 2),
          isSyncing: false,
        ),
        SyncDisplayStatus.offline,
      );
    });

    test('sem erros, sem pending, sem syncing → synced', () {
      expect(
        deriveSyncStatus(
          pendingCount: 0,
          lastResult: const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
          isSyncing: false,
        ),
        SyncDisplayStatus.synced,
      );
      // lastResult null também conta como synced (nunca sincronizou ainda).
      expect(
        deriveSyncStatus(pendingCount: 0, lastResult: null, isSyncing: false),
        SyncDisplayStatus.synced,
      );
    });

    test('pending > 0 sem erros, sem syncing → pending', () {
      expect(
        deriveSyncStatus(pendingCount: 3, lastResult: null, isSyncing: false),
        SyncDisplayStatus.pending,
      );
      expect(
        deriveSyncStatus(
          pendingCount: 1,
          lastResult: const SyncResult(pushed: 5, pulled: 2, pushFailures: 0),
          isSyncing: false,
        ),
        SyncDisplayStatus.pending,
      );
    });
  });
}

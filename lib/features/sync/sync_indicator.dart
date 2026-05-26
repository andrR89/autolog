import 'package:autolog/features/sync/sync_status.dart';
import 'package:autolog/features/sync/sync_status_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indicador de status de sync para a AppBar.
///
/// Exibe um ícone/indicador reativo ao estado de sincronização e,
/// ao toque (exceto em [SyncDisplayStatus.syncing]), dispara [triggerSync].
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    switch (state.status) {
      case SyncDisplayStatus.syncing:
        return Tooltip(
          message: 'Sincronizando…',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        );

      case SyncDisplayStatus.synced:
        return IconButton(
          icon: Icon(Icons.cloud_done, color: colorScheme.primary),
          tooltip: 'Sincronizado',
          onPressed: () => ref.read(syncStatusProvider.notifier).triggerSync(),
        );

      case SyncDisplayStatus.pending:
        return IconButton(
          icon: const Icon(Icons.cloud_upload),
          tooltip: 'Aguardando sincronizar',
          onPressed: () => ref.read(syncStatusProvider.notifier).triggerSync(),
        );

      case SyncDisplayStatus.offline:
        return IconButton(
          icon: Icon(Icons.cloud_off, color: colorScheme.error),
          tooltip: 'Sem conexão — toque pra tentar',
          onPressed: () => ref.read(syncStatusProvider.notifier).triggerSync(),
        );
    }
  }
}

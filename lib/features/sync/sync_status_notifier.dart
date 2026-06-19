import 'dart:async';

import 'package:autolog/data/sync/expense_sync_facade.dart';
import 'package:autolog/data/sync/fine_sync_facade.dart';
import 'package:autolog/data/sync/fuel_entry_sync_facade.dart';
import 'package:autolog/data/sync/insurance_sync_facade.dart';
import 'package:autolog/data/sync/reminder_sync_facade.dart';
import 'package:autolog/data/sync/sync_service.dart';
import 'package:autolog/data/sync/user_profile_sync_facade.dart';
import 'package:autolog/data/sync/vehicle_sync_facade.dart';
import 'package:autolog/data/sync/vehicle_sync_service.dart';
import 'package:autolog/features/sync/sync_status.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado imutável do indicador de sync.
class SyncStatusState {
  const SyncStatusState({required this.status, this.lastResult});

  final SyncDisplayStatus status;
  final SyncResult? lastResult;

  SyncStatusState copyWith({
    SyncDisplayStatus? status,
    SyncResult? lastResult,
    bool clearLastResult = false,
  }) {
    return SyncStatusState(
      status: status ?? this.status,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
    );
  }
}

/// Notifier que mantém o estado do indicador de sync e expõe [triggerSync].
class SyncStatusNotifier extends Notifier<SyncStatusState> {
  // Uma subscription por entidade:
  // [vehicles, user_profile, fuel, expenses, reminders, fines, insurances].
  final List<StreamSubscription<int>?> _pendingSubs = [
    null,
    null,
    null,
    null,
    null,
    null,
    null,
  ];

  // Contagem de pending por entidade (mesma ordem das subs).
  final List<int> _pendingCounts = [0, 0, 0, 0, 0, 0, 0];

  bool _isSyncing = false;

  int get _totalPending => _pendingCounts.fold(0, (a, b) => a + b);

  @override
  SyncStatusState build() {
    final userId = ref.read(currentUserIdProvider);
    final vehicleFacade = ref.read(vehicleSyncFacadeProvider);
    final userProfileFacade = ref.read(userProfileSyncFacadeProvider);
    final fuelFacade = ref.read(fuelEntrySyncFacadeProvider);
    final expenseFacade = ref.read(expenseSyncFacadeProvider);
    final reminderFacade = ref.read(reminderSyncFacadeProvider);
    final fineFacade = ref.read(fineSyncFacadeProvider);
    final insuranceFacade = ref.read(insuranceSyncFacadeProvider);

    // Cancela subscriptions anteriores ao reconstruir (por invalidação).
    for (var i = 0; i < _pendingSubs.length; i++) {
      _pendingSubs[i]?.cancel();
      _pendingSubs[i] = null;
    }

    void onCount(int index, int count) {
      _pendingCounts[index] = count;
      state = SyncStatusState(
        status: deriveSyncStatus(
          pendingCount: _totalPending,
          lastResult: state.lastResult,
          isSyncing: _isSyncing,
        ),
        lastResult: state.lastResult,
      );
    }

    _pendingSubs[0] =
        vehicleFacade.watchPendingCount(userId).listen((c) => onCount(0, c));
    _pendingSubs[1] =
        userProfileFacade
            .watchPendingCount(userId)
            .listen((c) => onCount(1, c));
    _pendingSubs[2] =
        fuelFacade.watchPendingCount(userId).listen((c) => onCount(2, c));
    _pendingSubs[3] =
        expenseFacade.watchPendingCount(userId).listen((c) => onCount(3, c));
    _pendingSubs[4] =
        reminderFacade.watchPendingCount(userId).listen((c) => onCount(4, c));
    _pendingSubs[5] =
        fineFacade.watchPendingCount(userId).listen((c) => onCount(5, c));
    _pendingSubs[6] =
        insuranceFacade.watchPendingCount(userId).listen((c) => onCount(6, c));

    // Cancela todas as subscriptions quando o provider for disposto.
    ref.onDispose(() {
      for (final sub in _pendingSubs) {
        sub?.cancel();
      }
    });

    return const SyncStatusState(status: SyncDisplayStatus.synced);
  }

  /// Dispara um ciclo de sync para o usuário autenticado.
  ///
  /// Nunca lança — erros são refletidos no estado como [SyncDisplayStatus.offline].
  Future<void> triggerSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    state = SyncStatusState(
      status: deriveSyncStatus(
        pendingCount: _totalPending,
        lastResult: state.lastResult,
        isSyncing: _isSyncing,
      ),
      lastResult: state.lastResult,
    );

    SyncResult? result;
    try {
      final userId = ref.read(currentUserIdProvider);
      final globalService = ref.read(globalSyncServiceProvider);
      final globalResult = await globalService.sync(userId);

      // Mapeia GlobalSyncResult → SyncResult sintético para manter API pública.
      // Anexa a mensagem do primeiro erro real ao wrapper — sem isso, o
      // snackbar diagnóstico só mostra os nomes das entidades e a causa-raiz
      // (RLS, schema, PostgrestException) fica perdida.
      Object? wrappedError;
      if (globalResult.errors.isNotEmpty) {
        final firstKey = globalResult.errors.keys.first;
        final firstErr = globalResult.errors[firstKey];
        wrappedError = StateError(
          'sync errors: ${globalResult.errors.keys.join(", ")} '
          '— $firstKey: $firstErr',
        );
      }
      result = SyncResult(
        pushed: globalResult.totalPushed,
        pulled: globalResult.totalPulled,
        pushFailures: globalResult.totalPushFailures,
        pullError: wrappedError,
      );
    } catch (e) {
      // O GlobalSyncService nunca deveria lançar, mas como precaução geramos
      // um SyncResult sintético que indica falha.
      result = SyncResult(pushed: 0, pulled: 0, pushFailures: 0, pullError: e);
    } finally {
      _isSyncing = false;
      state = SyncStatusState(
        status: deriveSyncStatus(
          pendingCount: _totalPending,
          lastResult: result,
          isSyncing: false,
        ),
        lastResult: result,
      );
    }
  }
}

/// Provider do indicador de status de sync.
final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatusState>(
      SyncStatusNotifier.new,
    );

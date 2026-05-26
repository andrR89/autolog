import 'dart:async';

import 'package:autolog/data/sync/expense_sync_facade.dart';
import 'package:autolog/data/sync/expense_sync_service.dart';
import 'package:autolog/data/sync/fine_sync_facade.dart';
import 'package:autolog/data/sync/fine_sync_service.dart';
import 'package:autolog/data/sync/fuel_entry_sync_facade.dart';
import 'package:autolog/data/sync/fuel_entry_sync_service.dart';
import 'package:autolog/data/sync/insurance_sync_facade.dart';
import 'package:autolog/data/sync/insurance_sync_service.dart';
import 'package:autolog/data/sync/reminder_sync_facade.dart';
import 'package:autolog/data/sync/reminder_sync_service.dart';
import 'package:autolog/data/sync/sync_service.dart';
import 'package:autolog/data/sync/user_profile_sync_facade.dart';
import 'package:autolog/data/sync/user_profile_sync_service.dart';
import 'package:autolog/data/sync/vehicle_sync_facade.dart';
import 'package:autolog/data/sync/vehicle_sync_service.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/sync/sync_status.dart';
import 'package:autolog/features/sync/sync_status_notifier.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.D-orchestrator — SyncStatusNotifier atualizado.
/// Agora usa GlobalSyncService e 4 façades de pending.

// ---------------------------------------------------------------------------
// Fake Vehicle façade (alimenta stream de pendingCount)
// ---------------------------------------------------------------------------

class _FakeVehicleFacade implements VehicleSyncFacade {
  // ignore: close_sinks  // fechado no tearDown
  final StreamController<int> pendingCtrl = StreamController<int>.broadcast();

  @override
  Stream<int> watchPendingCount(String userId) => pendingCtrl.stream;

  // Métodos não usados pelo notifier — stubs.
  @override
  Future<List<Vehicle>> listPending(String userId) async => const [];
  @override
  Future<void> markSynced(String id) async {}
  @override
  Future<void> upsertFromRemote(Vehicle remote) async {}
  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async => null;
  @override
  Future<Vehicle?> getRawById(String id) async => null;
}

// ---------------------------------------------------------------------------
// Fake Fuel Entry façade
// ---------------------------------------------------------------------------

class _FakeFuelFacade implements FuelEntrySyncFacade {
  // ignore: close_sinks
  final StreamController<int> pendingCtrl = StreamController<int>.broadcast();

  @override
  Stream<int> watchPendingCount(String userId) => pendingCtrl.stream;

  @override
  Future<List<FuelEntry>> listPending(String userId) async => const [];
  @override
  Future<void> markSynced(String id) async {}
  @override
  Future<void> upsertFromRemote(FuelEntry remote) async {}
  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async => null;
  @override
  Future<FuelEntry?> getRawById(String id) async => null;
}

// ---------------------------------------------------------------------------
// Fake Expense façade
// ---------------------------------------------------------------------------

class _FakeExpenseFacade implements ExpenseSyncFacade {
  // ignore: close_sinks
  final StreamController<int> pendingCtrl = StreamController<int>.broadcast();

  @override
  Stream<int> watchPendingCount(String userId) => pendingCtrl.stream;

  @override
  Future<List<Expense>> listPending(String userId) async => const [];
  @override
  Future<void> markSynced(String id) async {}
  @override
  Future<void> upsertFromRemote(Expense remote) async {}
  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async => null;
  @override
  Future<Expense?> getById(String id) async => null;
  @override
  Future<int> countPending(String userId) async => 0;
}

// ---------------------------------------------------------------------------
// Fake Reminder façade
// ---------------------------------------------------------------------------

class _FakeReminderFacade implements ReminderSyncFacade {
  // ignore: close_sinks
  final StreamController<int> pendingCtrl = StreamController<int>.broadcast();

  @override
  Stream<int> watchPendingCount(String userId) => pendingCtrl.stream;

  @override
  Future<List<Reminder>> listPending(String userId) async => const [];
  @override
  Future<void> markSynced(String id) async {}
  @override
  Future<void> upsertFromRemote(Reminder remote) async {}
  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async => null;
  @override
  Future<Reminder?> getById(String id) async => null;
  @override
  Future<int> countPending(String userId) async => 0;
}

// ---------------------------------------------------------------------------
// Fake UserProfile façade
// ---------------------------------------------------------------------------

class _FakeUserProfileFacade implements UserProfileSyncFacade {
  // ignore: close_sinks
  final StreamController<int> pendingCtrl = StreamController<int>.broadcast();

  @override
  Stream<int> watchPendingCount(String userId) => pendingCtrl.stream;

  @override
  Future<List<UserProfile>> listPending(String userId) async => const [];
  @override
  Future<void> markSynced(String userId) async {}
  @override
  Future<void> upsertFromRemote(UserProfile remote) async {}
  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async => null;
  @override
  Future<UserProfile?> getById(String userId) async => null;
  @override
  Future<int> countPending(String userId) async => 0;
}

// ---------------------------------------------------------------------------
// Fake Fine façade
// ---------------------------------------------------------------------------

class _FakeFineFacade implements FineSyncFacade {
  // ignore: close_sinks
  final StreamController<int> pendingCtrl = StreamController<int>.broadcast();

  @override
  Stream<int> watchPendingCount(String userId) => pendingCtrl.stream;

  @override
  Future<List<Fine>> listPending(String userId) async => const [];
  @override
  Future<void> markSynced(String id) async {}
  @override
  Future<void> upsertFromRemote(Fine remote) async {}
  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async => null;
  @override
  Future<Fine?> getById(String id) async => null;
  @override
  Future<int> countPending(String userId) async => 0;
}

// ---------------------------------------------------------------------------
// Fake Insurance façade
// ---------------------------------------------------------------------------

class _FakeInsuranceFacade implements InsuranceSyncFacade {
  // ignore: close_sinks
  final StreamController<int> pendingCtrl = StreamController<int>.broadcast();

  @override
  Stream<int> watchPendingCount(String userId) => pendingCtrl.stream;

  @override
  Future<List<Insurance>> listPending(String userId) async => const [];
  @override
  Future<void> markSynced(String id) async {}
  @override
  Future<void> upsertFromRemote(Insurance remote) async {}
  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async => null;
  @override
  Future<Insurance?> getById(String id) async => null;
  @override
  Future<int> countPending(String userId) async => 0;
}

// ---------------------------------------------------------------------------
// Fake services (para compor o GlobalSyncService)
// ---------------------------------------------------------------------------

/// Fake VehicleSyncService controlável — resultado configurável.
class _FakeVehicleService implements VehicleSyncService {
  SyncResult result = const SyncResult(pushed: 0, pulled: 0, pushFailures: 0);
  Object? throwOnSync;
  int callCount = 0;

  @override
  Future<SyncResult> sync(String userId) async {
    callCount++;
    if (throwOnSync != null) throw throwOnSync!;
    return result;
  }
}

/// Stub de FuelEntrySyncService — sempre retorna resultado vazio.
class _FakeFuelService implements FuelEntrySyncService {
  @override
  Future<SyncResult> sync(String userId) async =>
      const SyncResult(pushed: 0, pulled: 0, pushFailures: 0);
}

/// Stub de ExpenseSyncService — sempre retorna resultado vazio.
class _FakeExpenseService implements ExpenseSyncService {
  @override
  Future<SyncResult> sync(String userId) async =>
      const SyncResult(pushed: 0, pulled: 0, pushFailures: 0);
}

/// Stub de ReminderSyncService — sempre retorna resultado vazio.
class _FakeReminderService implements ReminderSyncService {
  @override
  Future<SyncResult> sync(String userId) async =>
      const SyncResult(pushed: 0, pulled: 0, pushFailures: 0);
}

/// Stub de UserProfileSyncService — sempre retorna resultado vazio.
class _FakeUserProfileService implements UserProfileSyncService {
  @override
  Future<SyncResult> sync(String userId) async =>
      const SyncResult(pushed: 0, pulled: 0, pushFailures: 0);
}

/// Stub de FineSyncService — sempre retorna resultado vazio.
class _FakeFineService implements FineSyncService {
  @override
  Future<SyncResult> sync(String userId) async =>
      const SyncResult(pushed: 0, pulled: 0, pushFailures: 0);
}

/// Stub de InsuranceSyncService — sempre retorna resultado vazio.
class _FakeInsuranceService implements InsuranceSyncService {
  @override
  Future<SyncResult> sync(String userId) async =>
      const SyncResult(pushed: 0, pulled: 0, pushFailures: 0);
}

void main() {
  late _FakeVehicleFacade vehicleFacade;
  late _FakeFuelFacade fuelFacade;
  late _FakeExpenseFacade expenseFacade;
  late _FakeReminderFacade reminderFacade;
  late _FakeUserProfileFacade userProfileFacade;
  late _FakeFineFacade fineFacade;
  late _FakeInsuranceFacade insuranceFacade;
  late _FakeVehicleService vehicleService;
  late ProviderContainer container;

  GlobalSyncService buildGlobalService() => GlobalSyncService(
    vehicle: vehicleService,
    userProfile: _FakeUserProfileService(),
    fuel: _FakeFuelService(),
    expense: _FakeExpenseService(),
    reminder: _FakeReminderService(),
    fine: _FakeFineService(),
    insurance: _FakeInsuranceService(),
  );

  setUp(() {
    vehicleFacade = _FakeVehicleFacade();
    fuelFacade = _FakeFuelFacade();
    expenseFacade = _FakeExpenseFacade();
    reminderFacade = _FakeReminderFacade();
    userProfileFacade = _FakeUserProfileFacade();
    fineFacade = _FakeFineFacade();
    insuranceFacade = _FakeInsuranceFacade();
    vehicleService = _FakeVehicleService();

    container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('u1'),
        vehicleSyncFacadeProvider.overrideWithValue(vehicleFacade),
        fuelEntrySyncFacadeProvider.overrideWithValue(fuelFacade),
        expenseSyncFacadeProvider.overrideWithValue(expenseFacade),
        reminderSyncFacadeProvider.overrideWithValue(reminderFacade),
        userProfileSyncFacadeProvider.overrideWithValue(userProfileFacade),
        fineSyncFacadeProvider.overrideWithValue(fineFacade),
        insuranceSyncFacadeProvider.overrideWithValue(insuranceFacade),
        // GlobalSyncService usa vehicleService configurável.
        globalSyncServiceProvider.overrideWith(
          (ref) => buildGlobalService(),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    vehicleFacade.pendingCtrl.close();
    fuelFacade.pendingCtrl.close();
    expenseFacade.pendingCtrl.close();
    reminderFacade.pendingCtrl.close();
    userProfileFacade.pendingCtrl.close();
    fineFacade.pendingCtrl.close();
    insuranceFacade.pendingCtrl.close();
  });

  test('inicial: pendingCount=0 → synced', () async {
    // Lê pra inicializar o notifier.
    container.read(syncStatusProvider);
    vehicleFacade.pendingCtrl.add(0);
    await Future<void>.delayed(Duration.zero);
    final state = container.read(syncStatusProvider);
    expect(state.status, SyncDisplayStatus.synced);
  });

  test('pending detectado: stream emite 2 → status pending', () async {
    container.read(syncStatusProvider);
    vehicleFacade.pendingCtrl.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(syncStatusProvider).status,
      SyncDisplayStatus.pending,
    );
  });

  test('triggerSync sucesso (sem pendentes depois) → synced final', () async {
    container.read(syncStatusProvider);
    vehicleFacade.pendingCtrl.add(0);
    await Future<void>.delayed(Duration.zero);

    await container.read(syncStatusProvider.notifier).triggerSync();
    expect(vehicleService.callCount, 1);

    final s = container.read(syncStatusProvider);
    expect(s.status, SyncDisplayStatus.synced);
    expect(s.lastResult, isNotNull);
  });

  test('triggerSync com pullError → offline', () async {
    container.read(syncStatusProvider);
    vehicleFacade.pendingCtrl.add(0);
    await Future<void>.delayed(Duration.zero);

    // Simula pullError no vehicle service (mantém semântica do teste original).
    vehicleService.result = SyncResult(
      pushed: 0,
      pulled: 0,
      pushFailures: 0,
      pullError: Exception('rede'),
    );

    await container.read(syncStatusProvider.notifier).triggerSync();
    expect(
      container.read(syncStatusProvider).status,
      SyncDisplayStatus.offline,
    );
  });

  test('triggerSync com pushFailures → offline', () async {
    container.read(syncStatusProvider);
    vehicleFacade.pendingCtrl.add(0);
    await Future<void>.delayed(Duration.zero);

    vehicleService.result =
        const SyncResult(pushed: 1, pulled: 0, pushFailures: 1);

    await container.read(syncStatusProvider.notifier).triggerSync();
    expect(
      container.read(syncStatusProvider).status,
      SyncDisplayStatus.offline,
    );
  });

  test('triggerSync nunca lança mesmo se o service falhar', () async {
    container.read(syncStatusProvider);
    vehicleFacade.pendingCtrl.add(0);
    await Future<void>.delayed(Duration.zero);

    vehicleService.throwOnSync = StateError('boom');

    // Não deve lançar.
    await container.read(syncStatusProvider.notifier).triggerSync();

    // Status após falha deve refletir um problema (offline é razoável).
    expect(
      container.read(syncStatusProvider).status,
      SyncDisplayStatus.offline,
    );
  });
}

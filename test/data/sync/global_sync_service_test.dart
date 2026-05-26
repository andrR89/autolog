import 'package:autolog/data/sync/expense_sync_service.dart';
import 'package:autolog/data/sync/fine_sync_service.dart';
import 'package:autolog/data/sync/fuel_entry_sync_service.dart';
import 'package:autolog/data/sync/insurance_sync_service.dart';
import 'package:autolog/data/sync/reminder_sync_service.dart';
import 'package:autolog/data/sync/sync_service.dart';
import 'package:autolog/data/sync/user_profile_sync_service.dart';
import 'package:autolog/data/sync/vehicle_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 6.D-orchestrator — GlobalSyncService.
/// Orquestra os 7 services e expõe SyncResult agregado.
///
/// Regras:
/// - Ordem: vehicles primeiro (FKs), depois demais.
/// - Falha (exception) num service não interrompe os outros.
/// - GlobalSyncResult agrega pushed/pulled/pushFailures e errors por entidade.

class _FakeVehicleSync implements VehicleSyncService {
  _FakeVehicleSync(this._result, {this.throwOnSync});
  final SyncResult _result;
  final Object? throwOnSync;
  int calls = 0;
  DateTime? calledAt;

  @override
  Future<SyncResult> sync(String userId) async {
    calls++;
    calledAt = DateTime.now();
    if (throwOnSync != null) throw throwOnSync!;
    return _result;
  }
}

class _FakeFuelSync implements FuelEntrySyncService {
  // ignore: unused_element_parameter
  _FakeFuelSync(this._result, {this.throwOnSync});
  final SyncResult _result;
  final Object? throwOnSync;
  int calls = 0;
  DateTime? calledAt;

  @override
  Future<SyncResult> sync(String userId) async {
    calls++;
    calledAt = DateTime.now();
    if (throwOnSync != null) throw throwOnSync!;
    return _result;
  }
}

class _FakeExpenseSync implements ExpenseSyncService {
  _FakeExpenseSync(this._result, {this.throwOnSync});
  final SyncResult _result;
  final Object? throwOnSync;
  int calls = 0;
  DateTime? calledAt;

  @override
  Future<SyncResult> sync(String userId) async {
    calls++;
    calledAt = DateTime.now();
    if (throwOnSync != null) throw throwOnSync!;
    return _result;
  }
}

class _FakeReminderSync implements ReminderSyncService {
  // ignore: unused_element_parameter
  _FakeReminderSync(this._result, {this.throwOnSync});
  final SyncResult _result;
  final Object? throwOnSync;
  int calls = 0;
  DateTime? calledAt;

  @override
  Future<SyncResult> sync(String userId) async {
    calls++;
    calledAt = DateTime.now();
    if (throwOnSync != null) throw throwOnSync!;
    return _result;
  }
}

class _FakeUserProfileSync implements UserProfileSyncService {
  _FakeUserProfileSync(this._result);
  final SyncResult _result;
  int calls = 0;

  @override
  Future<SyncResult> sync(String userId) async {
    calls++;
    return _result;
  }
}

class _FakeFineSync implements FineSyncService {
  _FakeFineSync(this._result);
  final SyncResult _result;
  int calls = 0;

  @override
  Future<SyncResult> sync(String userId) async {
    calls++;
    return _result;
  }
}

class _FakeInsuranceSync implements InsuranceSyncService {
  _FakeInsuranceSync(this._result);
  final SyncResult _result;
  int calls = 0;

  @override
  Future<SyncResult> sync(String userId) async {
    calls++;
    return _result;
  }
}

void main() {
  group('GlobalSyncService.sync', () {
    test('chama os 4 services e agrega totais', () async {
      final v = _FakeVehicleSync(
        const SyncResult(pushed: 1, pulled: 2, pushFailures: 0),
      );
      final f = _FakeFuelSync(
        const SyncResult(pushed: 3, pulled: 0, pushFailures: 0),
      );
      final e = _FakeExpenseSync(
        const SyncResult(pushed: 0, pulled: 5, pushFailures: 1),
      );
      final r = _FakeReminderSync(
        const SyncResult(pushed: 2, pulled: 1, pushFailures: 0),
      );
      final svc = GlobalSyncService(
        vehicle: v,
        userProfile: _FakeUserProfileSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        fuel: f, expense: e, reminder: r,
        fine: _FakeFineSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        insurance: _FakeInsuranceSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
      );

      final result = await svc.sync('u1');

      expect(v.calls, 1);
      expect(f.calls, 1);
      expect(e.calls, 1);
      expect(r.calls, 1);
      expect(result.totalPushed, 6);
      expect(result.totalPulled, 8);
      expect(result.totalPushFailures, 1);
      expect(result.errors, isEmpty);
    });

    test('vehicles executa antes dos demais (ordem por FK)', () async {
      final v = _FakeVehicleSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final f = _FakeFuelSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final e = _FakeExpenseSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final r = _FakeReminderSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final svc = GlobalSyncService(
        vehicle: v,
        userProfile: _FakeUserProfileSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        fuel: f, expense: e, reminder: r,
        fine: _FakeFineSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        insurance: _FakeInsuranceSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
      );

      await svc.sync('u1');

      expect(v.calledAt!.isBefore(f.calledAt!) ||
          v.calledAt!.isAtSameMomentAs(f.calledAt!), isTrue);
      expect(v.calledAt!.isBefore(e.calledAt!) ||
          v.calledAt!.isAtSameMomentAs(e.calledAt!), isTrue);
      expect(v.calledAt!.isBefore(r.calledAt!) ||
          v.calledAt!.isAtSameMomentAs(r.calledAt!), isTrue);
    });

    test('exceção num service não interrompe os outros', () async {
      final v = _FakeVehicleSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
        throwOnSync: Exception('vehicle boom'),
      );
      final f = _FakeFuelSync(
        const SyncResult(pushed: 1, pulled: 0, pushFailures: 0),
      );
      final e = _FakeExpenseSync(
        const SyncResult(pushed: 0, pulled: 2, pushFailures: 0),
        throwOnSync: Exception('expense boom'),
      );
      final r = _FakeReminderSync(
        const SyncResult(pushed: 0, pulled: 1, pushFailures: 0),
      );
      final svc = GlobalSyncService(
        vehicle: v,
        userProfile: _FakeUserProfileSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        fuel: f, expense: e, reminder: r,
        fine: _FakeFineSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        insurance: _FakeInsuranceSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
      );

      final result = await svc.sync('u1');

      expect(v.calls, 1);
      expect(f.calls, 1);
      expect(e.calls, 1);
      expect(r.calls, 1);
      expect(result.totalPushed, 1);
      expect(result.totalPulled, 1);
      expect(result.errors.length, 2);
      expect(result.errors.keys, containsAll(['vehicles', 'expenses']));
    });

    test('pullError dos services contam como erro agregado', () async {
      final v = _FakeVehicleSync(
        SyncResult(pushed: 0, pulled: 0, pushFailures: 0,
            pullError: Exception('net')),
      );
      final f = _FakeFuelSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final e = _FakeExpenseSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final r = _FakeReminderSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final svc = GlobalSyncService(
        vehicle: v,
        userProfile: _FakeUserProfileSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        fuel: f, expense: e, reminder: r,
        fine: _FakeFineSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        insurance: _FakeInsuranceSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
      );

      final result = await svc.sync('u1');
      expect(result.errors.keys, ['vehicles']);
    });

    test('hasFailures: true se houve push failures', () async {
      final v = _FakeVehicleSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 1),
      );
      final f = _FakeFuelSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final e = _FakeExpenseSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final r = _FakeReminderSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final svc = GlobalSyncService(
        vehicle: v,
        userProfile: _FakeUserProfileSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        fuel: f, expense: e, reminder: r,
        fine: _FakeFineSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        insurance: _FakeInsuranceSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
      );

      final result = await svc.sync('u1');
      expect(result.hasFailures, isTrue);
    });

    test('hasFailures: true se houve qualquer erro', () async {
      final v = _FakeVehicleSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
        throwOnSync: Exception('x'),
      );
      final f = _FakeFuelSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final e = _FakeExpenseSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final r = _FakeReminderSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final svc = GlobalSyncService(
        vehicle: v,
        userProfile: _FakeUserProfileSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        fuel: f, expense: e, reminder: r,
        fine: _FakeFineSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        insurance: _FakeInsuranceSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
      );

      final result = await svc.sync('u1');
      expect(result.hasFailures, isTrue);
    });

    test('hasFailures: false em sync totalmente limpo', () async {
      final v = _FakeVehicleSync(
        const SyncResult(pushed: 2, pulled: 3, pushFailures: 0),
      );
      final f = _FakeFuelSync(
        const SyncResult(pushed: 1, pulled: 0, pushFailures: 0),
      );
      final e = _FakeExpenseSync(
        const SyncResult(pushed: 0, pulled: 1, pushFailures: 0),
      );
      final r = _FakeReminderSync(
        const SyncResult(pushed: 0, pulled: 0, pushFailures: 0),
      );
      final svc = GlobalSyncService(
        vehicle: v,
        userProfile: _FakeUserProfileSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        fuel: f, expense: e, reminder: r,
        fine: _FakeFineSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
        insurance: _FakeInsuranceSync(const SyncResult(pushed: 0, pulled: 0, pushFailures: 0)),
      );

      final result = await svc.sync('u1');
      expect(result.hasFailures, isFalse);
    });
  });
}

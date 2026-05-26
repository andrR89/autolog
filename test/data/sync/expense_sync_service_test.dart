import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/data/sync/expense_sync_facade.dart';
import 'package:autolog/data/sync/expense_sync_service.dart';
import 'package:autolog/data/sync/remote_expense_source.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/expense_repository.dart' as edomain;
import 'package:autolog/domain/repositories/vehicle_repository.dart' as vdomain;
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 6.D-expenses — ExpenseSyncService (mirror de 1.2 / 6.D-fuel).
/// Spec: ver 6.D-fuel; mesmas regras adaptadas pra expenses.

class FakeRemoteExpenseSource implements RemoteExpenseSource {
  final Map<String, Expense> store = {};
  DateTime? lastFetchSince;
  String? lastFetchUserId;
  int fetchCallCount = 0;
  Set<String> failUpsertForIds = {};
  bool throwOnFetch = false;
  bool ignoreSince = false;

  void seed(Expense e) => store[e.id] = e;

  @override
  Future<void> upsert(Expense expense) async {
    if (failUpsertForIds.contains(expense.id)) {
      throw Exception('fake upsert failure for ${expense.id}');
    }
    store[expense.id] = expense;
  }

  @override
  Future<List<Expense>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    fetchCallCount++;
    lastFetchUserId = userId;
    lastFetchSince = since;
    if (throwOnFetch) throw Exception('fake fetch failure');
    final filtered = (since == null || ignoreSince)
        ? store.values
        : store.values.where((e) => e.updatedAt.isAfter(since));
    final list = filtered.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return list;
  }
}

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late vdomain.VehicleRepository vehicleRepo;
  late edomain.ExpenseRepository expenseRepo;
  late ExpenseSyncFacade facade;
  late FakeRemoteExpenseSource remote;
  late ExpenseSyncService sync;

  DateTime now() => fakeNow;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 25, 10);
    vehicleRepo = DriftVehicleRepository(db, now: now);
    expenseRepo = DriftExpenseRepository(db, now: now);
    facade = DriftExpenseSyncFacade(db);
    remote = FakeRemoteExpenseSource();
    sync = ExpenseSyncService(facade: facade, remote: remote);

    await vehicleRepo.create(Vehicle(
      id: 'v1',
      userId: 'u1',
      nickname: 'Civic',
      fuelType: FuelType.gasolina,
      initialOdometer: 10000,
      createdAt: DateTime.utc(2000),
      updatedAt: DateTime.utc(2000),
      syncStatus: SyncStatus.synced,
    ));
  });

  tearDown(() => db.close());

  Expense sample({
    String id = 'e1',
    String vehicleId = 'v1',
    DateTime? date,
    DateTime? updatedAt,
    String amount = '100',
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? deletedAt,
  }) {
    final d = date ?? fakeNow;
    return Expense(
      id: id,
      vehicleId: vehicleId,
      date: d,
      category: ExpenseCategory.manutencao,
      description: 'X',
      amount: Decimal.parse(amount),
      createdAt: d,
      updatedAt: updatedAt ?? d,
      syncStatus: syncStatus,
      deletedAt: deletedAt,
    );
  }

  group('push', () {
    test('envia pending, marca synced', () async {
      await expenseRepo.create(sample());
      final r = await sync.sync('u1');
      expect(remote.store['e1'], isNotNull);
      expect(r.pushed, 1);
      expect((await expenseRepo.getById('e1'))!.syncStatus, SyncStatus.synced);
    });

    test('propaga soft-delete', () async {
      await expenseRepo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 25, 11);
      await expenseRepo.softDelete('e1');
      await sync.sync('u1');
      expect(remote.store['e1']!.deletedAt, isNotNull);
      final raw = await (db.select(
        db.expenses,
      )..where((t) => t.id.equals('e1'))).getSingle();
      expect(raw.syncStatus, SyncStatus.synced);
    });

    test('falha parcial', () async {
      await expenseRepo.create(sample(id: 'e1'));
      await expenseRepo.create(sample(id: 'e2'));
      await expenseRepo.create(sample(id: 'e3'));
      remote.failUpsertForIds = {'e2'};
      final r = await sync.sync('u1');
      expect(r.pushed, 2);
      expect(r.pushFailures, 1);
      expect((await expenseRepo.getById('e2'))!.syncStatus, SyncStatus.pending);
    });
  });

  group('pull', () {
    test('insere novo como synced', () async {
      remote.seed(sample(id: 'e1', updatedAt: fakeNow));
      final r = await sync.sync('u1');
      expect((await expenseRepo.getById('e1'))!.syncStatus, SyncStatus.synced);
      expect(r.pulled, 1);
    });

    test('cursor incremental', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 11);
      remote.seed(sample(id: 'e1', updatedAt: t1));
      await sync.sync('u1');
      expect(remote.lastFetchSince, isNull);
      remote.seed(sample(id: 'e2', updatedAt: t2));
      final r2 = await sync.sync('u1');
      expect(remote.lastFetchSince, t1);
      expect(r2.pulled, 1);
    });

    test('cursor inicial null sem nada synced', () async {
      await sync.sync('u1');
      expect(remote.lastFetchSince, isNull);
    });
  });

  group('conflito (LWW)', () {
    test('remoto mais novo vence', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);
      await facade.upsertFromRemote(sample(
        id: 'e1',
        amount: '100',
        updatedAt: t1,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'e1', amount: '200', updatedAt: t2));
      final r = await sync.sync('u1');
      final local = await expenseRepo.getById('e1');
      expect(local!.amount, Decimal.parse('200'));
      expect(r.pulled, 1);
    });

    test('local mais novo preservado (guard LWW)', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);
      await facade.upsertFromRemote(sample(
        id: 'e1',
        amount: '200',
        updatedAt: t2,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'e1', amount: '100', updatedAt: t1));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await expenseRepo.getById('e1'))!.amount, Decimal.parse('200'));
      expect(r.pulled, 0);
    });

    test('empate updated_at: local vence', () async {
      final t = DateTime.utc(2026, 5, 25, 10);
      await facade.upsertFromRemote(sample(
        id: 'e1',
        amount: '100',
        updatedAt: t,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'e1', amount: '200', updatedAt: t));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await expenseRepo.getById('e1'))!.amount, Decimal.parse('100'));
      expect(r.pulled, 0);
    });
  });

  group('isolamento por user via JOIN com vehicles', () {
    test('expense de outro user NÃO aparece em listPending(u1)', () async {
      await vehicleRepo.create(Vehicle(
        id: 'v2',
        userId: 'u2',
        nickname: 'Outro',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2000),
        updatedAt: DateTime.utc(2000),
        syncStatus: SyncStatus.synced,
      ));
      await expenseRepo.create(sample(id: 'e_u1', vehicleId: 'v1'));
      await expenseRepo.create(sample(id: 'e_u2', vehicleId: 'v2'));

      expect((await facade.listPending('u1')).map((e) => e.id), ['e_u1']);
      expect((await facade.listPending('u2')).map((e) => e.id), ['e_u2']);
    });
  });

  group('erros', () {
    test('falha pull não vaza, push prévio preservado', () async {
      await expenseRepo.create(sample());
      remote.throwOnFetch = true;
      final r = await sync.sync('u1');
      expect(r.pushed, 1);
      expect(r.pulled, 0);
      expect(r.pullError, isNotNull);
      expect((await expenseRepo.getById('e1'))!.syncStatus, SyncStatus.synced);
    });
  });
}

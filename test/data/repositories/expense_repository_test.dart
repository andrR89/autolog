import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/repositories/expense_repository.dart' as domain;
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 4.1a — Repositório de expenses (CRUD local + soft delete).
/// Spec: docs/specs/sprint-4.1a-expense-repository.md
void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.ExpenseRepository repo;

  DateTime now() => fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 23, 10);
    repo = DriftExpenseRepository(db, now: now);
  });

  tearDown(() => db.close());

  Expense sample({
    String id = 'e1',
    String vehicleId = 'v1',
    DateTime? date,
    ExpenseCategory category = ExpenseCategory.manutencao,
    String description = 'Troca de óleo',
    Decimal? amount,
    int? odometer,
    SyncStatus syncStatus = SyncStatus.synced,
  }) {
    return Expense(
      id: id,
      vehicleId: vehicleId,
      date: date ?? fakeNow,
      category: category,
      description: description,
      amount: amount ?? Decimal.parse('150'),
      odometer: odometer,
      createdAt: DateTime.utc(2000),
      updatedAt: DateTime.utc(2000),
      syncStatus: syncStatus,
    );
  }

  group('create', () {
    test('insere, marca pending, define timestamps', () async {
      final saved = await repo.create(sample());

      expect(saved.id, 'e1');
      expect(saved.vehicleId, 'v1');
      expect(saved.syncStatus, SyncStatus.pending);
      expect(saved.createdAt, fakeNow);
      expect(saved.updatedAt, fakeNow);
      expect(saved.deletedAt, isNull);

      final got = await repo.getById('e1');
      expect(got, saved);
    });

    test('precisão decimal SAGRADA no amount — roundtrip exato', () async {
      final amount = Decimal.parse('1234.567');
      final saved = await repo.create(sample(amount: amount));
      expect(saved.amount, amount);

      final got = await repo.getById('e1');
      expect(got!.amount, amount);
    });

    test('caller mandando synced é sobrescrito para pending', () async {
      final saved = await repo.create(sample(syncStatus: SyncStatus.synced));
      expect(saved.syncStatus, SyncStatus.pending);
    });
  });

  group('update', () {
    test('bumpa updated_at, preserva createdAt, marca pending', () async {
      final created = await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 23, 11);

      final updated = await repo.update(
        created.copyWith(
          description: 'Troca de pneus',
          syncStatus: SyncStatus.synced,
        ),
      );

      expect(updated.description, 'Troca de pneus');
      expect(updated.createdAt, created.createdAt);
      expect(updated.updatedAt, fakeNow);
      expect(updated.syncStatus, SyncStatus.pending);
    });

    test('lança StateError quando id não existe', () async {
      expect(() => repo.update(sample(id: 'fantasma')), throwsStateError);
    });

    test('lança StateError quando soft-deletado', () async {
      await repo.create(sample());
      await repo.softDelete('e1');
      expect(
        () => repo.update(sample().copyWith(description: 'x')),
        throwsStateError,
      );
    });
  });

  group('softDelete', () {
    test('marca deleted_at e esconde dos reads', () async {
      await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 23, 12);
      await repo.softDelete('e1');
      expect(await repo.getById('e1'), isNull);
      expect(await repo.listByVehicle('v1'), isEmpty);
    });

    test('é idempotente — não sobrescreve deleted_at original', () async {
      await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 23, 12);
      await repo.softDelete('e1');

      final rawFirst = await (db.select(
        db.expenses,
      )..where((t) => t.id.equals('e1'))).getSingle();
      final firstDeletedAt = rawFirst.deletedAt;

      fakeNow = DateTime.utc(2026, 5, 23, 13);
      await repo.softDelete('e1');

      final rawSecond = await (db.select(
        db.expenses,
      )..where((t) => t.id.equals('e1'))).getSingle();
      expect(rawSecond.deletedAt, firstDeletedAt);
    });
  });

  group('listByVehicle', () {
    test('ordena por date DESC e exclui soft-deletados', () async {
      await repo.create(sample(id: 'e1', date: DateTime.utc(2026, 5, 20)));
      await repo.create(sample(id: 'e2', date: DateTime.utc(2026, 5, 22)));
      await repo.create(sample(id: 'e3', date: DateTime.utc(2026, 5, 21)));
      await repo.softDelete('e2');

      final list = await repo.listByVehicle('v1');
      expect(list.map((e) => e.id), ['e3', 'e1']);
    });

    test(
      'datas iguais: tiebreaker createdAt DESC (mais recente em cima)',
      () async {
        final sameDate = DateTime.utc(2026, 5, 23);

        fakeNow = DateTime.utc(2026, 5, 23, 10);
        await repo.create(sample(id: 'e1', date: sameDate));
        fakeNow = DateTime.utc(2026, 5, 23, 11);
        await repo.create(sample(id: 'e2', date: sameDate));
        fakeNow = DateTime.utc(2026, 5, 23, 12);
        await repo.create(sample(id: 'e3', date: sameDate));

        final list = await repo.listByVehicle('v1');
        expect(list.map((e) => e.id), ['e3', 'e2', 'e1']);
      },
    );

    test('isolamento por vehicleId', () async {
      await repo.create(sample(id: 'e1', vehicleId: 'v1'));
      await repo.create(sample(id: 'e2', vehicleId: 'v2'));

      expect((await repo.listByVehicle('v1')).map((e) => e.id), ['e1']);
      expect((await repo.listByVehicle('v2')).map((e) => e.id), ['e2']);
    });
  });

  group('watchByVehicle', () {
    test('emite inicial e em cada mutação', () async {
      final stream = repo.watchByVehicle('v1');

      final emissions = <List<String>>[];
      final sub = stream.listen((list) {
        emissions.add(list.map((e) => e.id).toList());
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));

      await repo.create(sample(id: 'e1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeNow = fakeNow.add(const Duration(minutes: 1));
      await repo.update(sample(id: 'e1').copyWith(description: 'editado'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeNow = fakeNow.add(const Duration(minutes: 1));
      await repo.softDelete('e1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(4));
      expect(emissions.first, isEmpty);
      expect(emissions[1], ['e1']);
      expect(emissions.last, isEmpty);
    });
  });
}

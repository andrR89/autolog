import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 4.2a — Repositório de reminders (CRUD local + soft delete).
/// Spec: docs/specs/sprint-4.2a-reminder-repository.md
void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.ReminderRepository repo;

  DateTime now() => fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 24, 10);
    repo = DriftReminderRepository(db, now: now);
  });

  tearDown(() => db.close());

  Reminder sample({
    String id = 'r1',
    String vehicleId = 'v1',
    ReminderType type = ReminderType.porKm,
    String title = 'Troca de óleo',
    int? dueKm = 50000,
    DateTime? dueDate,
    bool isDone = false,
    SyncStatus syncStatus = SyncStatus.synced,
  }) {
    return Reminder(
      id: id,
      vehicleId: vehicleId,
      type: type,
      title: title,
      dueKm: dueKm,
      dueDate: dueDate,
      isDone: isDone,
      createdAt: DateTime.utc(2000),
      updatedAt: DateTime.utc(2000),
      syncStatus: syncStatus,
    );
  }

  group('create', () {
    test('insere, marca pending, define timestamps', () async {
      final saved = await repo.create(sample());

      expect(saved.id, 'r1');
      expect(saved.syncStatus, SyncStatus.pending);
      expect(saved.createdAt, fakeNow);
      expect(saved.updatedAt, fakeNow);
      expect(saved.deletedAt, isNull);

      final got = await repo.getById('r1');
      expect(got, saved);
    });

    test('por_km com dueKm preserva no roundtrip', () async {
      final saved = await repo.create(
        sample(type: ReminderType.porKm, dueKm: 50000, dueDate: null),
      );
      expect(saved.type, ReminderType.porKm);
      expect(saved.dueKm, 50000);
      expect(saved.dueDate, isNull);
    });

    test('por_data com dueDate preserva no roundtrip', () async {
      final due = DateTime.utc(2026, 12, 31);
      final saved = await repo.create(
        sample(type: ReminderType.porData, dueKm: null, dueDate: due),
      );
      expect(saved.type, ReminderType.porData);
      expect(saved.dueDate, due);
      expect(saved.dueKm, isNull);
    });

    test('caller mandando synced é sobrescrito para pending', () async {
      final saved = await repo.create(sample(syncStatus: SyncStatus.synced));
      expect(saved.syncStatus, SyncStatus.pending);
    });
  });

  group('update', () {
    test('marcar isDone=true bumpa updated_at, preserva createdAt, '
        'marca pending', () async {
      final created = await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 24, 11);

      final updated = await repo.update(
        created.copyWith(isDone: true, syncStatus: SyncStatus.synced),
      );

      expect(updated.isDone, true);
      expect(updated.createdAt, created.createdAt);
      expect(updated.updatedAt, fakeNow);
      expect(updated.syncStatus, SyncStatus.pending);
    });

    test('lança StateError quando id não existe', () async {
      expect(() => repo.update(sample(id: 'fantasma')), throwsStateError);
    });

    test('lança StateError quando soft-deletado', () async {
      await repo.create(sample());
      await repo.softDelete('r1');
      expect(
        () => repo.update(sample().copyWith(title: 'x')),
        throwsStateError,
      );
    });
  });

  group('softDelete', () {
    test('marca deleted_at e esconde dos reads', () async {
      await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 24, 12);
      await repo.softDelete('r1');
      expect(await repo.getById('r1'), isNull);
      expect(await repo.listByVehicle('v1'), isEmpty);
    });

    test('é idempotente — não sobrescreve deleted_at original', () async {
      await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 24, 12);
      await repo.softDelete('r1');

      final rawFirst = await (db.select(
        db.reminders,
      )..where((t) => t.id.equals('r1'))).getSingle();
      final firstDeletedAt = rawFirst.deletedAt;

      fakeNow = DateTime.utc(2026, 5, 24, 13);
      await repo.softDelete('r1');

      final rawSecond = await (db.select(
        db.reminders,
      )..where((t) => t.id.equals('r1'))).getSingle();
      expect(rawSecond.deletedAt, firstDeletedAt);
    });
  });

  group('listByVehicle', () {
    test(
      'ordem: não-feitos primeiro (is_done ASC), depois createdAt DESC',
      () async {
        // r1: feito, criado primeiro.
        fakeNow = DateTime.utc(2026, 5, 24, 10);
        await repo.create(sample(id: 'r1', isDone: false));
        fakeNow = DateTime.utc(2026, 5, 24, 11);
        await repo.create(sample(id: 'r2', isDone: false));
        fakeNow = DateTime.utc(2026, 5, 24, 12);
        await repo.create(sample(id: 'r3', isDone: false));

        // Marca r1 como feito (vira o último no ordering).
        await repo.update((await repo.getById('r1'))!.copyWith(isDone: true));

        final list = await repo.listByVehicle('v1');
        // Não-feitos primeiro (r3, r2 por createdAt DESC), depois feitos (r1).
        expect(list.map((r) => r.id), ['r3', 'r2', 'r1']);
      },
    );

    test('isolamento por vehicleId', () async {
      await repo.create(sample(id: 'r1', vehicleId: 'v1'));
      await repo.create(sample(id: 'r2', vehicleId: 'v2'));
      expect((await repo.listByVehicle('v1')).map((r) => r.id), ['r1']);
      expect((await repo.listByVehicle('v2')).map((r) => r.id), ['r2']);
    });
  });

  group('watchByVehicle', () {
    test('emite inicial e em cada mutação', () async {
      final stream = repo.watchByVehicle('v1');

      final emissions = <List<String>>[];
      final sub = stream.listen((list) {
        emissions.add(list.map((r) => r.id).toList());
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));

      await repo.create(sample(id: 'r1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeNow = fakeNow.add(const Duration(minutes: 1));
      await repo.update(sample(id: 'r1').copyWith(title: 'editado'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeNow = fakeNow.add(const Duration(minutes: 1));
      await repo.softDelete('r1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(4));
      expect(emissions.first, isEmpty);
      expect(emissions[1], ['r1']);
      expect(emissions.last, isEmpty);
    });
  });
}

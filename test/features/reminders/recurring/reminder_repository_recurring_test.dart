// Sprint 6.MM — Testes de integração do repositório para recorrência.
//
// Cobre:
// - markDone cria próximo no banco quando há intervalo
// - markDone é idempotente (chamar duas vezes não cria dois próximos)
// - markDone sem intervalo não cria próximo
// - markDone em lembrete inexistente lança StateError
// - markDone em lembrete soft-deletado lança StateError

import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.ReminderRepository repo;
  int idCounter = 0;

  String nextId() => 'gen-${idCounter++}';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 29, 10, 0, 0);
    idCounter = 0;
    repo = DriftReminderRepository(db, now: () => fakeNow);
  });

  tearDown(() => db.close());

  Reminder sample({
    String id = 'r1',
    String vehicleId = 'v1',
    ReminderType type = ReminderType.porData,
    int? dueKm,
    DateTime? dueDate,
    int? intervalDays,
    int? intervalKm,
    bool isDone = false,
  }) {
    return Reminder(
      id: id,
      vehicleId: vehicleId,
      type: type,
      title: 'Revisão anual',
      dueKm: dueKm,
      dueDate: dueDate ?? DateTime.utc(2026, 6, 1),
      isDone: isDone,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      syncStatus: SyncStatus.synced,
      intervalDays: intervalDays,
      intervalKm: intervalKm,
    );
  }

  group('markDone — sem intervalo (one-shot)', () {
    test('marca como done sem criar próximo', () async {
      await repo.create(sample(id: 'r1', intervalDays: null));

      await repo.markDone('r1', now: fakeNow, generateId: nextId);

      final list = await repo.listByVehicle('v1');
      // Só o lembrete original (soft-deleted não aparece; done aparece).
      expect(list, hasLength(1));
      expect(list.single.id, 'r1');
      expect(list.single.isDone, true);
    });
  });

  group('markDone — com intervalDays', () {
    test('cria o próximo lembrete com dueDate somado', () async {
      final original = DateTime.utc(2026, 6, 1);
      await repo.create(sample(id: 'r1', dueDate: original, intervalDays: 365));

      await repo.markDone('r1', now: fakeNow, generateId: nextId);

      final list = await repo.listByVehicle('v1');
      expect(list, hasLength(2));

      final done = list.firstWhere((r) => r.isDone);
      final next = list.firstWhere((r) => !r.isDone);

      expect(done.id, 'r1');
      expect(next.isDone, false);
      expect(next.dueDate, DateTime.utc(2027, 6, 1));
      expect(next.intervalDays, 365);
      expect(next.parentReminderId, 'r1');
    });

    test('próximo herda title e vehicleId', () async {
      await repo.create(
        sample(id: 'r1', dueDate: DateTime.utc(2026, 6, 1), intervalDays: 30),
      );
      await repo.markDone('r1', now: fakeNow, generateId: nextId);

      final list = await repo.listByVehicle('v1');
      final next = list.firstWhere((r) => !r.isDone);
      expect(next.title, 'Revisão anual');
      expect(next.vehicleId, 'v1');
    });
  });

  group('markDone — com intervalKm', () {
    test('usa currentOdometerKm quando fornecido', () async {
      await repo.create(
        sample(
          id: 'r1',
          type: ReminderType.porKm,
          dueKm: 50000,
          dueDate: null,
          intervalKm: 10000,
        ),
      );

      await repo.markDone(
        'r1',
        currentOdometerKm: 51200,
        now: fakeNow,
        generateId: nextId,
      );

      final list = await repo.listByVehicle('v1');
      final next = list.firstWhere((r) => !r.isDone);
      expect(next.dueKm, 61200);
    });

    test(
      'usa fallback dueKm + intervalKm quando odômetro não fornecido',
      () async {
        await repo.create(
          sample(
            id: 'r1',
            type: ReminderType.porKm,
            dueKm: 50000,
            dueDate: null,
            intervalKm: 10000,
          ),
        );

        await repo.markDone('r1', now: fakeNow, generateId: nextId);

        final list = await repo.listByVehicle('v1');
        final next = list.firstWhere((r) => !r.isDone);
        expect(next.dueKm, 60000);
      },
    );
  });

  group('markDone — idempotência', () {
    test('chamar markDone duas vezes não cria dois próximos', () async {
      await repo.create(
        sample(id: 'r1', dueDate: DateTime.utc(2026, 6, 1), intervalDays: 30),
      );

      await repo.markDone('r1', now: fakeNow, generateId: nextId);
      // Chama de novo: o r1 já está done → deve ser idempotente.
      await repo.markDone('r1', now: fakeNow, generateId: nextId);

      // Deve haver exatamente 2: r1 (done) + 1 próximo (gen-0).
      final list = await repo.listByVehicle('v1');
      expect(list, hasLength(2));
    });
  });

  group('markDone — erros', () {
    test('lança StateError quando lembrete não existe', () async {
      expect(
        () => repo.markDone('nao-existe', now: fakeNow, generateId: nextId),
        throwsStateError,
      );
    });

    test('lança StateError quando soft-deletado', () async {
      await repo.create(sample(id: 'r1'));
      await repo.softDelete('r1');

      expect(
        () => repo.markDone('r1', now: fakeNow, generateId: nextId),
        throwsStateError,
      );
    });
  });
}

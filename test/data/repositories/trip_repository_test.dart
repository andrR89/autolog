import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/trip_repository.dart';
import 'package:autolog/domain/models/trip.dart';
import 'package:autolog/domain/repositories/trip_repository.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.X — Repositório de viagens (CRUD local + soft delete).
void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.TripRepository repo;

  DateTime now() => fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 24, 10);
    repo = DriftTripRepository(db, now: now);
  });

  tearDown(() => db.close());

  Trip sample({
    String id = 't1',
    String vehicleId = 'v1',
    String name = 'Floripa',
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    final start = startDate ?? DateTime.utc(2026, 5, 1);
    final end = endDate ?? DateTime.utc(2026, 5, 7);
    return Trip(
      id: id,
      vehicleId: vehicleId,
      name: name,
      startDate: start,
      endDate: end,
      notes: notes,
      createdAt: DateTime.utc(2000),
      updatedAt: DateTime.utc(2000),
    );
  }

  group('create', () {
    test('insere e define timestamps', () async {
      final saved = await repo.create(sample());

      expect(saved.id, 't1');
      expect(saved.name, 'Floripa');
      expect(saved.createdAt, fakeNow);
      expect(saved.updatedAt, fakeNow);
      expect(saved.deletedAt, isNull);
    });

    test('getById retorna a viagem criada', () async {
      await repo.create(sample());
      final got = await repo.getById('t1');
      expect(got, isNotNull);
      expect(got!.name, 'Floripa');
    });

    test('notes nullable é preservado', () async {
      final saved = await repo.create(sample(notes: 'Férias'));
      expect(saved.notes, 'Férias');

      final savedNull = await repo.create(
        sample(id: 't2', vehicleId: 'v1'),
      );
      expect(savedNull.notes, isNull);
    });
  });

  group('update', () {
    test('atualiza campos e bumpa updatedAt', () async {
      await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 25, 12);

      final updated = await repo.update(
        sample(name: 'Serra Gaúcha').copyWith(
          createdAt: DateTime.utc(2026, 5, 24, 10),
        ),
      );

      expect(updated.name, 'Serra Gaúcha');
      expect(updated.updatedAt, fakeNow);
      // createdAt deve ser preservado
      expect(updated.createdAt, DateTime.utc(2026, 5, 24, 10));
    });

    test('update em id inexistente lança StateError', () async {
      expect(
        () => repo.update(sample(id: 'nope')),
        throwsStateError,
      );
    });

    test('update em soft-deleted lança StateError', () async {
      await repo.create(sample());
      await repo.softDelete('t1');

      expect(
        () => repo.update(sample()),
        throwsStateError,
      );
    });
  });

  group('softDelete', () {
    test('define deleted_at e updatedAt', () async {
      await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 25, 15);

      await repo.softDelete('t1');

      // getById retorna null para soft-deleted
      final got = await repo.getById('t1');
      expect(got, isNull);

      // Verifica no banco direto que deleted_at foi definido
      final rows = await db.select(db.trips).get();
      expect(rows.first.deletedAt!.toUtc(), fakeNow);
      expect(rows.first.updatedAt.toUtc(), fakeNow);
    });

    test('idempotente: segundo softDelete não sobrescreve deleted_at', () async {
      await repo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 25, 15);
      await repo.softDelete('t1');

      final firstDeletedAt = (await db.select(db.trips).get()).first.deletedAt;

      fakeNow = DateTime.utc(2026, 5, 26, 10);
      await repo.softDelete('t1'); // segundo call — idempotente

      final rows = await db.select(db.trips).get();
      expect(rows.first.deletedAt, firstDeletedAt); // não mudou
    });

    test('softDelete em id inexistente não lança', () async {
      await expectLater(repo.softDelete('nope'), completes);
    });
  });

  group('listByVehicle', () {
    test('retorna apenas viagens do veículo, exclui soft-deleted', () async {
      await repo.create(sample(id: 't1', vehicleId: 'v1'));
      await repo.create(sample(id: 't2', vehicleId: 'v2')); // outro veículo
      await repo.create(sample(id: 't3', vehicleId: 'v1'));
      await repo.softDelete('t3'); // soft-deleted

      final list = await repo.listByVehicle('v1');
      expect(list.length, 1);
      expect(list.first.id, 't1');
    });

    test('ordena por startDate DESC', () async {
      await repo.create(
        sample(
          id: 't1',
          startDate: DateTime.utc(2026, 5, 1),
          endDate: DateTime.utc(2026, 5, 7),
        ),
      );
      await repo.create(
        sample(
          id: 't2',
          startDate: DateTime.utc(2026, 6, 1),
          endDate: DateTime.utc(2026, 6, 7),
        ),
      );

      final list = await repo.listByVehicle('v1');
      expect(list.first.id, 't2'); // junho primeiro (mais recente)
      expect(list.last.id, 't1');
    });
  });

  group('watchByVehicle', () {
    test('emite lista inicial e reage a insert', () async {
      final stream = repo.watchByVehicle('v1');

      // Primeira emissão — lista vazia.
      final first = await stream.first;
      expect(first, isEmpty);

      // Insert — stream deve emitir nova lista.
      await repo.create(sample());
      final second = await stream.first;
      expect(second.length, 1);
      expect(second.first.name, 'Floripa');
    });
  });
}

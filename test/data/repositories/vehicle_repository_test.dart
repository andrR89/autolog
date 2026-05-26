import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/vehicle_repository.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 1.1 — Repositório de vehicles (CRUD local + soft delete).
/// Spec: docs/specs/sprint-1.1-vehicle-repository.md
void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.VehicleRepository repo;

  // Tempo injetado, mutável entre operações pra testar bumps de updated_at.
  DateTime now() => fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 23, 10);
    repo = DriftVehicleRepository(db, now: now);
  });

  tearDown(() => db.close());

  Vehicle sampleVehicle({
    String id = 'v1',
    String userId = 'u1',
    String nickname = 'Meu Civic',
  }) {
    return Vehicle(
      id: id,
      userId: userId,
      nickname: nickname,
      fuelType: FuelType.flex,
      initialOdometer: 45000,
      // createdAt/updatedAt definidos pelo repositório no create.
      createdAt: DateTime.utc(2000), // ignorado/sobrescrito
      updatedAt: DateTime.utc(2000), // ignorado/sobrescrito
      syncStatus:
          SyncStatus.synced, // ignorado/sobrescrito — toda escrita vira pending
    );
  }

  group('create', () {
    test(
      'insere, marca pending, define createdAt e updatedAt = now() injetado',
      () async {
        final saved = await repo.create(sampleVehicle());

        expect(saved.id, 'v1');
        expect(saved.userId, 'u1');
        expect(saved.nickname, 'Meu Civic');
        expect(saved.fuelType, FuelType.flex);
        expect(saved.initialOdometer, 45000);
        expect(saved.syncStatus, SyncStatus.pending);
        expect(saved.createdAt, fakeNow);
        expect(saved.updatedAt, fakeNow);
        expect(saved.deletedAt, isNull);
        expect(saved.make, isNull);

        final got = await repo.getById('v1');
        expect(got, saved);
      },
    );

    test(
      'isolamento por userId — listByUser não vê de outro usuário',
      () async {
        await repo.create(sampleVehicle(id: 'v1', userId: 'u1'));
        await repo.create(sampleVehicle(id: 'v2', userId: 'u2'));

        final u1 = await repo.listByUser('u1');
        expect(u1.map((v) => v.id), ['v1']);

        final u2 = await repo.listByUser('u2');
        expect(u2.map((v) => v.id), ['v2']);
      },
    );
  });

  group('update', () {
    test(
      'bumpa updated_at, preserva createdAt, volta sync_status para pending',
      () async {
        final created = await repo.create(sampleVehicle());

        // Avança o relógio.
        fakeNow = DateTime.utc(2026, 5, 23, 11);

        // Simula que tinha virado synced (ex: SyncService).
        final synced = created.copyWith(syncStatus: SyncStatus.synced);
        // Persistimos esse "synced" diretamente (não vai pelo repo pra simular):
        // mais simples: testamos o efeito de update sobre pending também.

        final updated = await repo.update(
          synced.copyWith(nickname: 'Outro nome'),
        );

        expect(updated.nickname, 'Outro nome');
        expect(updated.createdAt, created.createdAt); // preservado
        expect(updated.updatedAt, fakeNow); // bumpado
        expect(
          updated.syncStatus,
          SyncStatus.pending,
        ); // marca pendente de novo
      },
    );

    test('lança StateError quando o id não existe', () async {
      expect(
        () => repo.update(sampleVehicle(id: 'fantasma')),
        throwsStateError,
      );
    });

    test('lança StateError quando o veículo está soft-deletado', () async {
      await repo.create(sampleVehicle());
      await repo.softDelete('v1');

      expect(
        () => repo.update(sampleVehicle().copyWith(nickname: 'Outro')),
        throwsStateError,
      );
    });
  });

  group('softDelete', () {
    test('marca deleted_at, sync_status=pending, esconde dos reads', () async {
      await repo.create(sampleVehicle());

      fakeNow = DateTime.utc(2026, 5, 23, 12);
      await repo.softDelete('v1');

      expect(await repo.getById('v1'), isNull);
      expect(await repo.listByUser('u1'), isEmpty);
    });

    test(
      'é idempotente — segunda chamada não sobrescreve deleted_at original',
      () async {
        await repo.create(sampleVehicle());

        fakeNow = DateTime.utc(2026, 5, 23, 12);
        await repo.softDelete('v1');

        // Lê o deleted_at original direto do banco (registro está oculto via repo).
        final rawFirst = await (db.select(
          db.vehicles,
        )..where((t) => t.id.equals('v1'))).getSingle();
        final firstDeletedAt = rawFirst.deletedAt;

        fakeNow = DateTime.utc(2026, 5, 23, 13);
        await repo.softDelete('v1'); // não deve lançar

        final rawSecond = await (db.select(
          db.vehicles,
        )..where((t) => t.id.equals('v1'))).getSingle();
        expect(rawSecond.deletedAt, firstDeletedAt);
      },
    );
  });

  group('listByUser', () {
    test('ordena por createdAt ascendente e exclui soft-deletados', () async {
      fakeNow = DateTime.utc(2026, 5, 23, 10);
      await repo.create(sampleVehicle(id: 'v1', nickname: 'A'));

      fakeNow = DateTime.utc(2026, 5, 23, 11);
      await repo.create(sampleVehicle(id: 'v2', nickname: 'B'));

      fakeNow = DateTime.utc(2026, 5, 23, 12);
      await repo.create(sampleVehicle(id: 'v3', nickname: 'C'));

      await repo.softDelete('v2');

      final list = await repo.listByUser('u1');
      expect(list.map((v) => v.id), ['v1', 'v3']);
    });
  });

  group('watchByUser', () {
    test(
      'emite na inicial e em cada mutação (create, update, softDelete)',
      () async {
        final stream = repo.watchByUser('u1');

        final emissions = <List<String>>[];
        final sub = stream.listen((list) {
          emissions.add(list.map((v) => v.id).toList());
        });

        // Aguarda a emissão inicial (lista vazia).
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await repo.create(sampleVehicle(id: 'v1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        fakeNow = fakeNow.add(const Duration(minutes: 1));
        await repo.update(
          sampleVehicle(id: 'v1').copyWith(nickname: 'Renomeado'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        fakeNow = fakeNow.add(const Duration(minutes: 1));
        await repo.softDelete('v1');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await sub.cancel();

        // Espera ao menos 4 emissões: inicial vazia, create, update, softDelete.
        expect(emissions.length, greaterThanOrEqualTo(4));
        expect(emissions.first, isEmpty);
        expect(emissions[1], ['v1']);
        expect(emissions.last, isEmpty); // após softDelete
      },
    );
  });
}

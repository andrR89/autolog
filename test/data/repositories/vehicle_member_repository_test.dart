import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/vehicle_member_repository.dart';
import 'package:autolog/domain/models/vehicle_member.dart';
import 'package:autolog/domain/repositories/vehicle_member_repository.dart'
    as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.Y — Repositório de vehicle_members (CRUD local).

void main() {
  late AppDatabase db;
  late domain.VehicleMemberRepository repo;
  final now = DateTime.utc(2026, 5, 27, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftVehicleMemberRepository(db);
  });

  tearDown(() => db.close());

  VehicleMember sample({
    String vehicleId = 'v1',
    String userId = 'u1',
    String role = 'member',
    DateTime? createdAt,
  }) {
    return VehicleMember(
      vehicleId: vehicleId,
      userId: userId,
      role: role,
      createdAt: createdAt ?? now,
    );
  }

  group('upsert', () {
    test('insere novo membro corretamente', () async {
      await repo.upsert(sample());

      final list = await repo.listByVehicle('v1');
      expect(list, hasLength(1));
      expect(list.first.vehicleId, 'v1');
      expect(list.first.userId, 'u1');
      expect(list.first.role, 'member');
      expect(list.first.createdAt, now);
    });

    test('upsert é idempotente — duplicata não lança', () async {
      await repo.upsert(sample());
      await repo.upsert(sample(role: 'owner')); // atualiza o role

      final list = await repo.listByVehicle('v1');
      expect(list, hasLength(1));
      expect(list.first.role, 'owner');
    });

    test('insere múltiplos membros para o mesmo veículo', () async {
      await repo.upsert(sample(userId: 'u1'));
      await repo.upsert(sample(userId: 'u2'));
      await repo.upsert(sample(userId: 'u3'));

      final list = await repo.listByVehicle('v1');
      expect(list, hasLength(3));
    });
  });

  group('listByVehicle', () {
    test('retorna vazio quando não há membros', () async {
      final list = await repo.listByVehicle('v1');
      expect(list, isEmpty);
    });

    test('lista apenas membros do veículo correto', () async {
      await repo.upsert(sample(vehicleId: 'v1', userId: 'u1'));
      await repo.upsert(sample(vehicleId: 'v2', userId: 'u2'));

      final listV1 = await repo.listByVehicle('v1');
      expect(listV1, hasLength(1));
      expect(listV1.first.userId, 'u1');

      final listV2 = await repo.listByVehicle('v2');
      expect(listV2, hasLength(1));
      expect(listV2.first.userId, 'u2');
    });

    test('membros são ordenados por createdAt ASC', () async {
      final t1 = DateTime.utc(2026, 5, 1);
      final t2 = DateTime.utc(2026, 5, 2);
      final t3 = DateTime.utc(2026, 5, 3);

      await repo.upsert(sample(userId: 'u3', createdAt: t3));
      await repo.upsert(sample(userId: 'u1', createdAt: t1));
      await repo.upsert(sample(userId: 'u2', createdAt: t2));

      final list = await repo.listByVehicle('v1');
      expect(list.map((m) => m.userId).toList(), ['u1', 'u2', 'u3']);
    });
  });

  group('watchByVehicle', () {
    test('emite lista vazia inicialmente', () async {
      final stream = repo.watchByVehicle('v1');
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test('emite atualização após upsert', () async {
      final stream = repo.watchByVehicle('v1');

      // Pula o estado inicial vazio.
      final events = <List<VehicleMember>>[];
      final sub = stream.listen(events.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.upsert(sample());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events.length, greaterThanOrEqualTo(2));
      expect(events.last, hasLength(1));
      expect(events.last.first.userId, 'u1');

      await sub.cancel();
    });

    test('emite atualização após remove', () async {
      await repo.upsert(sample());

      final stream = repo.watchByVehicle('v1');
      final events = <List<VehicleMember>>[];
      final sub = stream.listen(events.add);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.remove('v1', 'u1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events.last, isEmpty);

      await sub.cancel();
    });
  });

  group('remove', () {
    test('remove o membro correto', () async {
      await repo.upsert(sample(userId: 'u1'));
      await repo.upsert(sample(userId: 'u2'));

      await repo.remove('v1', 'u1');

      final list = await repo.listByVehicle('v1');
      expect(list, hasLength(1));
      expect(list.first.userId, 'u2');
    });

    test('remove é idempotente — não lança se membro não existe', () async {
      // Não deve lançar.
      await expectLater(
        repo.remove('v1', 'u-inexistente'),
        completes,
      );
    });

    test('remove não afeta membros de outro veículo', () async {
      await repo.upsert(sample(vehicleId: 'v1', userId: 'u1'));
      await repo.upsert(sample(vehicleId: 'v2', userId: 'u1'));

      await repo.remove('v1', 'u1');

      final listV1 = await repo.listByVehicle('v1');
      final listV2 = await repo.listByVehicle('v2');

      expect(listV1, isEmpty);
      expect(listV2, hasLength(1));
    });
  });
}

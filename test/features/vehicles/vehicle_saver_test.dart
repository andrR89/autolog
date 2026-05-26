import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/vehicle_repository.dart';
import 'package:autolog/features/vehicles/vehicle_saver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 1.3 — VehicleSaver: orquestra criar/editar/excluir via repo.
/// Spec: docs/specs/sprint-1.3-vehicles-ui.md

/// Fake em memória do repo (sem Drift).
class FakeVehicleRepository implements VehicleRepository {
  final Map<String, Vehicle> _store = {};
  Vehicle? lastCreated;
  Vehicle? lastUpdated;
  String? lastDeletedId;

  // Knob pra forçar erro em update.
  bool throwOnUpdate = false;

  @override
  Future<Vehicle> create(Vehicle vehicle) async {
    final saved = vehicle.copyWith(
      createdAt: DateTime.utc(2026, 5, 23),
      updatedAt: DateTime.utc(2026, 5, 23),
      syncStatus: SyncStatus.pending,
    );
    _store[saved.id] = saved;
    lastCreated = saved;
    return saved;
  }

  @override
  Future<Vehicle> update(Vehicle vehicle) async {
    if (throwOnUpdate) {
      throw StateError('forçado pra teste');
    }
    final existing = _store[vehicle.id];
    if (existing == null) {
      throw StateError('not found');
    }
    final updated = vehicle.copyWith(
      createdAt: existing.createdAt,
      updatedAt: DateTime.utc(2026, 5, 24),
      syncStatus: SyncStatus.pending,
    );
    _store[updated.id] = updated;
    lastUpdated = updated;
    return updated;
  }

  @override
  Future<void> softDelete(String id) async {
    lastDeletedId = id;
    _store.remove(id);
  }

  @override
  Future<Vehicle?> getById(String id) async => _store[id];

  @override
  Future<List<Vehicle>> listByUser(String userId) async =>
      _store.values.where((v) => v.userId == userId).toList();

  @override
  Stream<List<Vehicle>> watchByUser(String userId) =>
      Stream.value(_store.values.where((v) => v.userId == userId).toList());
}

void main() {
  late FakeVehicleRepository repo;
  late VehicleSaver saver;

  setUp(() {
    repo = FakeVehicleRepository();
    int counter = 0;
    saver = VehicleSaver(repo, generateId: () => 'id-${++counter}');
  });

  group('create', () {
    test(
      'chama repo.create com Vehicle montado a partir dos parâmetros',
      () async {
        final saved = await saver.create(
          userId: 'u1',
          nickname: 'Meu Civic',
          make: 'Honda',
          model: 'Civic',
          plate: 'ABC1D23',
          fuelType: FuelType.flex,
          initialOdometer: 45000,
        );

        expect(repo.lastCreated, isNotNull);
        expect(repo.lastCreated!.id, 'id-1'); // do generateId
        expect(repo.lastCreated!.userId, 'u1');
        expect(repo.lastCreated!.nickname, 'Meu Civic');
        expect(repo.lastCreated!.make, 'Honda');
        expect(repo.lastCreated!.model, 'Civic');
        expect(repo.lastCreated!.plate, 'ABC1D23');
        expect(repo.lastCreated!.fuelType, FuelType.flex);
        expect(repo.lastCreated!.initialOdometer, 45000);

        // Retorna o Vehicle do repo (já com timestamps definidos por ele).
        expect(saved, repo.lastCreated);
      },
    );

    test('opcionais nulos passam como null', () async {
      await saver.create(
        userId: 'u1',
        nickname: 'Sem marca',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
      );
      expect(repo.lastCreated!.make, isNull);
      expect(repo.lastCreated!.model, isNull);
      expect(repo.lastCreated!.plate, isNull);
    });
  });

  group('update', () {
    test(
      'preserva id, userId e createdAt do existing; aplica campos novos',
      () async {
        // Cria um existente direto no store.
        final original = await saver.create(
          userId: 'u1',
          nickname: 'Velho',
          fuelType: FuelType.gasolina,
          initialOdometer: 10000,
        );

        final updated = await saver.update(
          original,
          nickname: 'Novo',
          make: 'Toyota',
          fuelType: FuelType.flex,
          initialOdometer: 20000,
        );

        expect(repo.lastUpdated, isNotNull);
        expect(repo.lastUpdated!.id, original.id); // preservado
        expect(repo.lastUpdated!.userId, original.userId); // preservado
        expect(repo.lastUpdated!.createdAt, original.createdAt); // preservado
        expect(repo.lastUpdated!.nickname, 'Novo');
        expect(repo.lastUpdated!.make, 'Toyota');
        expect(repo.lastUpdated!.fuelType, FuelType.flex);
        expect(repo.lastUpdated!.initialOdometer, 20000);

        expect(updated, repo.lastUpdated);
      },
    );

    test('propaga erro do repo intacto', () async {
      final original = await saver.create(
        userId: 'u1',
        nickname: 'V',
        fuelType: FuelType.flex,
        initialOdometer: 0,
      );
      repo.throwOnUpdate = true;

      expect(
        () => saver.update(
          original,
          nickname: 'X',
          fuelType: FuelType.flex,
          initialOdometer: 1,
        ),
        throwsStateError,
      );
    });
  });

  group('delete', () {
    test('chama repo.softDelete com o id', () async {
      await saver.delete('algum-id');
      expect(repo.lastDeletedId, 'algum-id');
    });
  });
}

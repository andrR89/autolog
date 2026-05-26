import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart';
import 'package:autolog/features/fuel/fuel_entry_saver.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 2.3 — FuelEntrySaver: orquestra criar/editar/excluir via repo.
/// Spec: docs/specs/sprint-2.3-fuel-entry-form.md

/// Fake em memória do repo (sem Drift).
class _FakeFuelEntryRepository implements FuelEntryRepository {
  final Map<String, FuelEntry> _store = {};
  FuelEntry? lastCreated;
  FuelEntry? lastUpdated;
  String? lastDeletedId;
  bool throwOnUpdate = false;

  @override
  Future<FuelEntry> create(FuelEntry entry) async {
    final saved = entry.copyWith(
      createdAt: DateTime.utc(2026, 5, 23),
      updatedAt: DateTime.utc(2026, 5, 23),
      syncStatus: SyncStatus.pending,
    );
    _store[saved.id] = saved;
    lastCreated = saved;
    return saved;
  }

  @override
  Future<FuelEntry> update(FuelEntry entry) async {
    if (throwOnUpdate) {
      throw StateError('forçado pra teste');
    }
    final existing = _store[entry.id];
    if (existing == null) throw StateError('not found');
    final updated = entry.copyWith(
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
  Future<FuelEntry?> getById(String id) async => _store[id];

  @override
  Future<List<FuelEntry>> listByVehicle(String vehicleId) async =>
      _store.values.where((e) => e.vehicleId == vehicleId).toList();

  @override
  Stream<List<FuelEntry>> watchByVehicle(String vehicleId) => Stream.value(
    _store.values.where((e) => e.vehicleId == vehicleId).toList(),
  );
}

void main() {
  late _FakeFuelEntryRepository repo;
  late FuelEntrySaver saver;
  final date = DateTime.utc(2026, 5, 23, 14);

  setUp(() {
    repo = _FakeFuelEntryRepository();
    int counter = 0;
    saver = FuelEntrySaver(repo, generateId: () => 'id-${++counter}');
  });

  group('create', () {
    test('chama repo.create com FuelEntry montado; source = manual', () async {
      final saved = await saver.create(
        vehicleId: 'v1',
        date: date,
        odometer: 45100,
        liters: Decimal.parse('43.219'),
        pricePerLiter: Decimal.parse('5.799'),
        totalCost: Decimal.parse('250.626981'),
        fullTank: true,
        fuelType: FuelType.gasolina,
      );

      expect(repo.lastCreated, isNotNull);
      expect(repo.lastCreated!.id, 'id-1');
      expect(repo.lastCreated!.vehicleId, 'v1');
      expect(repo.lastCreated!.date, date);
      expect(repo.lastCreated!.odometer, 45100);
      expect(repo.lastCreated!.liters, Decimal.parse('43.219'));
      expect(repo.lastCreated!.pricePerLiter, Decimal.parse('5.799'));
      expect(repo.lastCreated!.totalCost, Decimal.parse('250.626981'));
      expect(repo.lastCreated!.fullTank, true);
      expect(repo.lastCreated!.fuelType, FuelType.gasolina);
      expect(repo.lastCreated!.source, FuelSource.manual);
      expect(repo.lastCreated!.receiptImageUrl, isNull);

      expect(saved, repo.lastCreated);
    });
  });

  group('update', () {
    test(
      'preserva id, vehicleId, createdAt, source, receiptImageUrl; aplica novos campos',
      () async {
        // Cria um existing direto (não via saver) com source diferente pra provar
        // que update NÃO troca a origem.
        final originalDate = DateTime.utc(2026, 5, 22, 10);
        final originalInStore = await repo.create(
          FuelEntry(
            id: 'orig-1',
            vehicleId: 'v1',
            date: originalDate,
            odometer: 45000,
            liters: Decimal.parse('40'),
            pricePerLiter: Decimal.parse('5'),
            totalCost: Decimal.parse('200'),
            fullTank: true,
            fuelType: FuelType.gasolina,
            source: FuelSource.aiScan, // veio de scan
            receiptImageUrl: 'https://x/cupom.jpg',
            createdAt: DateTime.utc(2000),
            updatedAt: DateTime.utc(2000),
            syncStatus: SyncStatus.synced,
          ),
        );

        final updated = await saver.update(
          originalInStore,
          date: date,
          odometer: 45200,
          liters: Decimal.parse('30'),
          pricePerLiter: Decimal.parse('6'),
          totalCost: Decimal.parse('180'),
          fullTank: false,
          fuelType: FuelType.etanol,
        );

        expect(repo.lastUpdated, isNotNull);
        // Preservados:
        expect(repo.lastUpdated!.id, 'orig-1');
        expect(repo.lastUpdated!.vehicleId, 'v1');
        expect(repo.lastUpdated!.createdAt, originalInStore.createdAt);
        expect(repo.lastUpdated!.source, FuelSource.aiScan);
        expect(repo.lastUpdated!.receiptImageUrl, 'https://x/cupom.jpg');
        // Aplicados:
        expect(repo.lastUpdated!.date, date);
        expect(repo.lastUpdated!.odometer, 45200);
        expect(repo.lastUpdated!.liters, Decimal.parse('30'));
        expect(repo.lastUpdated!.pricePerLiter, Decimal.parse('6'));
        expect(repo.lastUpdated!.totalCost, Decimal.parse('180'));
        expect(repo.lastUpdated!.fullTank, false);
        expect(repo.lastUpdated!.fuelType, FuelType.etanol);

        expect(updated, repo.lastUpdated);
      },
    );

    test('propaga erro do repo intacto', () async {
      final original = await saver.create(
        vehicleId: 'v1',
        date: date,
        odometer: 45000,
        liters: Decimal.parse('10'),
        pricePerLiter: Decimal.parse('5'),
        totalCost: Decimal.parse('50'),
        fullTank: true,
        fuelType: FuelType.gasolina,
      );
      repo.throwOnUpdate = true;

      expect(
        () => saver.update(
          original,
          date: date,
          odometer: 45100,
          liters: Decimal.parse('20'),
          pricePerLiter: Decimal.parse('5'),
          totalCost: Decimal.parse('100'),
          fullTank: true,
          fuelType: FuelType.gasolina,
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

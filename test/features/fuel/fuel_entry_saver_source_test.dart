import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart';
import 'package:autolog/features/fuel/fuel_entry_saver.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.3 — FuelEntrySaver.create agora aceita source opcional.
/// Spec: docs/specs/sprint-3.3-scan-flow.md
class _FakeRepo implements FuelEntryRepository {
  FuelEntry? lastCreated;
  @override
  Future<FuelEntry> create(FuelEntry entry) async {
    lastCreated = entry;
    return entry;
  }

  @override
  Future<FuelEntry> update(FuelEntry entry) async => throw UnimplementedError();
  @override
  Future<void> softDelete(String id) async {}
  @override
  Future<FuelEntry?> getById(String id) async => null;
  @override
  Future<List<FuelEntry>> listByVehicle(String vehicleId) async => const [];
  @override
  Stream<List<FuelEntry>> watchByVehicle(String vehicleId) =>
      const Stream.empty();
}

void main() {
  late _FakeRepo repo;
  late FuelEntrySaver saver;

  setUp(() {
    repo = _FakeRepo();
    saver = FuelEntrySaver(repo, generateId: () => 'id-1');
  });

  test('source: aiScan é repassado pro repo', () async {
    await saver.create(
      vehicleId: 'v1',
      date: DateTime.utc(2026, 5, 23),
      odometer: 1,
      liters: Decimal.parse('1'),
      pricePerLiter: Decimal.parse('1'),
      totalCost: Decimal.parse('1'),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.aiScan,
    );
    expect(repo.lastCreated!.source, FuelSource.aiScan);
  });

  test('source não informado: default manual (compatibilidade)', () async {
    await saver.create(
      vehicleId: 'v1',
      date: DateTime.utc(2026, 5, 23),
      odometer: 1,
      liters: Decimal.parse('1'),
      pricePerLiter: Decimal.parse('1'),
      totalCost: Decimal.parse('1'),
      fullTank: true,
      fuelType: FuelType.gasolina,
    );
    expect(repo.lastCreated!.source, FuelSource.manual);
  });
}

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/station_aggregation.dart';
import 'package:autolog/features/fuel/station_brands.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.P — agregação pura por posto.
/// Spec: docs/specs/sprint-6.P-station-price-tracker.md

FuelEntry _e({
  required String id,
  required DateTime date,
  required String liters,
  required String price,
  required String total,
  String? brand,
  String? name,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: 100,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse(price),
      totalCost: Decimal.parse(total),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      stationName: name,
      stationBrand: brand,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.synced,
    );

void main() {
  group('normalizeStation', () {
    test('trim + lowercase', () {
      expect(normalizeStation('Shell '), 'shell');
      expect(normalizeStation(' SHELL'), 'shell');
    });

    test('remove acentos', () {
      expect(normalizeStation('Petrobrás'), 'petrobras');
      expect(normalizeStation('Raízen'), 'raizen');
    });

    test('vazio → vazio', () {
      expect(normalizeStation(''), '');
      expect(normalizeStation('   '), '');
    });
  });

  group('brStationBrands', () {
    test('contém pelo menos 10 bandeiras incluindo Shell/Petrobras/Ipiranga', () {
      expect(brStationBrands.length >= 10, isTrue);
      expect(brStationBrands, containsAll(['Shell', 'Petrobras', 'Ipiranga']));
    });
  });

  group('aggregateByStation', () {
    test('lista vazia → vazia', () {
      expect(aggregateByStation(const []), isEmpty);
    });

    test('1 entrada com brand+name → 1 stat', () {
      final stats = aggregateByStation([
        _e(
          id: 'f1', date: DateTime.utc(2026, 5, 20),
          liters: '40', price: '5.79', total: '231.60',
          brand: 'Shell', name: 'Posto X',
        ),
      ]);
      expect(stats.length, 1);
      expect(stats.single.brand, 'Shell');
      expect(stats.single.name, 'Posto X');
      expect(stats.single.entriesCount, 1);
      expect(stats.single.totalLiters, Decimal.parse('40'));
      expect(stats.single.totalSpent, Decimal.parse('231.60'));
    });

    test('múltiplas entradas mesma estação agrupam', () {
      final stats = aggregateByStation([
        _e(
          id: 'f1', date: DateTime.utc(2026, 5, 1),
          liters: '40', price: '5.0', total: '200',
          brand: 'Shell', name: 'X',
        ),
        _e(
          id: 'f2', date: DateTime.utc(2026, 5, 15),
          liters: '50', price: '6.0', total: '300',
          brand: 'Shell', name: 'X',
        ),
      ]);
      expect(stats.length, 1);
      expect(stats.single.entriesCount, 2);
      expect(stats.single.totalLiters, Decimal.parse('90'));
      expect(stats.single.totalSpent, Decimal.parse('500'));
      // avg = 500 / 90 ≈ 5.5556
      expect(
        stats.single.avgPricePerLiter,
        Decimal.parse('5.5556'),
      );
      expect(stats.single.lastEntryDate, DateTime.utc(2026, 5, 15));
    });

    test('brand "Shell" e "shell  " agrupam (case/espaço insensitive)', () {
      final stats = aggregateByStation([
        _e(
          id: 'f1', date: DateTime.utc(2026, 5, 1),
          liters: '40', price: '5', total: '200',
          brand: 'Shell', name: 'X',
        ),
        _e(
          id: 'f2', date: DateTime.utc(2026, 5, 2),
          liters: '10', price: '5', total: '50',
          brand: 'shell  ', name: 'x',
        ),
      ]);
      expect(stats.length, 1);
      expect(stats.single.entriesCount, 2);
    });

    test('entradas sem brand E sem name → grupo "Sem identificação"', () {
      final stats = aggregateByStation([
        _e(
          id: 'f1', date: DateTime.utc(2026, 5, 1),
          liters: '40', price: '5', total: '200',
        ),
        _e(
          id: 'f2', date: DateTime.utc(2026, 5, 2),
          liters: '10', price: '5', total: '50',
        ),
      ]);
      expect(stats.length, 1);
      expect(stats.single.brand, isNull);
      expect(stats.single.name, isNull);
      expect(stats.single.entriesCount, 2);
    });

    test('ordenação por entriesCount DESC', () {
      final stats = aggregateByStation([
        _e(id: 'f1', date: DateTime.utc(2026, 5, 1),
            liters: '10', price: '5', total: '50',
            brand: 'Ipiranga', name: 'Y'),
        _e(id: 'f2', date: DateTime.utc(2026, 5, 2),
            liters: '10', price: '5', total: '50',
            brand: 'Shell', name: 'X'),
        _e(id: 'f3', date: DateTime.utc(2026, 5, 3),
            liters: '10', price: '5', total: '50',
            brand: 'Shell', name: 'X'),
      ]);
      expect(stats.first.brand, 'Shell');
      expect(stats.first.entriesCount, 2);
      expect(stats[1].brand, 'Ipiranga');
    });

    test('avgPricePerLiter usa precisão Decimal scale 4', () {
      final stats = aggregateByStation([
        _e(
          id: 'f1', date: DateTime.utc(2026, 5, 1),
          liters: '3', price: '5', total: '15',
        ),
      ]);
      expect(stats.single.avgPricePerLiter, Decimal.parse('5'));

      // 100 / 7 = 14.2857142857... → arredonda pra 14.2857
      final stats2 = aggregateByStation([
        _e(
          id: 'f1', date: DateTime.utc(2026, 5, 1),
          liters: '7', price: '14.2857', total: '100',
        ),
      ]);
      expect(stats2.single.avgPricePerLiter, Decimal.parse('14.2857'));
    });
  });
}

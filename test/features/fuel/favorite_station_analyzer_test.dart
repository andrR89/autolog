import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/favorite_station_analyzer.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.S — posto preferido + ranking.
/// Spec: docs/specs/sprint-6.S-favorite-station.md

FuelEntry _e({
  required String id,
  required String liters,
  required String price,
  required String total,
  String? brand,
  String? name,
  DateTime? date,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date ?? DateTime.utc(2026, 5, 1),
      odometer: 100,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse(price),
      totalCost: Decimal.parse(total),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      stationName: name,
      stationBrand: brand,
      createdAt: date ?? DateTime.utc(2026, 5, 1),
      updatedAt: date ?? DateTime.utc(2026, 5, 1),
      syncStatus: SyncStatus.synced,
    );

void main() {
  group('analyzeFavoriteStation', () {
    test('lista vazia → tudo null/vazio', () {
      final r = analyzeFavoriteStation(const []);
      expect(r.favorite, isNull);
      expect(r.cheapestQualified, isNull);
      expect(r.topByFrequency, isEmpty);
    });

    test('1 entry sem brand/name → favorite null', () {
      final r = analyzeFavoriteStation([
        _e(id: 'a', liters: '40', price: '5', total: '200'),
      ]);
      expect(r.favorite, isNull);
      expect(r.topByFrequency, isEmpty);
    });

    test('3 visitas Shell + 5 visitas Petrobras → favorite=Petrobras', () {
      final entries = <FuelEntry>[
        for (var i = 0; i < 3; i++)
          _e(id: 's$i', liters: '40', price: '5.5', total: '220',
              brand: 'Shell', name: 'Shell X'),
        for (var i = 0; i < 5; i++)
          _e(id: 'p$i', liters: '40', price: '5.7', total: '228',
              brand: 'Petrobras', name: 'Petrobras Y'),
      ];
      final r = analyzeFavoriteStation(entries);
      expect(r.favorite, isNotNull);
      expect(r.favorite!.brand, 'Petrobras');
      expect(r.favorite!.entriesCount, 5);
    });

    test('empate de frequência → desempate por lastEntryDate', () {
      final entries = [
        _e(id: 'a1', liters: '40', price: '5', total: '200',
            brand: 'Shell', name: 'X',
            date: DateTime.utc(2026, 1, 1)),
        _e(id: 'a2', liters: '40', price: '5', total: '200',
            brand: 'Shell', name: 'X',
            date: DateTime.utc(2026, 2, 1)),
        _e(id: 'b1', liters: '40', price: '5', total: '200',
            brand: 'Ipiranga', name: 'Y',
            date: DateTime.utc(2026, 3, 1)),
        _e(id: 'b2', liters: '40', price: '5', total: '200',
            brand: 'Ipiranga', name: 'Y',
            date: DateTime.utc(2026, 4, 1)),
      ];
      final r = analyzeFavoriteStation(entries);
      // ambos tem 2 visitas, Ipiranga vence pela data mais recente
      expect(r.favorite!.brand, 'Ipiranga');
    });

    test('cheapest qualified: B com < 3 visitas NÃO conta', () {
      final entries = [
        for (var i = 0; i < 5; i++)
          _e(id: 'a$i', liters: '40', price: '5.00', total: '200',
              brand: 'Shell', name: 'A'),
        for (var i = 0; i < 2; i++)
          _e(id: 'b$i', liters: '40', price: '4.00', total: '160',
              brand: 'Petrobras', name: 'B'),
      ];
      final r = analyzeFavoriteStation(entries);
      // Mesmo B sendo mais barato (avg 4.00), só tem 2 visitas → não qualifica
      // Cheapest qualified = A (5 visitas, avg 5.00 — único elegível)
      expect(r.cheapestQualified!.brand, 'Shell');
    });

    test('cheapest qualified: B com 3+ visitas e menor avg → B vence', () {
      final entries = [
        for (var i = 0; i < 5; i++)
          _e(id: 'a$i', liters: '40', price: '5.00', total: '200',
              brand: 'Shell', name: 'A'),
        for (var i = 0; i < 3; i++)
          _e(id: 'b$i', liters: '40', price: '4.50', total: '180',
              brand: 'Petrobras', name: 'B'),
      ];
      final r = analyzeFavoriteStation(entries);
      expect(r.cheapestQualified!.brand, 'Petrobras');
    });

    test('cheapest pode ser igual ao favorite (mesma estação)', () {
      final entries = [
        for (var i = 0; i < 5; i++)
          _e(id: 'a$i', liters: '40', price: '4.00', total: '160',
              brand: 'Shell', name: 'A'),
      ];
      final r = analyzeFavoriteStation(entries);
      expect(r.favorite!.brand, 'Shell');
      expect(r.cheapestQualified!.brand, 'Shell');
    });

    test('topByFrequency ordenado DESC e respeita topLimit', () {
      final entries = <FuelEntry>[
        for (var i = 0; i < 7; i++)
          _e(id: 'a$i', liters: '40', price: '5', total: '200',
              brand: 'A', name: 'A'),
        for (var i = 0; i < 5; i++)
          _e(id: 'b$i', liters: '40', price: '5', total: '200',
              brand: 'B', name: 'B'),
        for (var i = 0; i < 3; i++)
          _e(id: 'c$i', liters: '40', price: '5', total: '200',
              brand: 'C', name: 'C'),
        for (var i = 0; i < 2; i++)
          _e(id: 'd$i', liters: '40', price: '5', total: '200',
              brand: 'D', name: 'D'),
        for (var i = 0; i < 1; i++)
          _e(id: 'e$i', liters: '40', price: '5', total: '200',
              brand: 'E', name: 'E'),
        for (var i = 0; i < 1; i++)
          _e(id: 'f$i', liters: '40', price: '5', total: '200',
              brand: 'F', name: 'F'),
      ];
      final r = analyzeFavoriteStation(entries, topLimit: 3);
      expect(r.topByFrequency.length, 3);
      expect(r.topByFrequency[0].brand, 'A');
      expect(r.topByFrequency[1].brand, 'B');
      expect(r.topByFrequency[2].brand, 'C');
    });

    test('entries sem brand E sem name não entram em nenhum ranking', () {
      final entries = [
        for (var i = 0; i < 5; i++)
          _e(id: 's$i', liters: '40', price: '5', total: '200',
              brand: 'Shell', name: 'X'),
        for (var i = 0; i < 10; i++)
          _e(id: 'u$i', liters: '40', price: '4', total: '160'),
      ];
      final r = analyzeFavoriteStation(entries);
      // Os "sem identificação" tem mais entries (10) mas não contam.
      expect(r.favorite!.brand, 'Shell');
    });
  });
}

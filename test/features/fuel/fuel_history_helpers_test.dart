import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/fuel_history_helpers.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 2.4 — helpers da tela de histórico de abastecimentos.
/// Spec: docs/specs/sprint-2.4-fuel-history.md
void main() {
  FuelEntry entry({
    required String id,
    required DateTime date,
    required int odometer,
    required String liters,
    required String pricePerLiter,
    required String totalCost,
    required bool fullTank,
    String vehicleId = 'v1',
  }) {
    return FuelEntry(
      id: id,
      vehicleId: vehicleId,
      date: date,
      odometer: odometer,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse(pricePerLiter),
      totalCost: Decimal.parse(totalCost),
      fullTank: fullTank,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  group('computeForDisplay', () {
    test('lista vazia retorna vazia', () {
      expect(computeForDisplay(const []), isEmpty);
    });

    test('um único entry: kmPerLiter null', () {
      final e = entry(
        id: 'e1',
        date: DateTime.utc(2026, 5, 1),
        odometer: 10000,
        liters: '40',
        pricePerLiter: '5',
        totalCost: '200',
        fullTank: true,
      );
      final r = computeForDisplay([e]);
      expect(r, hasLength(1));
      expect(r[0].entry, e);
      expect(r[0].kmPerLiter, isNull);
    });

    test('dois cheios em DESC: o mais recente (pos 0) recebe km/l', () {
      final e1 = entry(
        id: 'e1',
        date: DateTime.utc(2026, 5, 1),
        odometer: 10000,
        liters: '40',
        pricePerLiter: '5',
        totalCost: '200',
        fullTank: true,
      );
      final e2 = entry(
        id: 'e2',
        date: DateTime.utc(2026, 5, 10),
        odometer: 10500,
        liters: '40',
        pricePerLiter: '5.5',
        totalCost: '220',
        fullTank: true,
      );
      // Input DESC: [e2, e1].
      final r = computeForDisplay([e2, e1]);
      expect(r.map((c) => c.entry.id), ['e2', 'e1']); // ordem preservada
      expect(r[0].kmPerLiter, Decimal.parse('12.5000'));
      expect(r[1].kmPerLiter, isNull);
    });

    test('cheio + parcial + cheio em DESC: o mais recente recebe a janela', () {
      final e1 = entry(
        id: 'e1',
        date: DateTime.utc(2026, 5, 1),
        odometer: 10000,
        liters: '40',
        pricePerLiter: '5',
        totalCost: '200',
        fullTank: true,
      );
      final e2 = entry(
        id: 'e2',
        date: DateTime.utc(2026, 5, 5),
        odometer: 10200,
        liters: '20',
        pricePerLiter: '5.5',
        totalCost: '110',
        fullTank: false,
      );
      final e3 = entry(
        id: 'e3',
        date: DateTime.utc(2026, 5, 10),
        odometer: 10500,
        liters: '30',
        pricePerLiter: '5.5',
        totalCost: '165',
        fullTank: true,
      );
      // Input DESC: [e3, e2, e1].
      final r = computeForDisplay([e3, e2, e1]);
      expect(r.map((c) => c.entry.id), ['e3', 'e2', 'e1']);
      expect(r[0].kmPerLiter, Decimal.parse('10.0000')); // E3 fecha janela
      expect(r[1].kmPerLiter, isNull); // parcial
      expect(r[2].kmPerLiter, isNull); // primeiro cheio
    });
  });

  group('formatKmPerLiter', () {
    test('null retorna travessão', () {
      expect(formatKmPerLiter(null), '—');
    });

    test('1 casa decimal com vírgula', () {
      expect(formatKmPerLiter(Decimal.parse('12.5')), '12,5 km/l');
      expect(formatKmPerLiter(Decimal.parse('11.1111')), '11,1 km/l');
      expect(formatKmPerLiter(Decimal.parse('10')), '10,0 km/l');
    });
  });

  group('formatCostPerKm', () {
    test('null retorna travessão', () {
      expect(formatCostPerKm(null), '—');
    });

    test(r'2 casas com vírgula e prefixo R$', () {
      expect(formatCostPerKm(Decimal.parse('0.5500')), r'R$ 0,55/km');
      expect(formatCostPerKm(Decimal.parse('1.2345')), r'R$ 1,23/km');
    });
  });

  group('formatCurrencyBr', () {
    test('com 2 casas e arredondamento PT-BR', () {
      expect(formatCurrencyBr(Decimal.parse('250.626981')), r'R$ 250,63');
    });

    test('com separador de milhar', () {
      expect(formatCurrencyBr(Decimal.parse('1234.56')), r'R$ 1.234,56');
    });

    test('zero', () {
      expect(formatCurrencyBr(Decimal.parse('0')), r'R$ 0,00');
    });
  });

  group('formatLitersBr', () {
    test('3 casas decimais com vírgula', () {
      expect(formatLitersBr(Decimal.parse('43.219')), '43,219 L');
      expect(formatLitersBr(Decimal.parse('40')), '40,000 L');
    });
  });

  group('formatDateBr', () {
    test('dd/MM/yyyy', () {
      expect(formatDateBr(DateTime.utc(2026, 5, 23)), '23/05/2026');
    });
  });
}

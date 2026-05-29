// Testes TDD para Co2Calculator (Sprint 6.CC).
// Cobertura: ≥12 casos conforme spec.

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/insights/co2/co2_calculator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

FuelEntry _entry({
  required String id,
  required String liters,
  required FuelType fuelType,
  DateTime? date,
  int odometer = 100,
}) {
  final d = date ?? DateTime.utc(2026, 5, 10);
  return FuelEntry(
    id: id,
    vehicleId: 'v1',
    date: d,
    odometer: odometer,
    liters: Decimal.parse(liters),
    pricePerLiter: Decimal.parse('5'),
    totalCost: Decimal.parse(liters) * Decimal.parse('5'),
    fullTank: true,
    fuelType: fuelType,
    source: FuelSource.manual,
    createdAt: d,
    updatedAt: d,
    syncStatus: SyncStatus.synced,
  );
}

void main() {
  // =========================================================================
  // emissionFactor
  // =========================================================================
  group('emissionFactor', () {
    test('gasolina C → 2,21 kg/L', () {
      expect(emissionFactor(FuelType.gasolina), Decimal.parse('2.21'));
    });

    test('etanol hidratado → 1,52 kg/L', () {
      expect(emissionFactor(FuelType.etanol), Decimal.parse('1.52'));
    });

    test('diesel B → 2,68 kg/L', () {
      expect(emissionFactor(FuelType.diesel), Decimal.parse('2.68'));
    });

    test('GNV → 1,93 kg/L equivalente', () {
      expect(emissionFactor(FuelType.gnv), Decimal.parse('1.93'));
    });

    test('flex → fallback gasolina 2,21', () {
      expect(emissionFactor(FuelType.flex), Decimal.parse('2.21'));
    });
  });

  // =========================================================================
  // computeCo2 — casos base
  // =========================================================================
  group('computeCo2 — lista vazia', () {
    test('retorna total 0 e perKmGrams null', () {
      final r = computeCo2(entries: const [], totalKmInPeriod: 0);
      expect(r.totalKg, Decimal.zero);
      expect(r.perKmGrams, isNull);
      expect(r.entriesCount, 0);
    });
  });

  group('computeCo2 — 1 abastecimento gasolina', () {
    test('40L gasolina → 88,40 kg; perKm null se km=0', () {
      final r = computeCo2(
        entries: [_entry(id: 'a', liters: '40', fuelType: FuelType.gasolina)],
        totalKmInPeriod: 0,
      );
      expect(r.totalKg, Decimal.parse('88.40'));
      expect(
        r.perKmGrams,
        isNull,
        reason: 'totalKmInPeriod==0 → não calcula g/km',
      );
      expect(r.entriesCount, 1);
    });

    test('40L gasolina + 500 km → perKm = 88400/500 = 176,8 gCO2/km', () {
      final r = computeCo2(
        entries: [_entry(id: 'a', liters: '40', fuelType: FuelType.gasolina)],
        totalKmInPeriod: 500,
      );
      // 88.40 kg * 1000 / 500 km = 176.8 g/km
      expect(r.totalKg, Decimal.parse('88.40'));
      expect(r.perKmGrams, Decimal.parse('176.8'));
    });
  });

  group('computeCo2 — mix de combustíveis', () {
    test('40L gasolina + 50L etanol + 30L diesel → soma correta', () {
      // gasolina: 40 * 2.21 = 88.4
      // etanol:   50 * 1.52 = 76.0
      // diesel:   30 * 2.68 = 80.4
      // total:           244.8
      final r = computeCo2(
        entries: [
          _entry(id: 'g', liters: '40', fuelType: FuelType.gasolina),
          _entry(id: 'e', liters: '50', fuelType: FuelType.etanol),
          _entry(id: 'd', liters: '30', fuelType: FuelType.diesel),
        ],
        totalKmInPeriod: 0,
      );
      expect(r.totalKg, Decimal.parse('244.80'));
      expect(r.entriesCount, 3);
    });
  });

  group('computeCo2 — tipo desconhecido (flex como fallback)', () {
    test('flex usa fator gasolina e NÃO crashea', () {
      final r = computeCo2(
        entries: [_entry(id: 'f', liters: '30', fuelType: FuelType.flex)],
        totalKmInPeriod: 0,
      );
      // 30 * 2.21 = 66.30
      expect(r.totalKg, Decimal.parse('66.30'));
      expect(
        r.unknownFuelTypes['flex'],
        1,
        reason: 'flex deve ser registrado em unknownFuelTypes',
      );
    });
  });

  group('computeCo2 — precisão Decimal', () {
    test('sem perda de precisão: 43,219L gasolina', () {
      // 43.219 * 2.21 = 95.51399
      final r = computeCo2(
        entries: [
          _entry(id: 'a', liters: '43.219', fuelType: FuelType.gasolina),
        ],
        totalKmInPeriod: 0,
      );
      expect(r.totalKg, Decimal.parse('95.51399'));
    });

    test('mix com decimais — resultado exato', () {
      // 10.5L etanol * 1.52 = 15.96
      // 20.25L gasolina * 2.21 = 44.7525
      // total = 60.7125
      final r = computeCo2(
        entries: [
          _entry(id: 'e', liters: '10.5', fuelType: FuelType.etanol),
          _entry(id: 'g', liters: '20.25', fuelType: FuelType.gasolina),
        ],
        totalKmInPeriod: 0,
      );
      expect(r.totalKg, Decimal.parse('60.7125'));
    });
  });

  group('computeCo2 — GNV convertido em L', () {
    test('GNV: 50L equivalente → 50 * 1.93 = 96.5 kg', () {
      final r = computeCo2(
        entries: [_entry(id: 'g', liters: '50', fuelType: FuelType.gnv)],
        totalKmInPeriod: 0,
      );
      expect(r.totalKg, Decimal.parse('96.50'));
    });
  });

  group('computeCo2 — metadados do período', () {
    test('periodDays calculado corretamente entre datas distintas', () {
      final entries = [
        _entry(
          id: 'a',
          liters: '30',
          fuelType: FuelType.gasolina,
          date: DateTime.utc(2026, 1, 1),
        ),
        _entry(
          id: 'b',
          liters: '30',
          fuelType: FuelType.gasolina,
          date: DateTime.utc(2026, 1, 31),
        ),
      ];
      final r = computeCo2(entries: entries, totalKmInPeriod: 0);
      expect(r.periodDays, 30); // 31 - 1 = 30 dias
      expect(r.entriesCount, 2);
    });

    test('1 abastecimento → periodDays = 0', () {
      final r = computeCo2(
        entries: [_entry(id: 'a', liters: '40', fuelType: FuelType.gasolina)],
        totalKmInPeriod: 0,
      );
      expect(r.periodDays, 0);
    });
  });

  group('computeCo2 — perKmGrams com km positivo', () {
    test('perKm arredondado corretamente para 1 casa', () {
      // 40L etanol * 1.52 = 60.8 kg; 60800 g / 400 km = 152.0 g/km
      final r = computeCo2(
        entries: [_entry(id: 'e', liters: '40', fuelType: FuelType.etanol)],
        totalKmInPeriod: 400,
      );
      expect(r.perKmGrams, Decimal.parse('152.0'));
    });

    test('totalKmInPeriod < 0 → trata como 0 e perKmGrams null', () {
      final r = computeCo2(
        entries: [_entry(id: 'a', liters: '40', fuelType: FuelType.gasolina)],
        totalKmInPeriod: -1,
      );
      expect(r.perKmGrams, isNull);
    });
  });

  group('computeCo2 — equivalência em árvores', () {
    test('21 kg/ano por árvore — ≈N árvores por ano', () {
      // 88.4 kg / 21 = ~4 árvores (floor)
      final r = computeCo2(
        entries: [_entry(id: 'a', liters: '40', fuelType: FuelType.gasolina)],
        totalKmInPeriod: 0,
      );
      // 88.4 / 21 = 4.2... → 4
      expect(r.treesEquivalentYear, 4);
    });
  });
}

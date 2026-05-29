import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/compare/period_compare_calculator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  FuelEntry fuel({
    required String id,
    required DateTime date,
    required int odometer,
    required String liters,
    required String totalCost,
    bool fullTank = true,
    String pricePerLiter = '5.00',
  }) {
    return FuelEntry(
      id: id,
      vehicleId: 'v1',
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

  Expense expense({
    required String id,
    required DateTime date,
    required String amount,
  }) {
    return Expense(
      id: id,
      vehicleId: 'v1',
      date: date,
      category: ExpenseCategory.manutencao,
      description: 'teste',
      amount: Decimal.parse(amount),
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  final jan1 = DateTime.utc(2026, 1, 1);
  final jan31 = DateTime.utc(2026, 1, 31);
  final feb1 = DateTime.utc(2026, 2, 1);
  final feb28 = DateTime.utc(2026, 2, 28);

  // ---------------------------------------------------------------------------
  // defaultMonthRange / defaultYearRange
  // ---------------------------------------------------------------------------

  group('defaultMonthRange', () {
    test('retorna mês corrente e mês anterior', () {
      final now = DateTime(2026, 5, 15);
      final (curr, prev) = defaultMonthRange(now);
      expect(curr.$1, DateTime.utc(2026, 5, 1));
      expect(curr.$2, DateTime.utc(2026, 5, 31, 23, 59, 59));
      expect(prev.$1, DateTime.utc(2026, 4, 1));
      expect(prev.$2, DateTime.utc(2026, 4, 30, 23, 59, 59));
    });

    test('janeiro corrente → dezembro anterior', () {
      final now = DateTime(2026, 1, 10);
      final (curr, prev) = defaultMonthRange(now);
      expect(curr.$1, DateTime.utc(2026, 1, 1));
      expect(prev.$1, DateTime.utc(2025, 12, 1));
      expect(prev.$2, DateTime.utc(2025, 12, 31, 23, 59, 59));
    });
  });

  group('defaultYearRange', () {
    test('retorna ano corrente e ano anterior', () {
      final now = DateTime(2026, 5, 15);
      final (curr, prev) = defaultYearRange(now);
      expect(curr.$1, DateTime.utc(2026, 1, 1));
      expect(curr.$2, DateTime.utc(2026, 12, 31, 23, 59, 59));
      expect(prev.$1, DateTime.utc(2025, 1, 1));
      expect(prev.$2, DateTime.utc(2025, 12, 31, 23, 59, 59));
    });
  });

  // ---------------------------------------------------------------------------
  // computePeriodCompare — casos base
  // ---------------------------------------------------------------------------

  group('computePeriodCompare — totalSpent', () {
    test('soma fuel + expenses no período', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 1, 15),
          odometer: 10000,
          liters: '40',
          totalCost: '200',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 2, 15),
          odometer: 10500,
          liters: '40',
          totalCost: '210',
        ),
      ];
      final expenses = [
        expense(id: 'e1', date: DateTime.utc(2026, 1, 20), amount: '50'),
        expense(id: 'e2', date: DateTime.utc(2026, 2, 10), amount: '80'),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: expenses,
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      // Período atual (fev): 210 + 80 = 290
      expect(result.current.totalSpent, Decimal.parse('290'));
      // Período anterior (jan): 200 + 50 = 250
      expect(result.previous.totalSpent, Decimal.parse('250'));
    });

    test('sem entries no período → totalSpent = 0', () {
      final result = computePeriodCompare(
        entries: const [],
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.current.totalSpent, Decimal.zero);
      expect(result.previous.totalSpent, Decimal.zero);
    });
  });

  // ---------------------------------------------------------------------------
  // Caso 1 — baseline insuficiente → consumo null
  // ---------------------------------------------------------------------------

  group('computePeriodCompare — consumo com baseline insuficiente', () {
    test(
      'período com apenas um abastecimento cheio: baseline insuficiente → avgConsumption null',
      () {
        // Só um cheio no período atual → sem ciclo fechado → null
        final entries = [
          fuel(
            id: 'f1',
            date: DateTime.utc(2026, 2, 5),
            odometer: 10000,
            liters: '40',
            totalCost: '200',
            fullTank: true,
          ),
        ];

        final result = computePeriodCompare(
          entries: entries,
          expenses: const [],
          currentFrom: feb1,
          currentTo: feb28,
          previousFrom: jan1,
          previousTo: jan31,
        );

        expect(result.current.avgConsumption, isNull);
      },
    );

    test(
      'primeiro abastecimento de toda a frota (sem baseline histórico): null',
      () {
        // Todos os abastecimentos são do mesmo período, só um cheio
        final entries = [
          fuel(
            id: 'f1',
            date: DateTime.utc(2026, 1, 10),
            odometer: 5000,
            liters: '30',
            totalCost: '150',
            fullTank: true,
          ),
        ];

        final result = computePeriodCompare(
          entries: entries,
          expenses: const [],
          currentFrom: jan1,
          currentTo: jan31,
          previousFrom: DateTime.utc(2025, 12, 1),
          previousTo: DateTime.utc(2025, 12, 31),
        );

        expect(result.current.avgConsumption, isNull);
      },
    );

    test(
      'período sem entries (previous vazio): avgConsumption null e delta null',
      () {
        // Período atual com dados, anterior sem nada
        final entries = [
          fuel(
            id: 'f1',
            date: DateTime.utc(2026, 2, 1),
            odometer: 10000,
            liters: '0',
            totalCost: '0',
            fullTank: true,
          ),
          fuel(
            id: 'f2',
            date: DateTime.utc(2026, 2, 15),
            odometer: 10500,
            liters: '40',
            totalCost: '200',
            fullTank: true,
          ),
        ];

        final result = computePeriodCompare(
          entries: entries,
          expenses: const [],
          currentFrom: feb1,
          currentTo: feb28,
          previousFrom: jan1,
          previousTo: jan31,
        );

        // Atual tem ciclo fechado, deve calcular
        expect(result.current.avgConsumption, isNotNull);
        // Anterior não tem dados
        expect(result.previous.avgConsumption, isNull);
        // Delta de consumo também deve ser null se um dos lados é null
        expect(result.avgConsumptionDelta, isNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Caso 2 — baseline ok → consumo calculado corretamente
  // ---------------------------------------------------------------------------

  group('computePeriodCompare — baseline ok', () {
    test('dois cheios no período: consumo calculado (km/L)', () {
      // e1 baseline (cheio); e2 fecha ciclo: 500km em 40L → 12.5 km/L
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 2, 1),
          odometer: 10000,
          liters: '0',
          totalCost: '0',
          fullTank: true,
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 2, 20),
          odometer: 10500,
          liters: '40',
          totalCost: '200',
          fullTank: true,
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.current.avgConsumption, Decimal.parse('12.5000'));
    });

    test('baseline vem de ANTES do período (cross-period baseline)', () {
      // O primeiro cheio está em janeiro (fora do período atual fev),
      // mas serve como baseline para o ciclo que fecha em fevereiro.
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 1, 25),
          odometer: 10000,
          liters: '0',
          totalCost: '0',
          fullTank: true,
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 2, 10),
          odometer: 10400,
          liters: '40',
          totalCost: '200',
          fullTank: true,
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      // O ciclo fecha em fev: 400km / 40L = 10km/L
      expect(result.current.avgConsumption, Decimal.parse('10.0000'));
    });
  });

  // ---------------------------------------------------------------------------
  // Caso 3 — distance (distância baseada em odômetro)
  // ---------------------------------------------------------------------------

  group('computePeriodCompare — distance', () {
    test('distance = max(odometer) - min(odometer) no período', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 2, 5),
          odometer: 10200,
          liters: '20',
          totalCost: '100',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 2, 15),
          odometer: 10700,
          liters: '40',
          totalCost: '200',
        ),
        fuel(
          id: 'f3',
          date: DateTime.utc(2026, 2, 25),
          odometer: 11000,
          liters: '30',
          totalCost: '150',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.current.totalKm, 800); // 11000 - 10200
    });

    test(
      'distance com odômetros não sequenciais (desordenados): max - min',
      () {
        // Lançados fora de ordem cronológica (ex: edição manual), mas o
        // algoritmo deve tomar max - min, não primeiro - último.
        final entries = [
          fuel(
            id: 'f1',
            date: DateTime.utc(2026, 2, 10),
            odometer: 10800,
            liters: '30',
            totalCost: '150',
          ),
          fuel(
            id: 'f2',
            date: DateTime.utc(2026, 2, 5),
            odometer: 10300,
            liters: '25',
            totalCost: '125',
          ),
        ];

        final result = computePeriodCompare(
          entries: entries,
          expenses: const [],
          currentFrom: feb1,
          currentTo: feb28,
          previousFrom: jan1,
          previousTo: jan31,
        );

        expect(result.current.totalKm, 500); // 10800 - 10300
      },
    );

    test('período sem entries: distance = 0', () {
      final result = computePeriodCompare(
        entries: const [],
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.current.totalKm, 0);
      expect(result.previous.totalKm, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Caso 4 — deltas
  // ---------------------------------------------------------------------------

  group('computePeriodCompare — deltas', () {
    test('delta de gasto positivo quando atual > anterior', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 1, 15),
          odometer: 10000,
          liters: '40',
          totalCost: '200',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 2, 15),
          odometer: 10500,
          liters: '50',
          totalCost: '300',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      // (300 - 200) / 200 * 100 = 50%
      expect(result.totalSpentDeltaPercent, Decimal.parse('50.0000'));
    });

    test('delta de gasto negativo quando atual < anterior', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 1, 15),
          odometer: 10000,
          liters: '50',
          totalCost: '300',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 2, 15),
          odometer: 10500,
          liters: '40',
          totalCost: '200',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      // (200 - 300) / 300 * 100 = -33.33...%
      expect(result.totalSpentDeltaPercent!.toDouble(), closeTo(-33.33, 0.01));
    });

    test('delta null quando previous totalSpent = 0 (divisão por zero)', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 2, 15),
          odometer: 10500,
          liters: '40',
          totalCost: '200',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.totalSpentDeltaPercent, isNull);
    });

    test('distanceDelta correto', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 1, 5),
          odometer: 10000,
          liters: '40',
          totalCost: '200',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 1, 25),
          odometer: 10400,
          liters: '40',
          totalCost: '200',
        ),
        fuel(
          id: 'f3',
          date: DateTime.utc(2026, 2, 10),
          odometer: 10800,
          liters: '40',
          totalCost: '200',
        ),
        fuel(
          id: 'f4',
          date: DateTime.utc(2026, 2, 28),
          odometer: 11300,
          liters: '50',
          totalCost: '250',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      // jan: 10400 - 10000 = 400; fev: 11300 - 10800 = 500
      expect(result.distanceDelta, 100); // 500 - 400
    });
  });

  // ---------------------------------------------------------------------------
  // Caso 5 — labels
  // ---------------------------------------------------------------------------

  group('computePeriodCompare — labels', () {
    test('label do período é formatado corretamente em PT-BR', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 2, 10),
          odometer: 10000,
          liters: '40',
          totalCost: '200',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.current.label, 'Fev 2026');
      expect(result.previous.label, 'Jan 2026');
    });
  });

  // ---------------------------------------------------------------------------
  // Caso 6 — totalLiters
  // ---------------------------------------------------------------------------

  group('computePeriodCompare — totalLiters', () {
    test('soma dos litros de todos os fuel entries no período', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 2, 5),
          odometer: 10000,
          liters: '35',
          totalCost: '175',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 2, 20),
          odometer: 10500,
          liters: '42',
          totalCost: '210',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.current.totalLiters, Decimal.parse('77'));
    });

    test('delta de litros null quando previous = 0', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 2, 10),
          odometer: 10500,
          liters: '40',
          totalCost: '200',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.litersDeltaPercent, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Caso 7 — entriesCount
  // ---------------------------------------------------------------------------

  group('computePeriodCompare — entriesCount', () {
    test('conta fuel entries do período', () {
      final entries = [
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 2, 5),
          odometer: 10000,
          liters: '35',
          totalCost: '175',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 2, 20),
          odometer: 10500,
          liters: '42',
          totalCost: '210',
        ),
      ];

      final result = computePeriodCompare(
        entries: entries,
        expenses: const [],
        currentFrom: feb1,
        currentTo: feb28,
        previousFrom: jan1,
        previousTo: jan31,
      );

      expect(result.current.entriesCount, 2);
      expect(result.previous.entriesCount, 0);
    });
  });
}

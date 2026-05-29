import 'package:autolog/features/reports/compare/period_compare_models.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PeriodSummary makeSummary({
    String label = 'Jan 2026',
    Decimal? totalSpent,
    Decimal? totalLiters,
    int totalKm = 0,
    int entriesCount = 0,
    Decimal? avgConsumption,
    Decimal? avgPricePerLiter,
  }) {
    return PeriodSummary(
      label: label,
      from: DateTime.utc(2026, 1, 1),
      to: DateTime.utc(2026, 1, 31),
      totalSpent: totalSpent ?? Decimal.zero,
      totalLiters: totalLiters ?? Decimal.zero,
      totalKm: totalKm,
      entriesCount: entriesCount,
      avgConsumption: avgConsumption,
      avgPricePerLiter: avgPricePerLiter,
    );
  }

  PeriodCompareData makeData({
    required PeriodSummary current,
    required PeriodSummary previous,
  }) {
    return PeriodCompareData(current: current, previous: previous);
  }

  group('PeriodCompareData — totalSpentDeltaPercent', () {
    test('delta positivo: atual > anterior', () {
      final data = makeData(
        current: makeSummary(totalSpent: Decimal.parse('300')),
        previous: makeSummary(totalSpent: Decimal.parse('200')),
      );
      // (300-200)/200*100 = 50%
      expect(data.totalSpentDeltaPercent, Decimal.parse('50.0000'));
    });

    test('delta negativo: atual < anterior', () {
      final data = makeData(
        current: makeSummary(totalSpent: Decimal.parse('150')),
        previous: makeSummary(totalSpent: Decimal.parse('200')),
      );
      // (150-200)/200*100 = -25%
      expect(data.totalSpentDeltaPercent, Decimal.parse('-25.0000'));
    });

    test('delta zero: atual == anterior', () {
      final data = makeData(
        current: makeSummary(totalSpent: Decimal.parse('200')),
        previous: makeSummary(totalSpent: Decimal.parse('200')),
      );
      expect(data.totalSpentDeltaPercent, Decimal.zero);
    });

    test('delta null: previous = 0 (divisão por zero)', () {
      final data = makeData(
        current: makeSummary(totalSpent: Decimal.parse('200')),
        previous: makeSummary(totalSpent: Decimal.zero),
      );
      expect(data.totalSpentDeltaPercent, isNull);
    });
  });

  group('PeriodCompareData — litersDeltaPercent', () {
    test('delta positivo', () {
      final data = makeData(
        current: makeSummary(totalLiters: Decimal.parse('60')),
        previous: makeSummary(totalLiters: Decimal.parse('40')),
      );
      // (60-40)/40*100 = 50%
      expect(data.litersDeltaPercent, Decimal.parse('50.0000'));
    });

    test('delta null quando previous = 0', () {
      final data = makeData(
        current: makeSummary(totalLiters: Decimal.parse('40')),
        previous: makeSummary(totalLiters: Decimal.zero),
      );
      expect(data.litersDeltaPercent, isNull);
    });
  });

  group('PeriodCompareData — avgConsumptionDelta (km/L)', () {
    test('delta positivo: mais km/L no atual (melhorou)', () {
      final data = makeData(
        current: makeSummary(avgConsumption: Decimal.parse('13')),
        previous: makeSummary(avgConsumption: Decimal.parse('10')),
      );
      // 13 - 10 = 3 (melhorou)
      expect(data.avgConsumptionDelta, Decimal.parse('3'));
    });

    test('delta negativo: menos km/L no atual (piorou)', () {
      final data = makeData(
        current: makeSummary(avgConsumption: Decimal.parse('9')),
        previous: makeSummary(avgConsumption: Decimal.parse('12')),
      );
      // 9 - 12 = -3 (piorou)
      expect(data.avgConsumptionDelta, Decimal.parse('-3'));
    });

    test('delta null quando current avgConsumption é null', () {
      final data = makeData(
        current: makeSummary(avgConsumption: null),
        previous: makeSummary(avgConsumption: Decimal.parse('12')),
      );
      expect(data.avgConsumptionDelta, isNull);
    });

    test('delta null quando previous avgConsumption é null', () {
      final data = makeData(
        current: makeSummary(avgConsumption: Decimal.parse('12')),
        previous: makeSummary(avgConsumption: null),
      );
      expect(data.avgConsumptionDelta, isNull);
    });
  });

  group('PeriodCompareData — distanceDelta', () {
    test('delta positivo: atual > anterior', () {
      final data = makeData(
        current: makeSummary(totalKm: 600),
        previous: makeSummary(totalKm: 400),
      );
      expect(data.distanceDelta, 200);
    });

    test('delta negativo: atual < anterior', () {
      final data = makeData(
        current: makeSummary(totalKm: 300),
        previous: makeSummary(totalKm: 500),
      );
      expect(data.distanceDelta, -200);
    });

    test('ambos zero → delta zero', () {
      final data = makeData(
        current: makeSummary(totalKm: 0),
        previous: makeSummary(totalKm: 0),
      );
      expect(data.distanceDelta, 0);
    });
  });
}

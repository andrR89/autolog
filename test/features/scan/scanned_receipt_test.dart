import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/scanned_receipt.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.3 — modelo ScannedReceipt.
/// Spec: docs/specs/sprint-3.3-scan-flow.md
void main() {
  group('ScannedReceipt', () {
    test('aceita todos os campos nulos', () {
      const r = ScannedReceipt();
      expect(r.liters, isNull);
      expect(r.pricePerLiter, isNull);
      expect(r.totalCost, isNull);
      expect(r.date, isNull);
      expect(r.fuelType, isNull);
    });

    test(
      'toJson/fromJson roundtrip preserva Decimal exato e enum por wire',
      () {
        final r = ScannedReceipt(
          liters: Decimal.parse('43.219'),
          pricePerLiter: Decimal.parse('5.799'),
          totalCost: Decimal.parse('250.626981'),
          date: DateTime.utc(2026, 5, 23),
          fuelType: FuelType.gasolina,
        );
        final json = r.toJson();
        expect(json['liters'], '43.219');
        expect(json['price_per_liter'], '5.799');
        expect(json['total_cost'], '250.626981');
        expect(json['fuel_type'], 'gasolina');

        final back = ScannedReceipt.fromJson(json);
        expect(back, r);
      },
    );

    test('chaves JSON em snake_case', () {
      final r = ScannedReceipt(
        liters: Decimal.parse('1'),
        pricePerLiter: Decimal.parse('1'),
        totalCost: Decimal.parse('1'),
        date: DateTime.utc(2026, 5, 23),
        fuelType: FuelType.flex,
      );
      final json = r.toJson();
      expect(json.containsKey('price_per_liter'), isTrue);
      expect(json.containsKey('total_cost'), isTrue);
      expect(json.containsKey('fuel_type'), isTrue);
    });
  });
}

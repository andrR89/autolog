import 'package:autolog/features/vehicles/inferred_vehicle_specs.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.L — parse defensivo do InferredVehicleSpecs.
/// Spec: docs/specs/sprint-6.L-infer-vehicle-specs.md
void main() {
  group('InferredVehicleSpecs.fromJson', () {
    test('JSON completo com todos os campos', () {
      final r = InferredVehicleSpecs.fromJson(<String, dynamic>{
        'engine_displacement_cc': 1600,
        'tank_capacity_l': '47.0',
        'horsepower': 124,
        'confidence': 0.85,
      });
      expect(r.engineDisplacementCc, 1600);
      expect(r.tankCapacityL, Decimal.parse('47.0'));
      expect(r.horsepower, 124);
      expect(r.confidence, closeTo(0.85, 0.001));
    });

    test('todos null → modelo todo null com confidence default 0.0', () {
      final r = InferredVehicleSpecs.fromJson(<String, dynamic>{
        'engine_displacement_cc': null,
        'tank_capacity_l': null,
        'horsepower': null,
        'confidence': 0.0,
      });
      expect(r.engineDisplacementCc, isNull);
      expect(r.tankCapacityL, isNull);
      expect(r.horsepower, isNull);
      expect(r.confidence, 0.0);
    });

    test('JSON vazio → modelo todo null e confidence 0.0', () {
      final r = InferredVehicleSpecs.fromJson(<String, dynamic>{});
      expect(r.engineDisplacementCc, isNull);
      expect(r.tankCapacityL, isNull);
      expect(r.horsepower, isNull);
      expect(r.confidence, 0.0);
    });

    test('confidence ausente → default 0.0', () {
      final r = InferredVehicleSpecs.fromJson({
        'engine_displacement_cc': 1600,
      });
      expect(r.confidence, 0.0);
    });

    test('chaves extras ignoradas', () {
      final r = InferredVehicleSpecs.fromJson({
        'engine_displacement_cc': 1600,
        'foo': 'bar',
        'random': 42,
      });
      expect(r.engineDisplacementCc, 1600);
    });

    test('tank_capacity_l como string decimal', () {
      final r = InferredVehicleSpecs.fromJson({'tank_capacity_l': '17.3'});
      expect(r.tankCapacityL, Decimal.parse('17.3'));
    });
  });

  group('InferredVehicleSpecs roundtrip JSON', () {
    test('toJson → fromJson preserva campos', () {
      final original = InferredVehicleSpecs(
        engineDisplacementCc: 600,
        tankCapacityL: Decimal.parse('17.3'),
        horsepower: 78,
        confidence: 0.7,
      );
      final back = InferredVehicleSpecs.fromJson(original.toJson());
      expect(back, original);
    });
  });
}

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/vehicles/inferred_vehicle_specs.dart';
import 'package:autolog/features/vehicles/vehicle_specs_inference_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.L — pipeline do VehicleSpecsInferenceService.
/// Spec: docs/specs/sprint-6.L-infer-vehicle-specs.md

class _FakeInvoker implements EdgeFunctionInvoker {
  _FakeInvoker({this.response, this.throwOnInvoke});
  final Map<String, dynamic>? response;
  final Object? throwOnInvoke;

  String? lastFunctionName;
  Map<String, dynamic>? lastBody;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    callCount++;
    lastFunctionName = functionName;
    lastBody = body;
    if (throwOnInvoke != null) throw throwOnInvoke!;
    return response ?? <String, dynamic>{};
  }
}

void main() {
  group('RealVehicleSpecsInferenceService.infer', () {
    test('invoca "infer-vehicle-specs" com type/make/model/year', () async {
      final invoker = _FakeInvoker(response: <String, dynamic>{
        'engine_displacement_cc': 1600,
        'horsepower': 124,
        'confidence': 0.85,
      });
      final svc = RealVehicleSpecsInferenceService(invoker);

      await svc.infer(
        type: VehicleType.carro,
        make: 'Honda',
        model: 'Civic LX',
        year: 2018,
      );

      expect(invoker.lastFunctionName, 'infer-vehicle-specs');
      expect(invoker.lastBody!['type'], 'carro');
      expect(invoker.lastBody!['make'], 'Honda');
      expect(invoker.lastBody!['model'], 'Civic LX');
      expect(invoker.lastBody!['year'], 2018);
      expect(invoker.callCount, 1);
    });

    test('retorna InferredVehicleSpecs parseado', () async {
      final invoker = _FakeInvoker(response: <String, dynamic>{
        'engine_displacement_cc': 600,
        'tank_capacity_l': '17.3',
        'horsepower': 78,
        'confidence': 0.7,
      });
      final svc = RealVehicleSpecsInferenceService(invoker);
      final r = await svc.infer(
        type: VehicleType.moto,
        make: 'Yamaha',
        model: 'XJ6',
        year: 2014,
      );
      expect(r.engineDisplacementCc, 600);
      expect(r.tankCapacityL, Decimal.parse('17.3'));
      expect(r.horsepower, 78);
      expect(r.confidence, closeTo(0.7, 0.001));
    });

    test('429 → QuotaExhaustedException', () async {
      final invoker = _FakeInvoker(throwOnInvoke: QuotaExhaustedException());
      final svc = RealVehicleSpecsInferenceService(invoker);
      expect(
        svc.infer(
          type: VehicleType.carro,
          make: 'X', model: 'Y', year: 2020,
        ),
        throwsA(isA<QuotaExhaustedException>()),
      );
    });

    test('ScanException existente propaga sem wrap', () async {
      final invoker = _FakeInvoker(throwOnInvoke: ScanException('rede'));
      final svc = RealVehicleSpecsInferenceService(invoker);
      try {
        await svc.infer(
            type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, 'rede');
      }
    });

    test('erro genérico vira ScanException contendo "specs"', () async {
      final invoker = _FakeInvoker(throwOnInvoke: StateError('boom'));
      final svc = RealVehicleSpecsInferenceService(invoker);
      try {
        await svc.infer(
            type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, contains('specs'));
        expect(e.cause, isA<StateError>());
      }
    });
  });

  group('MockVehicleSpecsInferenceService', () {
    test('callCount incrementa, retorna fixedResult', () async {
      const fixed = InferredVehicleSpecs(
        engineDisplacementCc: 2000,
        horsepower: 150,
        confidence: 0.9,
      );
      final mock = MockVehicleSpecsInferenceService(
        delay: Duration.zero,
        fixedResult: fixed,
      );
      await mock.infer(
          type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
      await mock.infer(
          type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
      expect(mock.callCount, 2);
    });

    test('throwOnCall lança ScanException', () async {
      final mock = MockVehicleSpecsInferenceService(
        delay: Duration.zero,
        throwOnCall: true,
      );
      expect(
        mock.infer(
            type: VehicleType.carro, make: 'X', model: 'Y', year: 2020),
        throwsA(isA<ScanException>()),
      );
    });

    test('default retorna specs não-vazios e confidence > 0', () async {
      final mock =
          MockVehicleSpecsInferenceService(delay: Duration.zero);
      final r = await mock.infer(
          type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
      expect(r.engineDisplacementCc, isNotNull);
      expect(r.confidence, greaterThan(0));
    });
  });
}

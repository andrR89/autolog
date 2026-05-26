import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/insights/maintenance_schedule.dart';
import 'package:autolog/features/insights/maintenance_suggestion_service.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.M — pipeline do MaintenanceSuggestionService.
/// Spec: docs/specs/sprint-6.M-maintenance-suggestions.md

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
    return response ?? <String, dynamic>{'items': <dynamic>[]};
  }
}

void main() {
  group('RealMaintenanceSuggestionService.suggest', () {
    test('invoca "suggest-maintenance" com type/make/model/year', () async {
      final invoker = _FakeInvoker();
      final svc = RealMaintenanceSuggestionService(invoker);

      await svc.suggest(
        type: VehicleType.carro,
        make: 'Honda',
        model: 'Civic LX',
        year: 2018,
      );

      expect(invoker.lastFunctionName, 'suggest-maintenance');
      expect(invoker.lastBody!['type'], 'carro');
      expect(invoker.lastBody!['make'], 'Honda');
      expect(invoker.lastBody!['model'], 'Civic LX');
      expect(invoker.lastBody!['year'], 2018);
      expect(invoker.callCount, 1);
    });

    test('passa engine/tank quando fornecidos', () async {
      final invoker = _FakeInvoker();
      final svc = RealMaintenanceSuggestionService(invoker);
      await svc.suggest(
        type: VehicleType.moto,
        make: 'Yamaha',
        model: 'XJ6',
        year: 2014,
        engineDisplacementCc: 600,
        tankCapacityL: Decimal.parse('17.3'),
      );
      expect(invoker.lastBody!['engine_displacement_cc'], 600);
      expect(invoker.lastBody!['tank_capacity_l'], '17.3');
    });

    test('retorna MaintenanceSchedule parseado', () async {
      final invoker = _FakeInvoker(response: {
        'items': [
          {
            'task': 'Troca de óleo',
            'cadence_type': 'km_or_months',
            'every_km': 10000,
            'every_months': 12,
          },
        ],
      });
      final svc = RealMaintenanceSuggestionService(invoker);
      final r = await svc.suggest(
        type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
      expect(r.items.single.task, 'Troca de óleo');
    });

    test('429 → QuotaExhaustedException', () async {
      final invoker = _FakeInvoker(throwOnInvoke: QuotaExhaustedException());
      final svc = RealMaintenanceSuggestionService(invoker);
      expect(
        svc.suggest(type: VehicleType.carro, make: 'X', model: 'Y', year: 2020),
        throwsA(isA<QuotaExhaustedException>()),
      );
    });

    test('ScanException propaga sem wrap', () async {
      final invoker = _FakeInvoker(throwOnInvoke: ScanException('rede'));
      final svc = RealMaintenanceSuggestionService(invoker);
      try {
        await svc.suggest(
            type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, 'rede');
      }
    });

    test('erro genérico vira ScanException contendo "manutenção"', () async {
      final invoker = _FakeInvoker(throwOnInvoke: StateError('boom'));
      final svc = RealMaintenanceSuggestionService(invoker);
      try {
        await svc.suggest(
            type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, contains('manutenção'));
        expect(e.cause, isA<StateError>());
      }
    });
  });

  group('MockMaintenanceSuggestionService', () {
    test('callCount incrementa, retorna fixedResult', () async {
      const fixed = MaintenanceSchedule(items: [
        MaintenanceItem(task: 'X', cadenceType: 'km', everyKm: 5000),
      ]);
      final mock = MockMaintenanceSuggestionService(
        delay: Duration.zero,
        fixedResult: fixed,
      );
      await mock.suggest(
          type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
      await mock.suggest(
          type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
      expect(mock.callCount, 2);
    });

    test('throwOnCall lança ScanException', () async {
      final mock = MockMaintenanceSuggestionService(
        delay: Duration.zero,
        throwOnCall: true,
      );
      expect(
        mock.suggest(type: VehicleType.carro, make: 'X', model: 'Y', year: 2020),
        throwsA(isA<ScanException>()),
      );
    });

    test('default retorna schedule não-vazio', () async {
      final mock = MockMaintenanceSuggestionService(delay: Duration.zero);
      final r = await mock.suggest(
          type: VehicleType.carro, make: 'X', model: 'Y', year: 2020);
      expect(r.items, isNotEmpty);
    });
  });
}

import 'package:autolog/features/insights/history_insights.dart';
import 'package:autolog/features/insights/insights_service.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.G — pipeline do InsightsService.
/// Spec: docs/specs/sprint-6.G-insights.md

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
    return response ?? <String, dynamic>{
      'patterns': <dynamic>[],
      'proposed_reminders': <dynamic>[],
    };
  }
}

void main() {
  group('RealInsightsService.analyze', () {
    test('invoca "analyze-history" com vehicle_id', () async {
      final invoker = _FakeInvoker();
      final svc = RealInsightsService(invoker);
      await svc.analyze('v123');
      expect(invoker.lastFunctionName, 'analyze-history');
      expect(invoker.lastBody!['vehicle_id'], 'v123');
      expect(invoker.callCount, 1);
    });

    test('retorna HistoryInsights parseado', () async {
      final invoker = _FakeInvoker(response: {
        'patterns': [
          {'category': 'ipva', 'cadence': 'yearly', 'confidence': 0.8},
        ],
        'proposed_reminders': [
          {'title': 'IPVA 2027', 'due_date': '2027-01-15T00:00:00.000Z'},
        ],
      });
      final svc = RealInsightsService(invoker);
      final r = await svc.analyze('v1');
      expect(r.patterns.length, 1);
      expect(r.patterns.first.category, 'ipva');
      expect(r.proposedReminders.length, 1);
    });

    test('429 → propaga QuotaExhaustedException', () async {
      final invoker = _FakeInvoker(throwOnInvoke: QuotaExhaustedException());
      final svc = RealInsightsService(invoker);
      expect(svc.analyze('v1'), throwsA(isA<QuotaExhaustedException>()));
    });

    test('ScanException existente propaga sem wrap', () async {
      final invoker = _FakeInvoker(throwOnInvoke: ScanException('rede'));
      final svc = RealInsightsService(invoker);
      try {
        await svc.analyze('v1');
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, 'rede');
      }
    });

    test('erro genérico vira ScanException com mensagem PT-BR', () async {
      final invoker = _FakeInvoker(throwOnInvoke: StateError('x'));
      final svc = RealInsightsService(invoker);
      try {
        await svc.analyze('v1');
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, contains('histórico'));
        expect(e.cause, isA<StateError>());
      }
    });
  });

  group('MockInsightsService', () {
    test('callCount incrementa, retorna fixedResult', () async {
      const fixed = HistoryInsights(
        patterns: [],
        proposedReminders: [],
      );
      final mock = MockInsightsService(
        delay: Duration.zero,
        fixedResult: fixed,
      );
      await mock.analyze('v1');
      await mock.analyze('v2');
      expect(mock.callCount, 2);
    });

    test('throwOnCall lança ScanException', () async {
      final mock = MockInsightsService(
        delay: Duration.zero,
        throwOnCall: true,
      );
      expect(mock.analyze('v1'), throwsA(isA<ScanException>()));
    });

    test('default retorna lista de patterns não-vazia (demo útil)', () async {
      final mock = MockInsightsService(delay: Duration.zero);
      final r = await mock.analyze('v1');
      expect(r.patterns, isNotEmpty);
    });
  });
}

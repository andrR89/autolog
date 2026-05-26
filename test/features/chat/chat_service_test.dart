import 'package:autolog/features/chat/chat_message.dart';
import 'package:autolog/features/chat/chat_service.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.T — pipeline do ChatService.
/// Spec: docs/specs/sprint-6.T-chat-history.md

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
    return response ?? <String, dynamic>{'content': 'oi'};
  }
}

void main() {
  group('RealChatService.ask', () {
    test('invoca "chat-history" com vehicle_id/user_message/recent_history',
        () async {
      final invoker = _FakeInvoker();
      final svc = RealChatService(invoker);

      await svc.ask(
        vehicleId: 'v1',
        userMessage: 'Quanto gastei?',
        recentHistory: [
          ChatMessage(
            id: 'h1', vehicleId: 'v1', role: ChatRole.user,
            content: 'oi', createdAt: DateTime.utc(2026, 5, 26),
          ),
        ],
      );

      expect(invoker.lastFunctionName, 'chat-history');
      expect(invoker.lastBody!['vehicle_id'], 'v1');
      expect(invoker.lastBody!['user_message'], 'Quanto gastei?');
      expect(invoker.lastBody!['recent_history'], isA<List>());
      expect(
        (invoker.lastBody!['recent_history'] as List).first,
        {'role': 'user', 'content': 'oi'},
      );
    });

    test('retorna ChatAnswer com content', () async {
      final invoker = _FakeInvoker(response: {'content': 'Resposta da IA.'});
      final svc = RealChatService(invoker);
      final a = await svc.ask(
        vehicleId: 'v1', userMessage: 'x', recentHistory: const [],
      );
      expect(a.content, 'Resposta da IA.');
    });

    test('429 → QuotaExhaustedException', () async {
      final invoker = _FakeInvoker(throwOnInvoke: QuotaExhaustedException());
      final svc = RealChatService(invoker);
      expect(
        svc.ask(vehicleId: 'v1', userMessage: 'x', recentHistory: const []),
        throwsA(isA<QuotaExhaustedException>()),
      );
    });

    test('ScanException propaga sem wrap', () async {
      final invoker = _FakeInvoker(throwOnInvoke: ScanException('rede'));
      final svc = RealChatService(invoker);
      try {
        await svc.ask(vehicleId: 'v1', userMessage: 'x', recentHistory: const []);
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, 'rede');
      }
    });

    test('erro genérico vira ScanException contendo "assistente"', () async {
      final invoker = _FakeInvoker(throwOnInvoke: StateError('x'));
      final svc = RealChatService(invoker);
      try {
        await svc.ask(vehicleId: 'v1', userMessage: 'x', recentHistory: const []);
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, contains('assistente'));
      }
    });
  });

  group('MockChatService', () {
    test('callCount incrementa, retorna fixedResult', () async {
      const fixed = ChatAnswer(content: 'Resposta fixa');
      final mock = MockChatService(
        delay: Duration.zero,
        fixedResult: fixed,
      );
      await mock.ask(vehicleId: 'v1', userMessage: 'x', recentHistory: const []);
      await mock.ask(vehicleId: 'v1', userMessage: 'y', recentHistory: const []);
      expect(mock.callCount, 2);
    });

    test('throwOnCall lança ScanException', () async {
      final mock = MockChatService(
        delay: Duration.zero,
        throwOnCall: true,
      );
      expect(
        mock.ask(vehicleId: 'v1', userMessage: 'x', recentHistory: const []),
        throwsA(isA<ScanException>()),
      );
    });

    test('default retorna content não-vazio', () async {
      final mock = MockChatService(delay: Duration.zero);
      final r = await mock.ask(
        vehicleId: 'v1', userMessage: 'x', recentHistory: const []);
      expect(r.content.isNotEmpty, isTrue);
    });
  });
}

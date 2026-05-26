import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/features/chat/chat_message.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resposta do assistente de chat.
class ChatAnswer {
  const ChatAnswer({required this.content});

  final String content;
}

/// Contrato do serviço de chat com o histórico do veículo.
///
/// Invoca o backend para obter uma resposta da IA baseada no histórico.
/// Lança [QuotaExhaustedException] quando a cota mensal é atingida.
/// Lança [ScanException] em erros de rede ou da IA.
abstract class ChatService {
  Future<ChatAnswer> ask({
    required String vehicleId,
    required String userMessage,
    required List<ChatMessage> recentHistory,
  });
}

/// Implementação real do [ChatService] que invoca a Edge Function via backend.
///
/// Recebe um [EdgeFunctionInvoker] por injeção — permite fake nos testes.
/// A chave da API Anthropic NUNCA toca este código (Regra de Ouro #4).
class RealChatService implements ChatService {
  RealChatService(this._invoker);

  final EdgeFunctionInvoker _invoker;

  @override
  Future<ChatAnswer> ask({
    required String vehicleId,
    required String userMessage,
    required List<ChatMessage> recentHistory,
  }) async {
    try {
      final body = await _invoker.invoke('chat-history', {
        'vehicle_id': vehicleId,
        'user_message': userMessage,
        'recent_history': recentHistory
            .map((m) => {'role': m.role.name, 'content': m.content})
            .toList(),
      });
      return ChatAnswer(content: body['content'] as String);
    } on QuotaExhaustedException {
      rethrow;
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException('Falha ao consultar o assistente', cause: e);
    }
  }
}

/// Implementação mock do [ChatService] para testes e desenvolvimento.
///
/// Retorna resposta demo por default. Pode ser configurada para:
/// - retornar um [fixedResult] personalizado;
/// - lançar [ScanException] via [throwOnCall];
/// - simular latência via [delay].
class MockChatService implements ChatService {
  MockChatService({
    this.delay = const Duration(milliseconds: 800),
    this.fixedResult,
    this.throwOnCall = false,
  });

  final Duration delay;
  final ChatAnswer? fixedResult;
  final bool throwOnCall;

  /// Número de vezes que [ask] foi chamado.
  int callCount = 0;

  static const _defaultAnswer = ChatAnswer(
    content: r'Você gastou R$ 1.250 com combustível em 2026.',
  );

  @override
  Future<ChatAnswer> ask({
    required String vehicleId,
    required String userMessage,
    required List<ChatMessage> recentHistory,
  }) async {
    callCount++;
    await Future<void>.delayed(delay);
    if (throwOnCall) {
      throw ScanException('Erro simulado pelo MockChatService');
    }
    return fixedResult ?? _defaultAnswer;
  }
}

/// Provider do serviço de chat.
///
/// Retorna [RealChatService] com o [SupabaseEdgeFunctionInvoker] real.
/// Nos testes, use `overrideWithValue(MockChatService())` para isolar.
final chatServiceProvider = Provider<ChatService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealChatService(SupabaseEdgeFunctionInvoker(client));
});

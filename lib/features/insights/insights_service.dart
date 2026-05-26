import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/features/insights/history_insights.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contrato do serviço de análise de histórico.
///
/// Invoca o backend para gerar [HistoryInsights] a partir do histórico do veículo.
/// Lança [ScanException] em caso de erro; [QuotaExhaustedException] se cota esgotada.
abstract class InsightsService {
  Future<HistoryInsights> analyze(String vehicleId);
}

/// Implementação real do [InsightsService] que invoca a Edge Function via backend.
///
/// Recebe um [EdgeFunctionInvoker] por injeção — permite fake nos testes.
/// A chave da API Anthropic NUNCA toca este código (Regra de Ouro #4).
class RealInsightsService implements InsightsService {
  RealInsightsService(this._invoker);

  final EdgeFunctionInvoker _invoker;

  @override
  Future<HistoryInsights> analyze(String vehicleId) async {
    try {
      final body = await _invoker.invoke('analyze-history', {
        'vehicle_id': vehicleId,
      });
      return HistoryInsights.fromJson(body);
    } on QuotaExhaustedException {
      rethrow;
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException('Falha ao analisar histórico', cause: e);
    }
  }
}

/// Implementação mock do [InsightsService] para testes e desenvolvimento.
///
/// Retorna dados demo realistas por default. Pode ser configurada para:
/// - retornar um [fixedResult] personalizado;
/// - lançar [ScanException] via [throwOnCall];
/// - simular latência via [delay].
class MockInsightsService implements InsightsService {
  MockInsightsService({
    this.delay = const Duration(milliseconds: 800),
    this.fixedResult,
    this.throwOnCall = false,
  });

  final Duration delay;
  final HistoryInsights? fixedResult;
  final bool throwOnCall;

  /// Número de vezes que [analyze] foi chamado.
  int callCount = 0;

  // Default não-vazio pra demo útil (testes esperam isNotEmpty em patterns).
  static final _default = HistoryInsights(
    patterns: [
      DetectedPattern(
        category: 'ipva',
        cadence: 'yearly',
        nextDue: DateTime(DateTime.now().year + 1, 1, 15),
        confidence: 0.85,
        rationale: 'Recorrência anual detectada em jan.',
      ),
    ],
    proposedReminders: [
      ProposedReminder(
        title: 'IPVA ${DateTime.now().year + 1}',
        dueDate: DateTime(DateTime.now().year + 1, 1, 15),
        rationale: 'Sugerido a partir do padrão IPVA anual.',
      ),
    ],
  );

  @override
  Future<HistoryInsights> analyze(String vehicleId) async {
    callCount++;
    await Future<void>.delayed(delay);
    if (throwOnCall) {
      throw ScanException('Erro simulado pelo MockInsightsService');
    }
    return fixedResult ?? _default;
  }
}

/// Provider do serviço de insights.
///
/// Retorna [RealInsightsService] com o [SupabaseEdgeFunctionInvoker] real.
/// Nos testes, use `overrideWithValue(MockInsightsService())` para isolar.
final insightsServiceProvider = Provider<InsightsService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealInsightsService(SupabaseEdgeFunctionInvoker(client));
});

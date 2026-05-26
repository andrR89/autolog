import 'dart:convert';
import 'dart:typed_data';

import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_expense.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contrato do serviço de scan de despesa.
///
/// Extrai dados estruturados de uma imagem de comprovante de despesa veicular.
/// Lança [ScanException] em erro real.
abstract class ExpenseScanService {
  Future<ScannedExpense> scan(Uint8List imageBytes);
}

/// Implementação real do [ExpenseScanService] que invoca a Edge Function via backend.
///
/// Recebe um [EdgeFunctionInvoker] por injeção — permite fake nos testes.
/// A chave da API Anthropic NUNCA toca este código (Regra de Ouro #4).
class RealExpenseScanService implements ExpenseScanService {
  RealExpenseScanService(this._invoker);

  final EdgeFunctionInvoker _invoker;

  @override
  Future<ScannedExpense> scan(Uint8List imageBytes) async {
    final encoded = base64Encode(imageBytes);
    try {
      final body = await _invoker.invoke('scan-expense', {
        'image_base64': encoded,
      });
      return ScannedExpense.fromJson(body);
    } on QuotaExhaustedException {
      rethrow;
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException('Falha ao escanear comprovante', cause: e);
    }
  }
}

/// Implementação mock do [ExpenseScanService] para uso em testes.
///
/// Retorna dados fake realistas. Pode ser configurada para:
/// - retornar um [fixedResult] personalizado;
/// - lançar [ScanException] via [throwOnCall];
/// - simular latência via [delay].
class MockExpenseScanService implements ExpenseScanService {
  MockExpenseScanService({
    this.delay = const Duration(milliseconds: 800),
    this.fixedResult,
    this.throwOnCall = false,
  });

  final Duration delay;
  final ScannedExpense? fixedResult;
  final bool throwOnCall;

  /// Número de vezes que [scan] foi chamado.
  int callCount = 0;

  static final _defaultExpense = ScannedExpense(
    amount: Decimal.parse('250.00'),
    category: ExpenseCategory.manutencao,
    date: DateTime.now(),
  );

  @override
  Future<ScannedExpense> scan(Uint8List imageBytes) async {
    callCount++;
    await Future<void>.delayed(delay);
    if (throwOnCall) {
      throw ScanException('Erro simulado pelo MockExpenseScanService');
    }
    return fixedResult ?? _defaultExpense;
  }
}

/// Provider do serviço de scan de despesa.
///
/// Retorna [RealExpenseScanService] com o [SupabaseEdgeFunctionInvoker] real.
/// Nos testes, use `overrideWithValue(MockExpenseScanService())` ou
/// `overrideWithValue(RealExpenseScanService(_FakeInvoker()))` para isolar.
final expenseScanServiceProvider = Provider<ExpenseScanService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealExpenseScanService(SupabaseEdgeFunctionInvoker(client));
});

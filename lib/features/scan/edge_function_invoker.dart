import 'dart:convert';

import 'package:autolog/features/scan/scan_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstração do invocador de Edge Functions.
///
/// Permite injetar um fake em testes sem depender do Supabase real.
/// A implementação real usa [SupabaseClient]; os testes usam [_FakeInvoker].
abstract class EdgeFunctionInvoker {
  /// Invoca a função com o [functionName] e o [body] dado.
  ///
  /// Retorna o JSON body decodificado em caso de sucesso.
  /// Lança [QuotaExhaustedException] em 429 (cota esgotada).
  /// Outras falhas lançam [ScanException].
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  );
}

/// Implementação real do [EdgeFunctionInvoker] usando [SupabaseClient].
class SupabaseEdgeFunctionInvoker implements EdgeFunctionInvoker {
  SupabaseEdgeFunctionInvoker(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final FunctionResponse resp;
    try {
      resp = await _client.functions.invoke(functionName, body: body);
    } on FunctionException catch (e) {
      // Supabase Flutter SDK packs status + details in FunctionException.
      if (e.status == 429) {
        throw QuotaExhaustedException();
      }
      throw ScanException('Erro ao chamar função (${e.status})', cause: e);
    } catch (e) {
      throw ScanException('Erro de rede ao escanear cupom', cause: e);
    }

    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // fall through
      }
    }
    throw ScanException('Resposta inesperada da função');
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_crlv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contrato do serviço de scan de CRLV.
///
/// Extrai dados estruturados de uma imagem ou PDF de CRLV-e.
/// Lança [QuotaExhaustedException] quando a cota mensal é atingida.
/// Lança [ScanException] em erro real.
abstract class CrlvScanService {
  Future<ScannedCrlv> scan(Uint8List bytes, {required String mimeType});
}

/// Implementação real do [CrlvScanService] que invoca a Edge Function via backend.
///
/// Recebe um [EdgeFunctionInvoker] por injeção — permite fake nos testes.
/// A chave da API Anthropic NUNCA toca este código (Regra de Ouro #4).
class RealCrlvScanService implements CrlvScanService {
  RealCrlvScanService(this._invoker);

  final EdgeFunctionInvoker _invoker;

  @override
  Future<ScannedCrlv> scan(Uint8List bytes, {required String mimeType}) async {
    final encoded = base64Encode(bytes);
    try {
      final body = await _invoker.invoke('scan-crlv', {
        'document_base64': encoded,
        'mime_type': mimeType,
      });
      return ScannedCrlv.fromJson(body);
    } on QuotaExhaustedException {
      rethrow;
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException('Falha ao escanear CRLV', cause: e);
    }
  }
}

/// Implementação mock do [CrlvScanService] para uso em testes.
///
/// Retorna dados fake realistas. Pode ser configurada para:
/// - retornar um [fixedResult] personalizado;
/// - lançar [ScanException] via [throwOnCall];
/// - simular latência via [delay].
class MockCrlvScanService implements CrlvScanService {
  MockCrlvScanService({
    this.delay = const Duration(milliseconds: 800),
    this.fixedResult,
    this.throwOnCall = false,
  });

  final Duration delay;
  final ScannedCrlv? fixedResult;
  final bool throwOnCall;

  /// Número de vezes que [scan] foi chamado.
  int callCount = 0;

  static const _default = ScannedCrlv(
    plate: 'ABC1D23',
    make: 'Honda',
    model: 'CIVIC LX 1.7',
    year: 2018,
    color: 'preto',
    fuelType: FuelType.flex,
  );

  @override
  Future<ScannedCrlv> scan(Uint8List bytes, {required String mimeType}) async {
    callCount++;
    await Future<void>.delayed(delay);
    if (throwOnCall) {
      throw ScanException('Erro simulado por MockCrlvScanService');
    }
    return fixedResult ?? _default;
  }
}

/// Provider do serviço de scan de CRLV.
///
/// Retorna [RealCrlvScanService] com o [SupabaseEdgeFunctionInvoker] real.
/// Nos testes, use `overrideWithValue(MockCrlvScanService())` para isolar.
final crlvScanServiceProvider = Provider<CrlvScanService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealCrlvScanService(SupabaseEdgeFunctionInvoker(client));
});

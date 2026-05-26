import 'dart:convert';
import 'dart:typed_data';

import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scanned_receipt.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contrato do serviço de scan de cupom.
///
/// Extrai dados estruturados de uma imagem de cupom.
/// Lança [ScanException] em erro real.
/// Cancelamento não passa por aqui — é tratado upstream pelo [ImageSource].
abstract class ScanService {
  Future<ScannedReceipt> scan(Uint8List imageBytes);
}

/// Exceção de scan com mensagem legível e causa opcional.
class ScanException implements Exception {
  ScanException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ScanException: $message';
}

/// Implementação mock do [ScanService] para uso em testes e Sprint 3.3.
///
/// Retorna dados fake realistas. Pode ser configurada para:
/// - retornar um [fixedResult] personalizado;
/// - lançar [ScanException] via [throwOnCall];
/// - simular latência via [delay].
class MockScanService implements ScanService {
  MockScanService({
    this.delay = const Duration(milliseconds: 800),
    this.fixedResult,
    this.throwOnCall = false,
  });

  final Duration delay;
  final ScannedReceipt? fixedResult;
  final bool throwOnCall;

  /// Número de vezes que [scan] foi chamado.
  int callCount = 0;

  static final _defaultReceipt = ScannedReceipt(
    liters: Decimal.parse('42.5'),
    pricePerLiter: Decimal.parse('5.79'),
    totalCost: Decimal.parse('246.07'),
    date: DateTime.now(),
    fuelType: FuelType.gasolina,
  );

  @override
  Future<ScannedReceipt> scan(Uint8List imageBytes) async {
    callCount++;
    await Future<void>.delayed(delay);
    if (throwOnCall) {
      throw ScanException('Erro simulado pelo MockScanService');
    }
    return fixedResult ?? _defaultReceipt;
  }
}

/// Exceção lançada quando o usuário esgotou a cota de scans do mês.
///
/// Subtipo de [ScanException] para permitir catch específico na UI (Sprint 3.5).
class QuotaExhaustedException extends ScanException {
  QuotaExhaustedException()
    : super('Cota de scan esgotada — vire premium ou siga manual');
}

/// Implementação real do [ScanService] que invoca a Edge Function via backend.
///
/// Recebe um [EdgeFunctionInvoker] por injeção — permite fake nos testes.
/// A chave da API Anthropic NUNCA toca este código (Regra de Ouro #4).
class RealScanService implements ScanService {
  RealScanService(this._invoker);

  final EdgeFunctionInvoker _invoker;

  @override
  Future<ScannedReceipt> scan(Uint8List imageBytes) async {
    final encoded = base64Encode(imageBytes);
    try {
      final body = await _invoker.invoke('scan-receipt', {
        'image_base64': encoded,
      });
      return ScannedReceipt.fromJson(body);
    } on QuotaExhaustedException {
      rethrow; // a UI/form decide o que fazer (Sprint 3.5)
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException('Falha inesperada ao escanear cupom', cause: e);
    }
  }
}

/// Provider do serviço de scan.
///
/// Retorna [RealScanService] com o [SupabaseEdgeFunctionInvoker] real.
/// Nos testes, use `overrideWithValue(MockScanService())` ou
/// `overrideWithValue(RealScanService(_FakeInvoker()))` para isolar.
final scanServiceProvider = Provider<ScanService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealScanService(SupabaseEdgeFunctionInvoker(client));
});

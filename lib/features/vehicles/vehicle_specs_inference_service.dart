import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/vehicles/inferred_vehicle_specs.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contrato do serviço de inferência de specs técnicos de veículo via IA.
///
/// Dado `{type, make, model, year}`, retorna specs inferidos (cilindrada,
/// tanque, cavalos) com uma pontuação de confiança.
/// Lança [QuotaExhaustedException] quando a cota mensal é atingida.
/// Lança [ScanException] em erro real.
abstract class VehicleSpecsInferenceService {
  Future<InferredVehicleSpecs> infer({
    required VehicleType type,
    required String make,
    required String model,
    required int year,
  });
}

/// Implementação real que invoca a Edge Function `infer-vehicle-specs`.
///
/// A chave da API Anthropic NUNCA toca este código (Regra de Ouro #4).
class RealVehicleSpecsInferenceService implements VehicleSpecsInferenceService {
  RealVehicleSpecsInferenceService(this._invoker);

  final EdgeFunctionInvoker _invoker;

  @override
  Future<InferredVehicleSpecs> infer({
    required VehicleType type,
    required String make,
    required String model,
    required int year,
  }) async {
    try {
      final body = await _invoker.invoke('infer-vehicle-specs', {
        'type': type.wire,
        'make': make,
        'model': model,
        'year': year,
      });
      return InferredVehicleSpecs.fromJson(body);
    } on QuotaExhaustedException {
      rethrow;
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException('Falha ao inferir specs do veículo', cause: e);
    }
  }
}

/// Implementação mock do [VehicleSpecsInferenceService] para testes e dev.
///
/// Retorna specs fake realistas. Pode ser configurada para:
/// - retornar um [fixedResult] personalizado;
/// - lançar [ScanException] via [throwOnCall];
/// - simular latência via [delay].
class MockVehicleSpecsInferenceService implements VehicleSpecsInferenceService {
  MockVehicleSpecsInferenceService({
    this.delay = const Duration(milliseconds: 800),
    this.fixedResult,
    this.throwOnCall = false,
  });

  final Duration delay;
  final InferredVehicleSpecs? fixedResult;
  final bool throwOnCall;

  /// Número de vezes que [infer] foi chamado.
  int callCount = 0;

  static final _default = InferredVehicleSpecs(
    engineDisplacementCc: 1600,
    tankCapacityL: Decimal.parse('47'),
    horsepower: 124,
    confidence: 0.85,
  );

  @override
  Future<InferredVehicleSpecs> infer({
    required VehicleType type,
    required String make,
    required String model,
    required int year,
  }) async {
    callCount++;
    await Future<void>.delayed(delay);
    if (throwOnCall) {
      throw ScanException('Erro simulado por MockVehicleSpecsInferenceService');
    }
    return fixedResult ?? _default;
  }
}

/// Provider do serviço de inferência de specs.
///
/// Retorna [RealVehicleSpecsInferenceService] com o [SupabaseEdgeFunctionInvoker] real.
/// Nos testes, use `overrideWithValue(MockVehicleSpecsInferenceService())` para isolar.
final vehicleSpecsInferenceServiceProvider =
    Provider<VehicleSpecsInferenceService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealVehicleSpecsInferenceService(SupabaseEdgeFunctionInvoker(client));
});

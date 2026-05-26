import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/insights/maintenance_schedule.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contrato do serviço de sugestão de calendário de manutenção via IA.
///
/// Dado `{type, make, model, year, engineDisplacementCc?, tankCapacityL?,
/// vehicleUf?, currentOdometerKm?}`,
/// retorna uma lista típica de manutenções para o veículo informado.
/// Lança [QuotaExhaustedException] quando a cota mensal é atingida.
/// Lança [ScanException] em erro real.
abstract class MaintenanceSuggestionService {
  Future<MaintenanceSchedule> suggest({
    required VehicleType type,
    required String make,
    required String model,
    required int year,
    int? engineDisplacementCc,
    Decimal? tankCapacityL,
    String? vehicleUf,
    int? currentOdometerKm,
  });
}

/// Implementação real que invoca a Edge Function `suggest-maintenance`.
///
/// A chave da API Anthropic NUNCA toca este código (Regra de Ouro #4).
class RealMaintenanceSuggestionService
    implements MaintenanceSuggestionService {
  RealMaintenanceSuggestionService(this._invoker);

  final EdgeFunctionInvoker _invoker;

  @override
  Future<MaintenanceSchedule> suggest({
    required VehicleType type,
    required String make,
    required String model,
    required int year,
    int? engineDisplacementCc,
    Decimal? tankCapacityL,
    String? vehicleUf,
    int? currentOdometerKm,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type.wire,
        'make': make,
        'model': model,
        'year': year,
      };
      if (engineDisplacementCc != null) {
        body['engine_displacement_cc'] = engineDisplacementCc;
      }
      if (tankCapacityL != null) {
        body['tank_capacity_l'] = tankCapacityL.toString();
      }
      if (vehicleUf != null) {
        body['vehicle_uf'] = vehicleUf;
      }
      if (currentOdometerKm != null) {
        body['current_odometer_km'] = currentOdometerKm;
      }

      final response = await _invoker.invoke('suggest-maintenance', body);
      return MaintenanceSchedule.fromJson(response);
    } on QuotaExhaustedException {
      rethrow;
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException(
        'Falha ao buscar sugestões de manutenção',
        cause: e,
      );
    }
  }
}

/// Implementação mock do [MaintenanceSuggestionService] para testes e dev.
///
/// Retorna um calendário padrão realista. Pode ser configurada para:
/// - retornar um [fixedResult] personalizado;
/// - lançar [ScanException] via [throwOnCall];
/// - simular latência via [delay].
class MockMaintenanceSuggestionService
    implements MaintenanceSuggestionService {
  MockMaintenanceSuggestionService({
    this.delay = const Duration(milliseconds: 800),
    this.fixedResult,
    this.throwOnCall = false,
  });

  final Duration delay;
  final MaintenanceSchedule? fixedResult;
  final bool throwOnCall;

  /// Número de vezes que [suggest] foi chamado.
  int callCount = 0;

  static const _default = MaintenanceSchedule(items: [
    MaintenanceItem(
      task: 'Troca de óleo',
      cadenceType: 'km_or_months',
      everyKm: 10000,
      everyMonths: 12,
    ),
    MaintenanceItem(
      task: 'Filtro de ar',
      cadenceType: 'km',
      everyKm: 20000,
    ),
    MaintenanceItem(
      task: 'Pastilhas de freio',
      cadenceType: 'km',
      everyKm: 30000,
    ),
    MaintenanceItem(
      task: 'Velas',
      cadenceType: 'km',
      everyKm: 40000,
    ),
    MaintenanceItem(
      task: 'Correia dentada',
      cadenceType: 'km',
      everyKm: 60000,
    ),
    MaintenanceItem(
      task: 'Fluido de freio',
      cadenceType: 'months',
      everyMonths: 24,
    ),
  ]);

  @override
  Future<MaintenanceSchedule> suggest({
    required VehicleType type,
    required String make,
    required String model,
    required int year,
    int? engineDisplacementCc,
    Decimal? tankCapacityL,
    String? vehicleUf,
    int? currentOdometerKm,
  }) async {
    callCount++;
    await Future<void>.delayed(delay);
    if (throwOnCall) {
      throw ScanException(
        'Erro simulado por MockMaintenanceSuggestionService',
      );
    }
    return fixedResult ?? _default;
  }
}

/// Provider do serviço de sugestão de manutenção.
///
/// Retorna [RealMaintenanceSuggestionService] com o [SupabaseEdgeFunctionInvoker] real.
/// Nos testes, use `overrideWithValue(MockMaintenanceSuggestionService())` para isolar.
final maintenanceSuggestionServiceProvider =
    Provider<MaintenanceSuggestionService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealMaintenanceSuggestionService(SupabaseEdgeFunctionInvoker(client));
});

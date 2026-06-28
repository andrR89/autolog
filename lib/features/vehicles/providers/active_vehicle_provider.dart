// Provider do veículo "ativo" — o que está em foco na NavigationRail desktop.
//
// activeVehicleIdProvider: StateNotifier<String?> persistido em SharedPreferences.
// activeVehicleProvider: FutureProvider<Vehicle?> derivado que resolve o Vehicle.

import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Chave de persistência
// ---------------------------------------------------------------------------

const _kActiveVehicleKey = 'active_vehicle_id';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Mantém o id do veículo atualmente em foco na navegação desktop.
///
/// Estado inicial é `null` (nenhum veículo selecionado). Após [loadInitial]
/// ser chamado, reflete o último veículo persistido em SharedPreferences.
///
/// [setActive] é idempotente: chamar com o mesmo valor não escreve em prefs.
class ActiveVehicleNotifier extends StateNotifier<String?> {
  ActiveVehicleNotifier() : super(null) {
    loadInitial();
  }

  /// Carrega o valor inicial de SharedPreferences.
  ///
  /// Exposto como público para permitir `await` em testes.
  Future<void> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kActiveVehicleKey);
    if (mounted) state = stored;
  }

  /// Define o veículo ativo.
  ///
  /// Idempotente: se [id] já é o state atual, não toca em prefs.
  /// Passa [null] para limpar a seleção.
  Future<void> setActive(String? id) async {
    if (id == state) return;
    state = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_kActiveVehicleKey);
    } else {
      await prefs.setString(_kActiveVehicleKey, id);
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Id do veículo ativo, persistido em SharedPreferences.
///
/// `null` = nenhum veículo selecionado (ex: tela da Garagem, Documentos).
final activeVehicleIdProvider =
    StateNotifierProvider<ActiveVehicleNotifier, String?>(
      (ref) => ActiveVehicleNotifier(),
    );

/// Veículo ativo resolvido — combina [activeVehicleIdProvider] com o repositório.
///
/// Retorna `null` quando não há id ativo ou o id não encontra veículo no banco.
final activeVehicleProvider = FutureProvider<Vehicle?>((ref) async {
  final id = ref.watch(activeVehicleIdProvider);
  if (id == null) return null;

  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getById(id);
});

// Providers Riverpod para o sistema de filtros do histórico de abastecimentos.
//
// Arquitetura:
//   fuelFilterStateProvider (StateNotifierProvider.family)
//     → mantém FuelFilterState por veículo (isolado)
//   filteredFuelEntriesProvider (Provider.family)
//     → combina stream de entries + estado do filtro → lista final

import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/filters/fuel_filter.dart';
import 'package:autolog/features/fuel/filters/fuel_filter_state.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// FuelFilterNotifier — StateNotifier para FuelFilterState
// ---------------------------------------------------------------------------

/// Notifier que gerencia o estado de filtro para um veículo específico.
///
/// Exposto via [fuelFilterStateProvider].
class FuelFilterNotifier extends StateNotifier<FuelFilterState> {
  FuelFilterNotifier() : super(FuelFilterState());

  /// Aplica um [FuelFilterState] completo (vindo do bottom sheet ao apertar "Aplicar").
  void apply(FuelFilterState newState) => state = newState;

  /// Reseta todos os filtros para o estado padrão.
  void clear() => state = FuelFilterState();

  /// Atualiza apenas o tipo de combustível.
  void setFuelType(String? fuelType) =>
      state = state.copyWith(fuelType: fuelType);

  /// Atualiza apenas a query de posto.
  void setStationQuery(String? query) =>
      state = state.copyWith(stationQuery: query);

  /// Atualiza apenas a busca livre.
  void setTextQuery(String? query) => state = state.copyWith(textQuery: query);

  /// Atualiza apenas o período.
  void setPeriod(dynamic period) => state = state.copyWith(period: period);

  /// Atualiza apenas a ordenação.
  void setSortBy(FuelSortBy sortBy) => state = state.copyWith(sortBy: sortBy);

  /// Atualiza apenas o toggle tanque cheio.
  void setOnlyFullTank(bool value) =>
      state = state.copyWith(onlyFullTank: value);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Estado de filtro por veículo (vehicleId → FuelFilterState).
///
/// Cada veículo mantém seu próprio estado de filtro independente.
final fuelFilterStateProvider =
    StateNotifierProvider.family<FuelFilterNotifier, FuelFilterState, String>(
      (ref, vehicleId) => FuelFilterNotifier(),
    );

/// Lista de [FuelEntry] filtrada e ordenada para um veículo.
///
/// Combina o stream reativo de [fuelEntriesByVehicleProvider] com o
/// [fuelFilterStateProvider]. Emite nova lista sempre que:
/// - O banco local atualiza (nova entry, delete, sync).
/// - O usuário muda os critérios de filtro.
///
/// A filtragem é client-only sobre o stream existente — sem queries adicionais
/// ao banco (Regra de Ouro: offline-first; evitar bloqueio de UI).
final filteredFuelEntriesProvider =
    Provider.family<AsyncValue<List<FuelEntry>>, String>((ref, vehicleId) {
      final entriesAsync = ref.watch(fuelEntriesByVehicleProvider(vehicleId));
      final filter = ref.watch(fuelFilterStateProvider(vehicleId));

      return entriesAsync.whenData(
        (entries) => applyFuelFilter(entries, filter),
      );
    });

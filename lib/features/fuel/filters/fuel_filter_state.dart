// Estado dos filtros da tela de histórico de abastecimentos.
//
// Imutável via freezed. A classe carrega todos os critérios de filtro +
// ordenação. Dois getters computados — hasActiveFilters e activeCount —
// guiam a badge do AppBar e o botão "Limpar tudo".

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fuel_filter_state.freezed.dart';

/// Ordenação disponível para o histórico de abastecimentos.
enum FuelSortBy {
  /// Data decrescente (padrão — mais recente primeiro).
  dateDesc,

  /// Data crescente (mais antigo primeiro).
  dateAsc,

  /// Valor total decrescente.
  totalDesc,

  /// Valor total crescente.
  totalAsc,

  /// Volume de litros decrescente.
  litersDesc,

  /// Volume de litros crescente.
  litersAsc;

  /// Rótulo PT-BR para exibição no Dropdown.
  String get label => switch (this) {
    dateDesc => 'Data (mais recente)',
    dateAsc => 'Data (mais antiga)',
    totalDesc => 'Maior valor',
    totalAsc => 'Menor valor',
    litersDesc => 'Maior volume',
    litersAsc => 'Menor volume',
  };
}

@freezed
abstract class FuelFilterState with _$FuelFilterState {
  // O construtor privado vazio é exigido pelo freezed para habilitar
  // getters customizados na classe.
  const FuelFilterState._();

  // ignore: sort_unnamed_constructors_first
  factory FuelFilterState({
    /// Tipo de combustível exato. null = todos.
    /// Valores canônicos: "gasolina", "etanol", "diesel", "gnv".
    String? fuelType,

    /// Substring case-insensitive em stationName. null = sem filtro.
    String? stationQuery,

    /// Período inclusivo. null = todos.
    DateTimeRange? period,

    /// Busca livre em notes/station/fuelType. null = sem filtro.
    String? textQuery,

    /// Critério de ordenação. Default: dateDesc.
    @Default(FuelSortBy.dateDesc) FuelSortBy sortBy,

    /// Quando true, exibe apenas abastecimentos com tanque cheio.
    @Default(false) bool onlyFullTank,
  }) = _FuelFilterState;

  // -------------------------------------------------------------------------
  // Getters computados
  // -------------------------------------------------------------------------

  /// True se qualquer filtro está diferente do default.
  bool get hasActiveFilters =>
      fuelType != null ||
      (stationQuery?.isNotEmpty ?? false) ||
      period != null ||
      (textQuery?.isNotEmpty ?? false) ||
      sortBy != FuelSortBy.dateDesc ||
      onlyFullTank;

  /// Quantidade de filtros ativos (para badge).
  ///
  /// Conta cada critério independentemente:
  /// - fuelType: +1
  /// - stationQuery: +1
  /// - period: +1
  /// - textQuery: +1
  /// - sortBy ≠ default: +1
  /// - onlyFullTank: +1
  int get activeCount {
    var count = 0;
    if (fuelType != null) count++;
    if (stationQuery?.isNotEmpty ?? false) count++;
    if (period != null) count++;
    if (textQuery?.isNotEmpty ?? false) count++;
    if (sortBy != FuelSortBy.dateDesc) count++;
    if (onlyFullTank) count++;
    return count;
  }
}

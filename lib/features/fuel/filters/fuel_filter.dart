// Função pura de filtragem e ordenação do histórico de abastecimentos.
//
// Não tem efeitos colaterais: recebe [FuelEntry]s + [FuelFilterState] e
// devolve uma nova lista filtrada e ordenada. Totalmente testável sem
// Flutter/Riverpod.

import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/filters/fuel_filter_state.dart';

/// Aplica [filter] sobre [entries] e retorna lista filtrada + ordenada.
///
/// Garantias:
/// - Nunca muta a lista original.
/// - Comparação de texto case-insensitive (toLowerCase).
/// - Período: inclusivo em ambos os extremos (início 00:00, fim 23:59:59).
/// - Ordenação estável: tiebreaker por id (String.compareTo) para saídas
///   determinísticas em qualquer cenário de teste ou produção.
/// - Lista vazia → lista vazia (nenhuma exceção).
List<FuelEntry> applyFuelFilter(
  List<FuelEntry> entries,
  FuelFilterState filter,
) {
  if (entries.isEmpty) return const [];

  // -------------------------------------------------------------------------
  // 1. Filtragem
  // -------------------------------------------------------------------------

  final result = entries.where((e) {
    // — Tipo de combustível —
    if (filter.fuelType != null) {
      if (e.fuelType.wire != filter.fuelType) return false;
    }

    // — Posto (substring case-insensitive em stationName) —
    final sq = filter.stationQuery;
    if (sq != null && sq.isNotEmpty) {
      final station = (e.stationName ?? '').toLowerCase();
      if (!station.contains(sq.toLowerCase())) return false;
    }

    // — Período inclusivo —
    final period = filter.period;
    if (period != null) {
      // Normaliza: início = 00:00:00.000 do dia; fim = 23:59:59.999 do dia.
      final startDay = DateTime(
        period.start.year,
        period.start.month,
        period.start.day,
      );
      final endDay = DateTime(
        period.end.year,
        period.end.month,
        period.end.day,
        23,
        59,
        59,
        999,
      );
      final entryDay = DateTime(e.date.year, e.date.month, e.date.day);
      if (entryDay.isBefore(startDay) || entryDay.isAfter(endDay)) {
        return false;
      }
    }

    // — Busca livre (textQuery em notes/station/fuelType) —
    // FuelEntry não tem campo "notes" no modelo atual; pesquisamos em:
    //   stationName, stationBrand, fuelType.wire
    final tq = filter.textQuery;
    if (tq != null && tq.isNotEmpty) {
      final needle = tq.toLowerCase();
      final haystack = [
        e.stationName ?? '',
        e.stationBrand ?? '',
        e.fuelType.wire,
      ].join(' ').toLowerCase();
      if (!haystack.contains(needle)) return false;
    }

    // — Somente tanque cheio —
    if (filter.onlyFullTank && !e.fullTank) return false;

    return true;
  }).toList();

  // -------------------------------------------------------------------------
  // 2. Ordenação estável (tiebreaker: id ascendente)
  // -------------------------------------------------------------------------

  result.sort((a, b) {
    int primary;
    switch (filter.sortBy) {
      case FuelSortBy.dateDesc:
        primary = b.date.compareTo(a.date);
      case FuelSortBy.dateAsc:
        primary = a.date.compareTo(b.date);
      case FuelSortBy.totalDesc:
        primary = b.totalCost.compareTo(a.totalCost);
      case FuelSortBy.totalAsc:
        primary = a.totalCost.compareTo(b.totalCost);
      case FuelSortBy.litersDesc:
        primary = b.liters.compareTo(a.liters);
      case FuelSortBy.litersAsc:
        primary = a.liters.compareTo(b.liters);
    }
    if (primary != 0) return primary;
    // Tiebreaker determinístico: id lexicográfico ascendente.
    return a.id.compareTo(b.id);
  });

  return result;
}

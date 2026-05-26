import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/station_aggregation.dart';

/// Resultado do cálculo de posto preferido para um conjunto de abastecimentos.
class FavoriteStationInsight {
  const FavoriteStationInsight({
    required this.favorite,
    required this.cheapestQualified,
    required this.topByFrequency,
  });

  /// Posto mais frequentado (maior entriesCount). null se nenhum identificado.
  final StationStats? favorite;

  /// Posto com menor avgPricePerLiter entre os com >= minVisitsForCheapest.
  /// null se nenhum qualifica.
  final StationStats? cheapestQualified;

  /// Top N postos por frequência (entriesCount DESC).
  final List<StationStats> topByFrequency;
}

/// Calcula insight de "posto preferido" a partir de FuelEntries.
///
/// Filtra entries sem brand E sem name (não contam pra ranking — grupo
/// "sem identificação" que vem do aggregator).
///
/// [minVisitsForCheapest] — só estações com >= N visitas elegíveis pra
/// "mais barato" (default 3, evita 1 abastecimento sortudo).
/// [topLimit] — quantos no ranking por frequência (default 5).
FavoriteStationInsight analyzeFavoriteStation(
  List<FuelEntry> entries, {
  int minVisitsForCheapest = 3,
  int topLimit = 5,
}) {
  // 1. Agregar via aggregateByStation (reuse — não duplicar lógica).
  final all = aggregateByStation(entries);

  // 2. Filtrar OUT estações sem brand E sem name (sem identificação útil).
  final identified = all
      .where((s) => s.brand != null || s.name != null)
      .toList();

  if (identified.isEmpty) {
    return const FavoriteStationInsight(
      favorite: null,
      cheapestQualified: null,
      topByFrequency: [],
    );
  }

  // 3. favorite = max entriesCount, desempate por lastEntryDate DESC.
  identified.sort((a, b) {
    final byCount = b.entriesCount.compareTo(a.entriesCount);
    if (byCount != 0) return byCount;
    return b.lastEntryDate.compareTo(a.lastEntryDate);
  });
  final favorite = identified.first;

  // 4. cheapestQualified = menor avgPricePerLiter entre os com >= minVisits.
  final qualified = identified
      .where((s) => s.entriesCount >= minVisitsForCheapest)
      .toList()
    ..sort((a, b) => a.avgPricePerLiter.compareTo(b.avgPricePerLiter));
  final cheapest = qualified.isEmpty ? null : qualified.first;

  // 5. topByFrequency = top N por entriesCount (já ordenados acima).
  final top = identified.take(topLimit).toList();

  return FavoriteStationInsight(
    favorite: favorite,
    cheapestQualified: cheapest,
    topByFrequency: top,
  );
}

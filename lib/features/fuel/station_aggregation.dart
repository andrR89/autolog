import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/station_brands.dart';
import 'package:decimal/decimal.dart';

/// Estatísticas agregadas por posto/bandeira.
class StationStats {
  const StationStats({
    required this.brand,
    required this.name,
    required this.entriesCount,
    required this.totalLiters,
    required this.totalSpent,
    required this.avgPricePerLiter,
    required this.lastEntryDate,
  });

  /// Bandeira do posto (ex.: "Shell"). null = grupo sem identificação.
  final String? brand;

  /// Nome do posto (ex.: "Posto Shell BR-101 km 87"). null = sem nome.
  final String? name;

  /// Quantidade de abastecimentos nesse grupo.
  final int entriesCount;

  /// Soma dos litros abastecidos.
  final Decimal totalLiters;

  /// Soma do valor gasto.
  final Decimal totalSpent;

  /// Média do preço por litro = totalSpent / totalLiters, scale 4.
  final Decimal avgPricePerLiter;

  /// Data do abastecimento mais recente no grupo.
  final DateTime lastEntryDate;
}

/// Agrupa abastecimentos por (brand normalizado + '|' + name normalizado).
///
/// Entradas sem brand E sem name vão para o grupo com chave vazia "".
/// Ordena por [entriesCount] DESC (mais frequentes primeiro).
///
/// brand/name do grupo = primeiro valor não-vazio encontrado (preserva
/// a capitalização original do usuário — só agrupa pelo normalizado).
List<StationStats> aggregateByStation(List<FuelEntry> entries) {
  if (entries.isEmpty) return const [];

  // Estrutura auxiliar para acumular dados por chave normalizada.
  final Map<String, _Accumulator> groups = {};

  for (final entry in entries) {
    final normBrand =
        entry.stationBrand != null ? normalizeStation(entry.stationBrand!) : '';
    final normName =
        entry.stationName != null ? normalizeStation(entry.stationName!) : '';

    final key = '$normBrand|$normName';

    if (groups.containsKey(key)) {
      groups[key]!.add(entry);
    } else {
      groups[key] = _Accumulator(
        firstBrand: entry.stationBrand,
        firstName: entry.stationName,
      )..add(entry);
    }
  }

  // Converte para StationStats.
  final result = groups.values.map((acc) {
    final totalLiters = acc.totalLiters;
    final totalSpent = acc.totalSpent;

    final Decimal avg;
    if (totalLiters == Decimal.zero) {
      avg = Decimal.zero;
    } else {
      // Usa 5 dígitos intermediários e arredonda para 4 casas decimais (HALF_UP).
      avg = (totalSpent / totalLiters)
          .toDecimal(scaleOnInfinitePrecision: 5)
          .round(scale: 4);
    }

    return StationStats(
      brand: acc.brand,
      name: acc.name,
      entriesCount: acc.entriesCount,
      totalLiters: totalLiters,
      totalSpent: totalSpent,
      avgPricePerLiter: avg,
      lastEntryDate: acc.lastEntryDate,
    );
  }).toList();

  // Ordena por entriesCount DESC.
  result.sort((a, b) => b.entriesCount.compareTo(a.entriesCount));

  return result;
}

// ---------------------------------------------------------------------------
// Auxiliar interno
// ---------------------------------------------------------------------------

class _Accumulator {
  _Accumulator({required String? firstBrand, required String? firstName})
      : brand = firstBrand,
        name = firstName;

  /// Primeiro brand/name não-nulo encontrado (preserva capitalização original).
  String? brand;
  String? name;

  int entriesCount = 0;
  Decimal totalLiters = Decimal.zero;
  Decimal totalSpent = Decimal.zero;
  DateTime? _lastEntryDate;

  DateTime get lastEntryDate => _lastEntryDate!;

  void add(FuelEntry entry) {
    entriesCount++;
    totalLiters += entry.liters;
    totalSpent += entry.totalCost;

    if (_lastEntryDate == null || entry.date.isAfter(_lastEntryDate!)) {
      _lastEntryDate = entry.date;
    }

    // Preserva o primeiro brand/name não-nulo (primeira aparição ganha).
    brand ??= entry.stationBrand;
    name ??= entry.stationName;
  }
}

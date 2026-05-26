import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

class MonthlyConsumption {
  const MonthlyConsumption({required this.month, required this.kmPerLiter});
  final DateTime month;
  final Decimal kmPerLiter;
}

class _Bucket {
  int km = 0;
  Decimal liters = Decimal.zero;
}

/// Agrega consumo médio (km/l) ponderado por km, por mês.
///
/// Espera entries do mesmo veículo, ordenados por data ASC.
/// Retorna lista ASC por mês. Meses sem ciclos fechados NÃO aparecem.
///
/// Regras (PRD §7 + spec sprint-5.2):
/// - Mês do ciclo = mês da entry que **fecha** o ciclo (cheio que define o consumo).
/// - Consumo mensal = sum(km dos ciclos que fecham no mês) / sum(litros dos ciclos).
/// - Ciclos com km <= 0 ou litros == 0 são ignorados.
List<MonthlyConsumption> computeMonthlyConsumption(List<FuelEntry> entriesAsc) {
  if (entriesAsc.isEmpty) return [];

  final Map<DateTime, _Bucket> acc = {};
  DateTime bucketOf(DateTime d) => DateTime.utc(d.year, d.month, 1);

  int? lastFullIndex;

  for (int i = 0; i < entriesAsc.length; i++) {
    final cur = entriesAsc[i];

    if (cur.fullTank && lastFullIndex != null) {
      final km = cur.odometer - entriesAsc[lastFullIndex].odometer;

      var liters = Decimal.zero;
      for (int j = lastFullIndex + 1; j <= i; j++) {
        liters = liters + entriesAsc[j].liters;
      }

      if (km > 0 && liters > Decimal.zero) {
        final bucket = bucketOf(cur.date);
        final b = acc.putIfAbsent(bucket, _Bucket.new);
        b.km += km;
        b.liters = b.liters + liters;
      }
    }

    // Atualiza baseline mesmo quando km <= 0 (defensivo, igual à 2.2).
    if (cur.fullTank) lastFullIndex = i;
  }

  final keys = acc.keys.toList()..sort();
  return [
    for (final k in keys)
      MonthlyConsumption(
        month: k,
        kmPerLiter: (Decimal.fromInt(acc[k]!.km) / acc[k]!.liters)
            .toDecimal(scaleOnInfinitePrecision: 4)
            .round(scale: 4),
      ),
  ];
}

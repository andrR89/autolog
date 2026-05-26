import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

class MonthlyPrice {
  const MonthlyPrice({required this.month, required this.pricePerLiter});
  final DateTime month;
  final Decimal pricePerLiter;
}

class _Bucket {
  Decimal cost = Decimal.zero;
  Decimal liters = Decimal.zero;
}

List<MonthlyPrice> computeMonthlyPrice(List<FuelEntry> fuelEntries) {
  if (fuelEntries.isEmpty) return [];
  final Map<DateTime, _Bucket> acc = {};
  DateTime bucketOf(DateTime d) => DateTime.utc(d.year, d.month, 1);

  for (final e in fuelEntries) {
    final b = acc.putIfAbsent(bucketOf(e.date), _Bucket.new);
    b.cost = b.cost + e.totalCost;
    b.liters = b.liters + e.liters;
  }

  final keys = acc.keys.toList()..sort();
  return [
    for (final k in keys)
      if (acc[k]!.liters > Decimal.zero)
        MonthlyPrice(
          month: k,
          pricePerLiter: (acc[k]!.cost / acc[k]!.liters)
              .toDecimal(scaleOnInfinitePrecision: 4)
              .round(scale: 4),
        ),
  ];
}

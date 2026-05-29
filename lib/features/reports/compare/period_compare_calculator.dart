import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/compare/period_compare_models.dart';
import 'package:decimal/decimal.dart';

// ---------------------------------------------------------------------------
// Helpers de intervalo
// ---------------------------------------------------------------------------

/// Retorna (período atual, período anterior) para comparação mês a mês.
///
/// current = mês de [now]; previous = mês anterior.
/// Cada par é (DateTime from (UTC), DateTime to (UTC) inclusive até 23:59:59).
((DateTime, DateTime) current, (DateTime, DateTime) previous) defaultMonthRange(
  DateTime now,
) {
  final currFrom = DateTime.utc(now.year, now.month, 1);
  final currTo = _lastMomentOfMonth(now.year, now.month);

  final prevYear = now.month == 1 ? now.year - 1 : now.year;
  final prevMonth = now.month == 1 ? 12 : now.month - 1;
  final prevFrom = DateTime.utc(prevYear, prevMonth, 1);
  final prevTo = _lastMomentOfMonth(prevYear, prevMonth);

  return ((currFrom, currTo), (prevFrom, prevTo));
}

/// Retorna (período atual, período anterior) para comparação ano a ano.
((DateTime, DateTime) current, (DateTime, DateTime) previous) defaultYearRange(
  DateTime now,
) {
  final currFrom = DateTime.utc(now.year, 1, 1);
  final currTo = DateTime.utc(now.year, 12, 31, 23, 59, 59);
  final prevFrom = DateTime.utc(now.year - 1, 1, 1);
  final prevTo = DateTime.utc(now.year - 1, 12, 31, 23, 59, 59);
  return ((currFrom, currTo), (prevFrom, prevTo));
}

DateTime _lastMomentOfMonth(int year, int month) {
  // O último dia do mês é o dia anterior ao dia 1 do próximo mês.
  final lastDay = DateTime.utc(
    year,
    month + 1,
    1,
  ).subtract(const Duration(days: 1));
  return DateTime.utc(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
}

// ---------------------------------------------------------------------------
// Calculadora principal
// ---------------------------------------------------------------------------

/// Computa a comparação entre dois períodos a partir das listas completas
/// de [FuelEntry] e [Expense] do veículo.
///
/// Não filtra por `deletedAt` — o caller já deve fornecer entradas ativas.
///
/// ### Regra de consumo (PRD §7 / Regra de Ouro #2)
/// - avgConsumption é calculado usando a lógica de tanque cheio.
/// - Para encontrar o baseline mais recente ANTES do período, percorremos
///   todas as entries ordenadas e usamos o último cheio antes da from.
/// - null quando não há ciclo fechado no período (baseline insuficiente).
PeriodCompareData computePeriodCompare({
  required List<FuelEntry> entries,
  required List<Expense> expenses,
  required DateTime currentFrom,
  required DateTime currentTo,
  required DateTime previousFrom,
  required DateTime previousTo,
}) {
  // Ordenar entries por data ASC (critério: date).
  final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));

  final current = _buildSummary(
    allEntries: sorted,
    expenses: expenses,
    from: currentFrom,
    to: currentTo,
  );
  final previous = _buildSummary(
    allEntries: sorted,
    expenses: expenses,
    from: previousFrom,
    to: previousTo,
  );

  return PeriodCompareData(current: current, previous: previous);
}

PeriodSummary _buildSummary({
  required List<FuelEntry> allEntries,
  required List<Expense> expenses,
  required DateTime from,
  required DateTime to,
}) {
  // Entries DO período
  final periodEntries = allEntries
      .where((e) => !e.date.isBefore(from) && !e.date.isAfter(to))
      .toList();

  // Expenses DO período
  final periodExpenses = expenses
      .where((e) => !e.date.isBefore(from) && !e.date.isAfter(to))
      .toList();

  // --- totalSpent = fuel total + expense amounts ---
  var fuelTotal = Decimal.zero;
  for (final e in periodEntries) {
    fuelTotal = fuelTotal + e.totalCost;
  }
  var expTotal = Decimal.zero;
  for (final e in periodExpenses) {
    expTotal = expTotal + e.amount;
  }
  final totalSpent = fuelTotal + expTotal;

  // --- totalLiters ---
  var totalLiters = Decimal.zero;
  for (final e in periodEntries) {
    totalLiters = totalLiters + e.liters;
  }

  // --- totalKm = max(odometer) - min(odometer) no período ---
  int totalKm = 0;
  if (periodEntries.isNotEmpty) {
    final odoms = periodEntries.map((e) => e.odometer);
    totalKm =
        odoms.reduce((a, b) => a > b ? a : b) -
        odoms.reduce((a, b) => a < b ? a : b);
  }

  // --- avgConsumption — lógica de tanque cheio (PRD §7) ---
  // Encontrar o último cheio ANTES da from (baseline cross-period).
  // Depois percorrer as entries do período buscando ciclos fechados.
  final Decimal? avgConsumption = _computeAvgConsumption(
    allEntries: allEntries,
    from: from,
    to: to,
  );

  // --- avgPricePerLiter ponderado por litros ---
  Decimal? avgPricePerLiter;
  if (totalLiters > Decimal.zero) {
    avgPricePerLiter = (fuelTotal / totalLiters)
        .toDecimal(scaleOnInfinitePrecision: 4)
        .round(scale: 4);
  }

  // --- label ---
  final label = _periodLabel(from, to);

  return PeriodSummary(
    label: label,
    from: from,
    to: to,
    totalSpent: totalSpent,
    totalLiters: totalLiters,
    totalKm: totalKm,
    entriesCount: periodEntries.length,
    avgConsumption: avgConsumption,
    avgPricePerLiter: avgPricePerLiter,
  );
}

/// Calcula consumo médio (km/L) ponderado por km para o período.
///
/// Algoritmo:
/// 1. Procura o último fullTank ANTES de [from] → baseline de partida.
/// 2. Percorre as entries do período ASC buscando ciclos cheio→cheio.
/// 3. Soma km e litros de todos os ciclos válidos que FECHAM no período.
/// 4. Retorna km_total / litros_total, ou null se não há ciclo fechado.
Decimal? _computeAvgConsumption({
  required List<FuelEntry> allEntries,
  required DateTime from,
  required DateTime to,
}) {
  // Separar entries antes do período e no período
  final beforePeriod = allEntries.where((e) => e.date.isBefore(from)).toList();
  final inPeriod = allEntries
      .where((e) => !e.date.isBefore(from) && !e.date.isAfter(to))
      .toList();

  // Baseline = o fullTank mais recente antes do período (se existir)
  FuelEntry? baseline;
  for (final e in beforePeriod.reversed) {
    if (e.fullTank) {
      baseline = e;
      break;
    }
  }

  // Acumular km e litros de ciclos válidos que fecham no período
  int accumKm = 0;
  Decimal accumLiters = Decimal.zero;

  // "current cycle" começa do baseline (se existir), senão aguarda o
  // primeiro fullTank no período.
  FuelEntry? lastFull = baseline;

  for (final entry in inPeriod) {
    if (entry.fullTank && lastFull != null) {
      final km = entry.odometer - lastFull.odometer;

      // Coletar litros ENTRE o lastFull (exclusive) e entry (inclusive)
      // dentro de toda a lista allEntries
      final allSorted = allEntries; // já ordenado ASC pelo caller
      final idxLast = allSorted.indexOf(lastFull);
      final idxEntry = allSorted.indexOf(entry);

      var liters = Decimal.zero;
      if (idxLast >= 0 && idxEntry >= 0 && idxEntry > idxLast) {
        for (int j = idxLast + 1; j <= idxEntry; j++) {
          liters = liters + allSorted[j].liters;
        }
      } else {
        // Fallback: só os litros da entry que fecha o ciclo
        liters = entry.liters;
      }

      if (km > 0 && liters > Decimal.zero) {
        accumKm += km;
        accumLiters = accumLiters + liters;
      }
    }

    if (entry.fullTank) lastFull = entry;
  }

  if (accumKm == 0 || accumLiters == Decimal.zero) return null;

  return (Decimal.fromInt(accumKm) / accumLiters)
      .toDecimal(scaleOnInfinitePrecision: 4)
      .round(scale: 4);
}

// Nomes de meses abreviados em PT-BR — sem dependência de initializeDateFormatting.
// Capitalizados para uso em labels de UI (ex: "Fev 2026").
const _monthNamesCapitalized = [
  'Jan', // 1
  'Fev', // 2
  'Mar', // 3
  'Abr', // 4
  'Mai', // 5
  'Jun', // 6
  'Jul', // 7
  'Ago', // 8
  'Set', // 9
  'Out', // 10
  'Nov', // 11
  'Dez', // 12
];

/// Formata o label do período:
/// - mesmo mês/ano → "Fev 2026"
/// - ano inteiro → "2026"
/// - intervalo customizado → "Jan – Jun 2026"
String _periodLabel(DateTime from, DateTime to) {
  // Mesmo mês/ano → label de mês
  if (from.year == to.year && from.month == to.month) {
    return '${_monthNamesCapitalized[from.month - 1]} ${from.year}';
  }

  // Ano inteiro (jan a dez, mesmo ano)
  if (from.month == 1 && to.month == 12 && from.year == to.year) {
    return '${from.year}';
  }

  // Intervalo customizado: "Jan – Jun 2026"
  return '${_monthNamesCapitalized[from.month - 1]} – '
      '${_monthNamesCapitalized[to.month - 1]} ${to.year}';
}

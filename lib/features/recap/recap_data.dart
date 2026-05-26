// recap_data.dart — Função pura de cálculo do Recap mensal/semanal.
//
// Sem efeitos colaterais, sem I/O. Recebe listas brutas de FuelEntry e Expense
// e retorna um RecapData com todos os indicadores do período.
//
// Spec: docs/specs/sprint-6.V-recap-wrapped.md

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/station_aggregation.dart';
import 'package:decimal/decimal.dart';

// ---------------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------------

enum RecapPeriod { week, month }

// ---------------------------------------------------------------------------
// Modelo de resultado
// ---------------------------------------------------------------------------

class RecapData {
  const RecapData({
    required this.period,
    required this.start,
    required this.end,
    required this.totalSpent,
    required this.fuelSpent,
    required this.expensesSpent,
    required this.kmDriven,
    required this.fuelEntriesCount,
    required this.expensesCount,
    required this.avgConsumptionKmL,
    required this.cheapestPricePerLiter,
    required this.mostExpensivePricePerLiter,
    required this.favoriteStation,
    required this.topExpenseCategory,
  });

  final RecapPeriod period;
  final DateTime start;
  final DateTime end;

  /// Total = fuelSpent + expensesSpent.
  final Decimal totalSpent;

  /// Soma dos totalCost dos abastecimentos no período.
  final Decimal fuelSpent;

  /// Soma dos amount das despesas no período.
  final Decimal expensesSpent;

  /// Diferença max-min do hodômetro entre fuels no período. 0 se < 2 fuels.
  final int kmDriven;

  /// Quantidade de abastecimentos no período.
  final int fuelEntriesCount;

  /// Quantidade de despesas no período.
  final int expensesCount;

  /// km/L = kmDriven / totalLiters, arredondado a 4 casas. Null se kmDriven == 0.
  final Decimal? avgConsumptionKmL;

  /// Menor pricePerLiter entre os fuels do período. Null se nenhum fuel.
  final Decimal? cheapestPricePerLiter;

  /// Maior pricePerLiter entre os fuels do período. Null se nenhum fuel.
  final Decimal? mostExpensivePricePerLiter;

  /// Posto mais frequente formatado como "{brand ?? '—'} • {name ?? 'Posto'}".
  /// Null se nenhum fuel com brand/name identificado.
  final String? favoriteStation;

  /// Categoria de despesa mais frequente em PT-BR. Null se nenhuma despesa.
  final String? topExpenseCategory;
}

// ---------------------------------------------------------------------------
// Função pura
// ---------------------------------------------------------------------------

/// Calcula o [RecapData] para o [period] relativo ao instante [now].
///
/// Range:
/// - [RecapPeriod.week]  → [now - 7 dias, now] (inclusive nos dois lados).
/// - [RecapPeriod.month] → [1º dia de now.year/now.month 00:00 UTC, now].
///
/// [fuels] e [expenses] são listas **brutas** (todos os veículos do usuário);
/// a filtragem por data é feita aqui.
RecapData computeRecap({
  required RecapPeriod period,
  required DateTime now,
  required List<FuelEntry> fuels,
  required List<Expense> expenses,
}) {
  // 1. Determina o range.
  final DateTime start;
  final DateTime end = now;

  switch (period) {
    case RecapPeriod.week:
      start = DateTime.utc(now.year, now.month, now.day)
          .subtract(const Duration(days: 7));
    case RecapPeriod.month:
      start = DateTime.utc(now.year, now.month, 1);
  }

  // 2. Filtra por range (>= start, <= end — datas são UTC).
  final inFuels = fuels.where((f) {
    final d = f.date;
    return !d.isBefore(start) && !d.isAfter(end);
  }).toList();

  final inExpenses = expenses.where((e) {
    final d = e.date;
    return !d.isBefore(start) && !d.isAfter(end);
  }).toList();

  // 3. fuelSpent / expensesSpent / totalSpent.
  final fuelSpent = inFuels.fold(
    Decimal.zero,
    (sum, f) => sum + f.totalCost,
  );
  final expensesSpent = inExpenses.fold(
    Decimal.zero,
    (sum, e) => sum + e.amount,
  );
  final totalSpent = fuelSpent + expensesSpent;

  // 4. kmDriven.
  final int kmDriven;
  if (inFuels.length >= 2) {
    final odomList = inFuels.map((f) => f.odometer).toList();
    odomList.sort();
    kmDriven = odomList.last - odomList.first;
  } else {
    kmDriven = 0;
  }

  // 5. avgConsumptionKmL.
  Decimal? avgConsumptionKmL;
  if (kmDriven > 0) {
    final totalLiters = inFuels.fold(
      Decimal.zero,
      (sum, f) => sum + f.liters,
    );
    if (totalLiters > Decimal.zero) {
      avgConsumptionKmL = (Decimal.fromInt(kmDriven) / totalLiters)
          .toDecimal(scaleOnInfinitePrecision: 5)
          .round(scale: 4);
    }
  }

  // 6. cheapest / mostExpensive pricePerLiter.
  Decimal? cheapest;
  Decimal? mostExpensive;
  if (inFuels.isNotEmpty) {
    for (final f in inFuels) {
      final p = f.pricePerLiter;
      if (cheapest == null || p < cheapest) cheapest = p;
      if (mostExpensive == null || p > mostExpensive) mostExpensive = p;
    }
  }

  // 7. favoriteStation — usa aggregateByStation, filtra identificados, pega top.
  String? favoriteStation;
  if (inFuels.isNotEmpty) {
    final stats = aggregateByStation(inFuels);
    final identified = stats.where((s) => s.brand != null || s.name != null);
    if (identified.isNotEmpty) {
      final top = identified.first;
      final brand = top.brand ?? '—';
      final name = top.name ?? 'Posto';
      favoriteStation = '$brand • $name';
    }
  }

  // 8. topExpenseCategory — mode por category → PT-BR.
  String? topExpenseCategory;
  if (inExpenses.isNotEmpty) {
    final counts = <ExpenseCategory, int>{};
    for (final e in inExpenses) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final topCat = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    topExpenseCategory = _categoryLabel(topCat);
  }

  return RecapData(
    period: period,
    start: start,
    end: end,
    totalSpent: totalSpent,
    fuelSpent: fuelSpent,
    expensesSpent: expensesSpent,
    kmDriven: kmDriven,
    fuelEntriesCount: inFuels.length,
    expensesCount: inExpenses.length,
    avgConsumptionKmL: avgConsumptionKmL,
    cheapestPricePerLiter: cheapest,
    mostExpensivePricePerLiter: mostExpensive,
    favoriteStation: favoriteStation,
    topExpenseCategory: topExpenseCategory,
  );
}

// ---------------------------------------------------------------------------
// Helper local — PT-BR labels para categorias
// ---------------------------------------------------------------------------

String _categoryLabel(ExpenseCategory cat) => switch (cat) {
      ExpenseCategory.manutencao => 'Manutenção',
      ExpenseCategory.lavagem => 'Lavagem',
      ExpenseCategory.estacionamento => 'Estacionamento',
      ExpenseCategory.multa => 'Multas',
      ExpenseCategory.seguro => 'Seguro',
      ExpenseCategory.ipva => 'IPVA',
      ExpenseCategory.licenciamento => 'Licenciamento',
      ExpenseCategory.outro => 'Outros',
    };

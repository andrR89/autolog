import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/services/consumption_calculator.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Snapshot agregado do mês corrente para a faixa de stats do hero.
class CurrentMonthStats {
  const CurrentMonthStats({
    required this.label,
    required this.totalSpend,
    required this.entryCount,
  });

  /// Label "MAIO/2026" (uppercase) — pronto para eyebrow.
  final String label;

  /// Soma de [FuelEntry.totalCost] do mês corrente.
  final Decimal totalSpend;

  /// Quantidade de [FuelEntry] no mês corrente.
  final int entryCount;
}

/// Computa stats do mês corrente sobre uma lista de entries em qualquer
/// ordem. [now] é injetável para testes (default: DateTime.now()).
CurrentMonthStats computeCurrentMonthStats(
  List<FuelEntry> entries, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final label = DateFormat(
    'MMMM/yyyy',
    'pt_BR',
  ).format(reference).toUpperCase();

  var spend = Decimal.zero;
  var count = 0;
  for (final entry in entries) {
    if (entry.date.year == reference.year &&
        entry.date.month == reference.month) {
      spend = spend + entry.totalCost;
      count += 1;
    }
  }

  return CurrentMonthStats(label: label, totalSpend: spend, entryCount: count);
}

/// Métrica "hero" do veículo. Estratégia conservadora:
/// - Pega o último cheio com baseline (km/L calculado != null), em ordem
///   decrescente por data.
/// - Se nenhum cheio fechou janela ainda, retorna null (UI mostra "—" e
///   um convite a registrar mais um cheio).
///
/// [rows] deve estar em ordem decrescente por data (mesma ordem da lista).
Decimal? pickHeroKmPerLiter(List<ConsumptionRow> rows) {
  for (final row in rows) {
    if (row.kmPerLiter != null) return row.kmPerLiter;
  }
  return null;
}

/// Adapta o output do [computeConsumption] (que espera ordem ASC por data)
/// para a ordem DESC usada na lista (mais recente primeiro), mantendo o
/// mesmo [ConsumptionRow] por entry.
///
/// [descByDate] deve estar ordenado decrescente (mais recente primeiro),
/// que é a ordem natural do repositório.
List<ConsumptionRow> computeForDisplay(List<FuelEntry> descByDate) {
  if (descByDate.isEmpty) return [];
  final asc = descByDate.reversed.toList();
  final computed = computeConsumption(asc);
  return computed.reversed.toList();
}

/// Formata [value] em km/l com 1 casa decimal PT-BR.
///
/// Exemplo: `Decimal.parse('12.5')` → "12,5 km/l".
/// Null → "—".
String formatKmPerLiter(Decimal? value) {
  if (value == null) return '—';
  final formatted = NumberFormat('0.0', 'pt_BR').format(value.toDouble());
  return '$formatted km/l';
}

/// Formata [value] em custo por km com 2 casas decimais PT-BR.
///
/// Exemplo: `Decimal.parse('0.55')` → "R\$ 0,55/km".
/// Null → "—".
String formatCostPerKm(Decimal? value) {
  if (value == null) return '—';
  final formatted = NumberFormat('0.00', 'pt_BR').format(value.toDouble());
  return 'R\$ $formatted/km';
}

/// Formata [value] em moeda BRL com separador de milhar e 2 casas decimais.
///
/// Exemplo: `Decimal.parse('1234.56')` → "R\$ 1.234,56".
/// O [Decimal] vira [double] APENAS para a formatação — nunca alimenta cálculos.
String formatCurrencyBr(Decimal value) {
  // Usa padrão explícito e concatena símbolo para evitar problemas de espaço
  // não-separável que a intl pode inserir no locale pt_BR.
  final formatted = NumberFormat('#,##0.00', 'pt_BR').format(value.toDouble());
  return 'R\$ $formatted';
}

/// Formata [value] em litros com 3 casas decimais PT-BR.
///
/// Exemplo: `Decimal.parse('43.219')` → "43,219 L".
String formatLitersBr(Decimal value) {
  final formatted = NumberFormat('0.000', 'pt_BR').format(value.toDouble());
  return '$formatted L';
}

/// Formata [date] no padrão brasileiro dd/MM/yyyy.
///
/// Exemplo: `DateTime.utc(2026, 5, 23)` → "23/05/2026".
String formatDateBr(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

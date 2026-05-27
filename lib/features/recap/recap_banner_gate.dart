// Gating contextual do banner de Recap em Reports (Sprint 6.W.2).
//
// O Recap não é entry-point permanente. Aparece como banner discreto APENAS
// em dois momentos do calendário (e só se há dados suficientes):
//
//   1. Primeiros 7 dias do mês  → banner do "Recap de [mês anterior]"
//   2. Últimos 5 dias do mês    → banner do "Recap do mês atual"
//
// Fora desses momentos, o banner não aparece — o user ainda pode acessar o
// Recap manualmente por outro entry-point (menu/ícone).

/// Mínimo de entries combinadas (fuel + expense) pra contar uma história.
const int kRecapMinEntries = 3;

enum RecapShowDecision { hide, currentMonth, previousMonth }

class RecapBannerSuggestion {
  const RecapBannerSuggestion({
    required this.decision,
    this.periodLabel,
  });

  /// `null` quando [decision] = hide.
  final String? periodLabel;
  final RecapShowDecision decision;
}

const _ptBrMonths = <String>[
  '', // index 0 não usado
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// Decide se/como mostrar o banner de Recap em [now].
///
/// - [currentMonthEntries]: count combinado de fuel + expense no mês de [now].
/// - [previousMonthEntries]: count do mês anterior (pra recap pós-fechamento).
///
/// Prioridade: mês anterior > mês atual (recap fechado é mais valioso).
RecapBannerSuggestion shouldShowRecapBanner({
  required DateTime now,
  required int currentMonthEntries,
  required int previousMonthEntries,
}) {
  // 1. Primeiros 7 dias do mês — recap do mês anterior (fechado).
  if (now.day <= 7 && previousMonthEntries >= kRecapMinEntries) {
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    return RecapBannerSuggestion(
      decision: RecapShowDecision.previousMonth,
      periodLabel: _ptBrMonths[prevMonth],
    );
  }

  // 2. Últimos 5 dias do mês — recap do mês atual em andamento.
  final daysInMonth = DateTime.utc(now.year, now.month + 1, 0).day;
  if (daysInMonth - now.day < 5 &&
      currentMonthEntries >= kRecapMinEntries) {
    return RecapBannerSuggestion(
      decision: RecapShowDecision.currentMonth,
      periodLabel: _ptBrMonths[now.month],
    );
  }

  return const RecapBannerSuggestion(decision: RecapShowDecision.hide);
}

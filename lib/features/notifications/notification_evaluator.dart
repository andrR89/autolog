// Detector puro de notificações proativas (Sprint 6.U).
//
// Combina 3 fontes de sinal já existentes:
//  - `analyzeConsumptionTrend` (6.Q) pra detectar consumo piorando.
//  - `suggestFiscalReminders` (6.N) pra IPVA/licenciamento próximos.
//  - `UserProfile.cnhExpiresAt` pra CNH vencendo.
//
// Prioriza fiscal > cnh > consumption_drop. Dedupe de 7 dias por categoria
// usando o histórico `recentLog` (vindo da tabela local `notifications_log`).

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/insights/fiscal_calendar.dart';
import 'package:autolog/features/insights/history_insights.dart' show ProposedReminder;
import 'package:autolog/features/recap/recap_banner_gate.dart' show kRecapMinEntries;
import 'package:autolog/features/reports/trend_analyzer.dart';
import 'package:decimal/decimal.dart';

const _ptBrMonthsForRecap = <String>[
  '',
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

class NotificationProposal {
  const NotificationProposal({
    required this.category,
    required this.title,
    required this.body,
  });

  final String category;
  final String title;
  final String body;
}

/// Avalia todos os detectores e devolve a primeira proposta acionável.
///
/// Prioridade fixa: `fiscal` > `cnh` > `consumption_drop`. Cada categoria
/// respeita dedupe de 7 dias contra [recentLog].
///
/// Se [preferences] for fornecido, categorias desligadas são puladas.
///
/// Retorna `null` quando nada precisa ser notificado.
NotificationProposal? evaluateNotifications({
  required List<FuelEntry> fuelEntries,
  required UserProfile? userProfile,
  required List<NotificationLogRow> recentLog,
  required DateTime now,
  required String vehicleId,
  required String? vehicleUf,
  required String? vehiclePlate,
  NotificationPreferences? preferences,
}) {
  bool dedupedRecently(String category) {
    return recentLog.any((l) =>
        l.category == category &&
        now.difference(l.sentAt).inDays < 7);
  }

  // 1) Fiscal — prioridade máxima. Usa calendário hardcoded; se IPVA/Lic
  //    do ano corrente já passou, tenta também ano+1 pra cobrir virada.
  final fiscalThisYear = suggestFiscalReminders(
    uf: vehicleUf, plate: vehiclePlate, year: now.year,
  );
  final allFiscal = <ProposedReminder>[...fiscalThisYear];
  final allCurrentInPast =
      fiscalThisYear.every((p) => p.dueDate != null && p.dueDate!.isBefore(now));
  if (allCurrentInPast) {
    allFiscal.addAll(suggestFiscalReminders(
      uf: vehicleUf, plate: vehiclePlate, year: now.year + 1,
    ));
  }
  if (preferences?.enabled('fiscal') ?? true) {
    for (final p in allFiscal) {
      final due = p.dueDate;
      if (due == null) continue;
      final days = due.difference(now).inDays;
      if (days >= 7 && days <= 30 && !dedupedRecently('fiscal')) {
        return NotificationProposal(
          category: 'fiscal',
          title: '${p.title} vence em ${days}d',
          body: p.rationale,
        );
      }
    }
  }

  // 2) CNH — janela 7..30 dias do vencimento.
  if (preferences?.enabled('cnh') ?? true) {
    final cnhExp = userProfile?.cnhExpiresAt;
    if (cnhExp != null) {
      final days = cnhExp.difference(now).inDays;
      if (days >= 7 && days <= 30 && !dedupedRecently('cnh')) {
        return NotificationProposal(
          category: 'cnh',
          title: 'CNH vence em ${days}d',
          body: 'Lembre de renovar sua habilitação.',
        );
      }
    }
  }

  // 3) Consumo — só notifica em piora (down) > 10%.
  if (preferences?.enabled('consumption_drop') ?? true) {
    final trend = analyzeConsumptionTrend(entries: fuelEntries, now: now);
    if (trend.hasEnoughData &&
        trend.direction == TrendDirection.down &&
        trend.deltaPercent.abs() > Decimal.fromInt(10) &&
        !dedupedRecently('consumption_drop')) {
      return NotificationProposal(
        category: 'consumption_drop',
        title: 'Consumo caiu',
        body:
            'Seu consumo piorou ${trend.deltaPercent.abs()}% nos últimos 3 meses.',
      );
    }
  }

  // 4) Recap ready — primeiros 3 dias do mês, mês anterior fechou com
  // dados suficientes pra contar uma história. Dedupe de 7 dias garante
  // 1 disparo por virada (gate "now.day <= 3" também limita).
  if ((preferences?.enabled('recap_ready') ?? true) && now.day <= 3) {
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final entriesInPrev = fuelEntries.where((e) =>
        e.date.year == prevYear && e.date.month == prevMonth).length;
    if (entriesInPrev >= kRecapMinEntries &&
        !dedupedRecently('recap_ready')) {
      final monthName = _ptBrMonthsForRecap[prevMonth];
      return NotificationProposal(
        category: 'recap_ready',
        title: '✨ Seu Recap de $monthName tá pronto',
        body: 'Veja seus gastos e km do mês fechado.',
      );
    }
  }

  return null;
}

import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/features/insights/history_insights.dart';

/// Gera [ProposedReminder]s para documentos com vencimento próximo.
///
/// Regras (spec §8):
/// - CNH vence em ≤ 30 dias → "Renovar CNH", dueDate = cnhExpiresAt - 30 dias.
/// - Seguro vence em ≤ 60 dias → "Renovar seguro [insurer]", dueDate = endsAt - 60 dias.
/// - Multa com dueDate definido E não paga E (dueDate - now) ≤ 7 dias
///   → "Pagar multa [autoNumber|sem número]", dueDate = fine.dueDate - 7 dias.
List<ProposedReminder> suggestDocumentReminders({
  required UserProfile? profile,
  required List<Fine> unpaidFines,
  required List<Insurance> activeInsurances,
  required DateTime now,
}) {
  final proposals = <ProposedReminder>[];

  // ── CNH ──────────────────────────────────────────────────────────────────
  final cnhExpires = profile?.cnhExpiresAt;
  if (cnhExpires != null) {
    final daysLeft = cnhExpires.difference(now).inDays;
    if (daysLeft <= 30) {
      proposals.add(
        ProposedReminder(
          title: 'Renovar CNH',
          dueDate: cnhExpires.subtract(const Duration(days: 30)),
          rationale:
              'Sua CNH vence em $daysLeft dia(s). Renove com antecedência.',
        ),
      );
    }
  }

  // ── Seguros ───────────────────────────────────────────────────────────────
  for (final ins in activeInsurances) {
    final daysLeft = ins.endsAt.difference(now).inDays;
    if (daysLeft <= 60) {
      final label =
          ins.insurer != null ? 'Renovar seguro ${ins.insurer}' : 'Renovar seguro';
      proposals.add(
        ProposedReminder(
          title: label,
          dueDate: ins.endsAt.subtract(const Duration(days: 60)),
          rationale:
              'Apólice vence em $daysLeft dia(s). Renove para manter cobertura.',
        ),
      );
    }
  }

  // ── Multas ────────────────────────────────────────────────────────────────
  for (final fine in unpaidFines) {
    if (fine.paid) continue;
    final due = fine.dueDate;
    if (due == null) continue;
    final daysLeft = due.difference(now).inDays;
    if (daysLeft <= 7) {
      final label = fine.autoNumber != null
          ? 'Pagar multa ${fine.autoNumber}'
          : 'Pagar multa sem número';
      proposals.add(
        ProposedReminder(
          title: label,
          dueDate: due.subtract(const Duration(days: 7)),
          rationale: 'Prazo de pagamento da multa em $daysLeft dia(s).',
        ),
      );
    }
  }

  return proposals;
}

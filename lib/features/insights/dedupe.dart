import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/insights/history_insights.dart';

/// Normaliza título para match de dedupe: trim + lowercase + remove acentos.
///
/// Não depende de packages externos — remove diacriticos manualmente.
String normalizeTitle(String title) {
  final lower = title.trim().toLowerCase();
  const accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(accents[ch] ?? ch);
  }
  return buf.toString();
}

/// Filtra propostas que já existem como [Reminder] ativo (não soft-deleted).
///
/// Match: título normalizado igual E (dueDate dentro de ±14 dias OU dueKm igual).
/// Reminders com [Reminder.deletedAt] != null são ignorados (soft-deleted).
List<ProposedReminder> dedupeProposed(
  List<ProposedReminder> proposed,
  List<Reminder> existing,
) {
  const window = Duration(days: 14);
  final active = existing.where((r) => r.deletedAt == null).toList();

  return proposed.where((p) {
    final pTitle = normalizeTitle(p.title);
    for (final r in active) {
      // Título deve bater primeiro.
      if (normalizeTitle(r.title) != pTitle) continue;

      // Título bate — verifica dueDate ou dueKm.
      if (p.dueDate != null && r.dueDate != null) {
        final delta = r.dueDate!.difference(p.dueDate!).abs();
        if (delta <= window) return false; // duplicata por data
      }
      if (p.dueKm != null && r.dueKm != null && p.dueKm == r.dueKm) {
        return false; // duplicata por km
      }
    }
    return true; // sem match → mantém
  }).toList();
}

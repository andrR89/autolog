import 'package:autolog/features/insights/history_insights.dart';
import 'package:autolog/features/tts/insight_narrator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.CC — narradores de texto pra TTS.
void main() {
  group('narrateInsights', () {
    test('vazio → mensagem padrão', () {
      const r = HistoryInsights(
        patterns: [], proposedReminders: [],
      );
      final out = narrateInsights(r);
      expect(out.toLowerCase(), contains('sem insights'));
    });

    test('1 padrão + 1 proposta → contém ambos', () {
      final r = HistoryInsights(
        patterns: [
          DetectedPattern(
            category: 'ipva',
            cadence: 'yearly',
            nextDue: DateTime.utc(2027, 1, 15),
            confidence: 0.85,
            rationale: 'Recorrência anual.',
          ),
        ],
        proposedReminders: [
          ProposedReminder(
            title: 'IPVA 2027',
            dueDate: DateTime.utc(2027, 1, 15),
            rationale: 'Sugestão',
          ),
        ],
      );
      final out = narrateInsights(r);
      expect(out, contains('IPVA'));
      expect(out.toLowerCase(), contains('padrão'));
      expect(out.toLowerCase(), contains('lembrete'));
    });
  });

  group('narrateFiscal', () {
    test('lista vazia', () {
      expect(narrateFiscal(const []).toLowerCase(),
          contains('sem lembretes fiscais'));
    });

    test('IPVA + Licenciamento gera frase descritiva', () {
      final out = narrateFiscal([
        const ProposedReminder(title: 'IPVA 2026', rationale: ''),
        const ProposedReminder(title: 'Licenciamento 2026', rationale: ''),
      ]);
      expect(out.contains('IPVA 2026'), isTrue);
      expect(out.contains('Licenciamento 2026'), isTrue);
    });
  });
}

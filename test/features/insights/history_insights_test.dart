import 'package:autolog/features/insights/history_insights.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.G — parse defensivo de HistoryInsights.
/// Spec: docs/specs/sprint-6.G-insights.md
void main() {
  group('HistoryInsights.fromJson', () {
    test('JSON completo', () {
      final r = HistoryInsights.fromJson({
        'patterns': [
          {
            'category': 'ipva',
            'cadence': 'yearly',
            'next_due': '2027-01-15T00:00:00.000Z',
            'confidence': 0.9,
            'rationale': 'Pago em jan/25 e jan/26.',
          },
        ],
        'proposed_reminders': [
          {
            'title': 'IPVA 2027',
            'due_date': '2027-01-15T00:00:00.000Z',
            'due_km': null,
            'rationale': 'Recorrência anual detectada.',
          },
        ],
      });
      expect(r.patterns.length, 1);
      expect(r.patterns.first.category, 'ipva');
      expect(r.patterns.first.cadence, 'yearly');
      expect(r.patterns.first.confidence, closeTo(0.9, 0.001));
      expect(r.proposedReminders.length, 1);
      expect(r.proposedReminders.first.title, 'IPVA 2027');
      expect(r.proposedReminders.first.dueDate, DateTime.utc(2027, 1, 15));
    });

    test('listas vazias → patterns e proposedReminders vazios', () {
      final r = HistoryInsights.fromJson({
        'patterns': <dynamic>[],
        'proposed_reminders': <dynamic>[],
      });
      expect(r.patterns, isEmpty);
      expect(r.proposedReminders, isEmpty);
    });

    test('campos opcionais ausentes nos patterns', () {
      final r = HistoryInsights.fromJson({
        'patterns': [
          {'category': 'manutencao', 'cadence': 'unknown'},
        ],
        'proposed_reminders': <dynamic>[],
      });
      expect(r.patterns.first.nextDue, isNull);
      expect(r.patterns.first.confidence, 0.0);
      expect(r.patterns.first.rationale, isNull);
    });

    test('chaves extras ignoradas', () {
      final r = HistoryInsights.fromJson({
        'patterns': <dynamic>[],
        'proposed_reminders': <dynamic>[],
        'foo': 'bar',
      });
      expect(r.patterns, isEmpty);
    });

    test('roundtrip toJson/fromJson preserva conteúdo', () {
      final original = HistoryInsights(
        patterns: [
          DetectedPattern(
            category: 'ipva',
            cadence: 'yearly',
            nextDue: DateTime.utc(2027, 1, 15),
            confidence: 0.85,
            rationale: 'x',
          ),
        ],
        proposedReminders: [
          ProposedReminder(
            title: 'IPVA 2027',
            dueDate: DateTime.utc(2027, 1, 15),
            rationale: 'y',
          ),
        ],
      );
      final back = HistoryInsights.fromJson(original.toJson());
      expect(back, original);
    });
  });

  group('ProposedReminder.fromJson', () {
    test('dueKm preservado quando presente', () {
      final r = ProposedReminder.fromJson({
        'title': 'Troca de óleo',
        'due_km': 80000,
        'rationale': 'Troca a cada 10mil',
      });
      expect(r.dueKm, 80000);
      expect(r.dueDate, isNull);
    });

    test('rationale default vazio se ausente', () {
      final r = ProposedReminder.fromJson({'title': 'X'});
      expect(r.rationale, '');
    });
  });
}

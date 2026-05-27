import 'package:autolog/features/insights/fiscal_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.W.1 — Fix 3: 27 UFs no calendário fiscal.
/// Spec: docs/specs/sprint-6.W.1-ia-contextual-patch.md
void main() {
  const canonical27 = <String>[
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  group('brFiscalCalendar — 27 UFs', () {
    test('tem exatamente 27 entradas', () {
      expect(brFiscalCalendar.length, 27);
    });

    test('contém todas as 27 UFs brasileiras canônicas', () {
      for (final uf in canonical27) {
        expect(brFiscalCalendar.containsKey(uf), isTrue, reason: 'falta $uf');
      }
    });

    test('cada UF mapeia IPVA + Licenciamento com 10 dígitos cobertos', () {
      for (final uf in canonical27) {
        final cal = brFiscalCalendar[uf]!;
        // Cada FiscalScheduleByDigit deve ter mapeamentos pra qualquer dígito
        // (0..9) — monthFor não-null/válido pra todos.
        for (var d = 0; d <= 9; d++) {
          final ipvaMonth = cal.ipva.monthFor(d);
          final licMonth = cal.licensing.monthFor(d);
          expect(ipvaMonth >= 1 && ipvaMonth <= 12, isTrue,
              reason: '$uf IPVA dígito $d → $ipvaMonth fora de 1..12');
          expect(licMonth >= 1 && licMonth <= 12, isTrue,
              reason: '$uf Licenciamento dígito $d → $licMonth fora de 1..12');
        }
      }
    });

    test('cada UF produz 2 propostas (IPVA + Licenciamento)', () {
      for (final uf in canonical27) {
        final props = suggestFiscalReminders(
          uf: uf, plate: 'ABC1234', year: 2026,
        );
        expect(props.length, 2,
            reason: '$uf deveria gerar 2 propostas, gerou ${props.length}');
        expect(
          props.first.dueDate, isNotNull,
          reason: '$uf primeira proposta sem dueDate',
        );
      }
    });

    // Regressões de homologação — quando o Diretor reportar erro UF×final,
    // adicione caso aqui.
    test('SC final 6 → IPVA junho (regressão 27/05/2026)', () {
      final r = suggestFiscalReminders(
        uf: 'SC', plate: 'TPJ4B26', year: 2026,
      );
      final ipva = r.firstWhere((p) => p.title.startsWith('IPVA'));
      expect(ipva.dueDate!.month, 6);
    });

    test('SC: pattern final N → mês N (1..9), final 0 → out', () {
      for (var d = 1; d <= 9; d++) {
        final r = suggestFiscalReminders(
          uf: 'SC', plate: 'ABC1D2$d', year: 2026,
        );
        final ipva = r.firstWhere((p) => p.title.startsWith('IPVA'));
        expect(ipva.dueDate!.month, d, reason: 'SC final $d');
      }
      final r0 = suggestFiscalReminders(
        uf: 'SC', plate: 'ABC1D20', year: 2026,
      );
      expect(r0.firstWhere((p) => p.title.startsWith('IPVA')).dueDate!.month,
          10);
    });
  });
}

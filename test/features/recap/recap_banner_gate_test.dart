import 'package:autolog/features/recap/recap_banner_gate.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.W.2 — gating contextual do banner de Recap.
///
/// Regra: o banner SÓ aparece em dois momentos do calendário,
/// E só se há dados suficientes pra contar uma história.
///
/// - Primeiros 7 dias do mês  → "Recap de [mês anterior]"
/// - Últimos 5 dias do mês    → "Recap do mês atual"
/// - Mínimo de [kRecapMinEntries] entries combinadas (fuel + expense).
void main() {
  group('shouldShowRecapBanner — meio do mês', () {
    test('dia 15 com dados → hide', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 5, 15),
        currentMonthEntries: 10,
        previousMonthEntries: 20,
      );
      expect(r.decision, RecapShowDecision.hide);
      expect(r.periodLabel, isNull);
    });

    test('dia 20 sem dados → hide', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 5, 20),
        currentMonthEntries: 0,
        previousMonthEntries: 0,
      );
      expect(r.decision, RecapShowDecision.hide);
    });
  });

  group('shouldShowRecapBanner — primeiros 7 dias do mês', () {
    test('dia 1 do mês com ≥3 entries no anterior → previousMonth', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 6, 1),
        currentMonthEntries: 0,
        previousMonthEntries: 5,
      );
      expect(r.decision, RecapShowDecision.previousMonth);
      expect(r.periodLabel, 'maio');
    });

    test('dia 7 ainda na janela', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 6, 7),
        currentMonthEntries: 0,
        previousMonthEntries: 5,
      );
      expect(r.decision, RecapShowDecision.previousMonth);
    });

    test('dia 8 já fora da janela inicial', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 6, 8),
        currentMonthEntries: 0,
        previousMonthEntries: 5,
      );
      expect(r.decision, RecapShowDecision.hide);
    });

    test('dia 1 SEM dados no anterior → hide', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 6, 1),
        currentMonthEntries: 0,
        previousMonthEntries: 0,
      );
      expect(r.decision, RecapShowDecision.hide);
    });

    test('dia 3 com 2 entries no anterior → hide (abaixo do mínimo)', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 6, 3),
        currentMonthEntries: 0,
        previousMonthEntries: 2,
      );
      expect(r.decision, RecapShowDecision.hide);
    });

    test('virada do ano: jan/2027 → previousMonth = "dezembro"', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2027, 1, 5),
        currentMonthEntries: 0,
        previousMonthEntries: 8,
      );
      expect(r.decision, RecapShowDecision.previousMonth);
      expect(r.periodLabel, 'dezembro');
    });
  });

  group('shouldShowRecapBanner — últimos 5 dias do mês', () {
    test('dia 30 de maio (5 dias até fim) com ≥3 entries → currentMonth', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 5, 30),
        currentMonthEntries: 5,
        previousMonthEntries: 0,
      );
      expect(r.decision, RecapShowDecision.currentMonth);
      expect(r.periodLabel, 'maio');
    });

    test('dia 31 (último) ainda na janela', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 5, 31),
        currentMonthEntries: 3,
        previousMonthEntries: 0,
      );
      expect(r.decision, RecapShowDecision.currentMonth);
    });

    test('fevereiro de ano não-bissexto: dia 24 fora, dia 25 entra', () {
      // 2026 não-bissexto, fev tem 28 dias. 28 - 5 = 23 → dia >= 24 entra.
      final r24 = shouldShowRecapBanner(
        now: DateTime.utc(2026, 2, 23),
        currentMonthEntries: 5,
        previousMonthEntries: 0,
      );
      expect(r24.decision, RecapShowDecision.hide);

      final r25 = shouldShowRecapBanner(
        now: DateTime.utc(2026, 2, 24),
        currentMonthEntries: 5,
        previousMonthEntries: 0,
      );
      expect(r25.decision, RecapShowDecision.currentMonth);
      expect(r25.periodLabel, 'fevereiro');
    });

    test('últimos 5 dias mas só 2 entries → hide', () {
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 5, 30),
        currentMonthEntries: 2,
        previousMonthEntries: 0,
      );
      expect(r.decision, RecapShowDecision.hide);
    });
  });

  group('shouldShowRecapBanner — prioridade', () {
    test('quando os 2 momentos colidem (primeiros 7 do mês cobrindo o ant.) '
        'a prioridade é mostrar o do mês anterior — mais valioso', () {
      // dia 1 — janela do mês anterior tem preferência.
      final r = shouldShowRecapBanner(
        now: DateTime.utc(2026, 6, 1),
        currentMonthEntries: 8,
        previousMonthEntries: 8,
      );
      expect(r.decision, RecapShowDecision.previousMonth);
      expect(r.periodLabel, 'maio');
    });
  });
}

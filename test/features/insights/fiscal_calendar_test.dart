import 'package:autolog/features/insights/fiscal_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.N — calendário fiscal hardcoded + função pura.
/// Spec: docs/specs/sprint-6.N-fiscal-reminders.md
void main() {
  group('lastDigitOfPlate', () {
    test('placa antiga ABC1234 → 4', () {
      expect(lastDigitOfPlate('ABC1234'), 4);
    });

    test('placa Mercosul ABC1D23 → 3', () {
      expect(lastDigitOfPlate('ABC1D23'), 3);
    });

    test('placa com espaço/hífen aceita', () {
      expect(lastDigitOfPlate('ABC-1234'), 4);
      expect(lastDigitOfPlate(' ABC1234 '), 4);
    });

    test('inválida → null', () {
      expect(lastDigitOfPlate(''), isNull);
      expect(lastDigitOfPlate(null), isNull);
      expect(lastDigitOfPlate('???'), isNull);
    });
  });

  group('brFiscalCalendar', () {
    test('SP existe e tem IPVA por dígito', () {
      final sp = brFiscalCalendar['SP'];
      expect(sp, isNotNull);
      // SP distribui IPVA jan→mai conforme final 1-2/3-4/5-6/7-8/9-0
      expect(sp!.ipva.monthFor(1), 1);
      expect(sp.ipva.monthFor(2), 1);
      expect(sp.ipva.monthFor(3), 2);
      expect(sp.ipva.monthFor(9), 5);
      expect(sp.ipva.monthFor(0), 5);
    });

    test('UF default cobre estados sem entrada específica', () {
      // Acessamos via função pública (que aplica fallback).
      final propostas = suggestFiscalReminders(
        uf: 'ZZ', plate: 'ABC1234', year: 2026,
      );
      expect(propostas.length, 2);
    });

    test('FiscalScheduleByDigit.monthFor com dígito null usa fallback', () {
      final sp = brFiscalCalendar['SP']!;
      final m = sp.ipva.monthFor(null);
      // não deve lançar; deve retornar um mês válido (1..12)
      expect(m >= 1 && m <= 12, isTrue);
    });
  });

  group('suggestFiscalReminders', () {
    test('SP plate 1234 (final 4) → IPVA fev (jan-mai dist.), Licenc. ...',
        () {
      final r = suggestFiscalReminders(
        uf: 'SP', plate: 'ABC1234', year: 2026,
      );
      expect(r.length, 2);
      final ipva = r.firstWhere((p) => p.title.startsWith('IPVA'));
      final lic = r.firstWhere((p) => p.title.startsWith('Licenciamento'));
      expect(ipva.title, 'IPVA 2026');
      expect(lic.title, 'Licenciamento 2026');
      expect(ipva.dueDate, isNotNull);
      expect(lic.dueDate, isNotNull);
      // SP final 4 → IPVA fev (mês 2)
      expect(ipva.dueDate!.month, 2);
      expect(ipva.dueDate!.year, 2026);
    });

    test('uf null + plate null → 2 propostas usando default', () {
      final r = suggestFiscalReminders(
        uf: null, plate: null, year: 2026,
      );
      expect(r.length, 2);
    });

    test('UF desconhecida ("ZZ") → usa default, 2 propostas', () {
      final r = suggestFiscalReminders(
        uf: 'ZZ', plate: 'ABC1234', year: 2026,
      );
      expect(r.length, 2);
    });

    test('SP sem plate → 2 propostas (usa fallback do dígito)', () {
      final r = suggestFiscalReminders(uf: 'SP', plate: null, year: 2026);
      expect(r.length, 2);
      expect(r.first.dueDate, isNotNull);
    });

    test('title contém o ano', () {
      final r = suggestFiscalReminders(uf: 'SP', plate: 'ABC1234', year: 2027);
      expect(r.first.title.contains('2027'), isTrue);
    });

    test('rationale menciona "Detran" (disclaimer pra user)', () {
      final r = suggestFiscalReminders(uf: 'SP', plate: 'ABC1234', year: 2026);
      expect(r.first.rationale.toLowerCase().contains('detran'), isTrue);
    });

    test('dueDate é dia 1 do mês', () {
      final r = suggestFiscalReminders(uf: 'SP', plate: 'ABC1234', year: 2026);
      expect(r.first.dueDate!.day, 1);
    });
  });

  group('FiscalScheduleByDigit.monthFor', () {
    test('retorna mês mapeado pro dígito conhecido', () {
      const s = FiscalScheduleByDigit({
        0: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 9, 9: 10,
      });
      expect(s.monthFor(3), 4);
      expect(s.monthFor(9), 10);
    });

    test('dígito null → mês fallback (qualquer mês válido)', () {
      const s = FiscalScheduleByDigit({0: 1, 1: 1});
      final m = s.monthFor(null);
      expect(m >= 1 && m <= 12, isTrue);
    });

    test('dígito fora do mapa → mês fallback', () {
      const s = FiscalScheduleByDigit({0: 5}); // só dígito 0 mapeado
      final m = s.monthFor(7);
      expect(m >= 1 && m <= 12, isTrue);
    });
  });
}

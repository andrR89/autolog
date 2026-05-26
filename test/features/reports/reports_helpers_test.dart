import 'package:autolog/features/reports/reports_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 5.4 — helpers da tela de relatórios.
/// Spec: docs/specs/sprint-5.4-reports-screen.md
void main() {
  group('formatMonthLabel', () {
    test('maio/2026 → "mai/2026"', () {
      expect(formatMonthLabel(DateTime.utc(2026, 5, 1)), 'mai/2026');
    });

    test('janeiro/2026 → "jan/2026"', () {
      expect(formatMonthLabel(DateTime.utc(2026, 1, 1)), 'jan/2026');
    });

    test('dezembro/2026 → "dez/2026"', () {
      expect(formatMonthLabel(DateTime.utc(2026, 12, 1)), 'dez/2026');
    });

    test('sempre lowercase, sem ponto final', () {
      for (final m in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
        final label = formatMonthLabel(DateTime.utc(2026, m, 1));
        expect(
          label,
          equals(label.toLowerCase()),
          reason: 'label "$label" deveria ser minúsculo',
        );
        expect(
          label.contains('.'),
          isFalse,
          reason: 'label "$label" não deveria ter ponto',
        );
      }
    });
  });
}

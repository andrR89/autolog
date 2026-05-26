import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/insights/dedupe.dart';
import 'package:autolog/features/insights/history_insights.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.G — dedupe entre propostas e lembretes existentes.
/// Spec: docs/specs/sprint-6.G-insights.md

void main() {
  Reminder rem({
    required String id,
    required String title,
    DateTime? dueDate,
    int? dueKm,
    DateTime? deletedAt,
    bool isDone = false,
  }) =>
      Reminder(
        id: id,
        vehicleId: 'v1',
        type: dueKm != null ? ReminderType.porKm : ReminderType.porData,
        title: title,
        dueDate: dueDate,
        dueKm: dueKm,
        isDone: isDone,
        createdAt: DateTime.utc(2026, 1),
        updatedAt: DateTime.utc(2026, 1),
        deletedAt: deletedAt,
        syncStatus: SyncStatus.synced,
      );

  ProposedReminder prop({
    required String title,
    DateTime? dueDate,
    int? dueKm,
  }) =>
      ProposedReminder(
        title: title,
        dueDate: dueDate,
        dueKm: dueKm,
        rationale: '',
      );

  group('normalizeTitle', () {
    test('trim + lowercase', () {
      expect(normalizeTitle('  IPVA 2026  '), 'ipva 2026');
    });

    test('remove acentos', () {
      expect(normalizeTitle('Revisão Anual'), 'revisao anual');
      expect(normalizeTitle('Substituição de óleo'), 'substituicao de oleo');
    });

    test('string vazia → vazia', () {
      expect(normalizeTitle(''), '');
      expect(normalizeTitle('   '), '');
    });
  });

  group('dedupeProposed', () {
    test('listas vazias → proposta inalterada (filtrada vazia)', () {
      expect(dedupeProposed([], []), isEmpty);
      final p = [prop(title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 15))];
      expect(dedupeProposed(p, []), p);
    });

    test('match exato (título + dueDate) → filtra', () {
      final existing = [
        rem(id: 'r1', title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 15)),
      ];
      final p = [prop(title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 15))];
      expect(dedupeProposed(p, existing), isEmpty);
    });

    test('título igual, dueDate dentro de ±14 dias → filtra', () {
      final existing = [
        rem(id: 'r1', title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 10)),
      ];
      final p = [prop(title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 20))];
      expect(dedupeProposed(p, existing), isEmpty);
    });

    test('título igual, dueDate fora de ±14 dias → mantém', () {
      final existing = [
        rem(id: 'r1', title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 1)),
      ];
      final p = [prop(title: 'IPVA 2027', dueDate: DateTime.utc(2027, 2, 1))];
      expect(dedupeProposed(p, existing).length, 1);
    });

    test('título igual, dueKm igual → filtra', () {
      final existing = [
        rem(id: 'r1', title: 'Troca de óleo', dueKm: 80000),
      ];
      final p = [prop(title: 'Troca de óleo', dueKm: 80000)];
      expect(dedupeProposed(p, existing), isEmpty);
    });

    test('match case/acento-insensitive', () {
      final existing = [
        rem(id: 'r1', title: 'ipva 2027', dueDate: DateTime.utc(2027, 1, 15)),
      ];
      final p = [
        prop(title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 15)),
      ];
      expect(dedupeProposed(p, existing), isEmpty);

      final existing2 = [
        rem(id: 'r2', title: 'Revisao', dueDate: DateTime.utc(2027, 1, 15)),
      ];
      final p2 = [prop(title: 'Revisão', dueDate: DateTime.utc(2027, 1, 15))];
      expect(dedupeProposed(p2, existing2), isEmpty);
    });

    test('lembretes soft-deleted ignorados', () {
      final existing = [
        rem(
          id: 'r1',
          title: 'IPVA 2027',
          dueDate: DateTime.utc(2027, 1, 15),
          deletedAt: DateTime.utc(2026, 6),
        ),
      ];
      final p = [prop(title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 15))];
      expect(dedupeProposed(p, existing).length, 1);
    });

    test('título diferente, dueDate igual → mantém', () {
      final existing = [
        rem(id: 'r1', title: 'Seguro', dueDate: DateTime.utc(2027, 1, 15)),
      ];
      final p = [
        prop(title: 'IPVA 2027', dueDate: DateTime.utc(2027, 1, 15)),
      ];
      expect(dedupeProposed(p, existing).length, 1);
    });
  });
}

// Sprint 6.MM — Testes da fábrica de próximo lembrete recorrente.
//
// Cobre ≥15 casos:
// 1. Sem intervalo → null (one-shot)
// 2. intervalDays definido, dueDate definido → soma datas corretamente
// 3. intervalKm definido, currentOdometerKm fornecido → currentOdo + interval
// 4. intervalKm definido, SEM currentOdometerKm → fallback dueKm + interval
// 5. Ambos intervalDays e intervalKm definidos com ambos due* → ambos calculados
// 6. parentReminderId aponta para o original
// 7. Novo id ≠ original (nextId externo)
// 8. isDone = false no próximo
// 9. status = pending no próximo
// 10. intervalDays preservado no próximo
// 11. intervalKm preservado no próximo
// 12. title preservado
// 13. vehicleId preservado
// 14. type preservado
// 15. intervalDays definido mas dueDate null → trata como one-shot
// 16. intervalKm definido mas dueKm null → trata como one-shot
// 17. intervalDays de 365 (anual) → dueDate correto mesmo em ano bissexto

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/reminders/recurring/next_reminder_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseNow = DateTime.utc(2026, 5, 29, 10, 0, 0);
  const nextId = 'next-id-123';

  Reminder base({
    String id = 'original-id',
    ReminderType type = ReminderType.porData,
    int? dueKm,
    DateTime? dueDate,
    int? intervalDays,
    int? intervalKm,
  }) {
    return Reminder(
      id: id,
      vehicleId: 'v1',
      type: type,
      title: 'Troca de óleo',
      dueKm: dueKm,
      dueDate: dueDate,
      isDone: true,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 5, 29),
      syncStatus: SyncStatus.pending,
      intervalDays: intervalDays,
      intervalKm: intervalKm,
    );
  }

  group('Caso 1 — sem intervalo (one-shot)', () {
    test('retorna null quando intervalDays e intervalKm são null', () {
      final r = base(
        dueDate: DateTime.utc(2026, 6, 1),
        intervalDays: null,
        intervalKm: null,
      );
      expect(
        createNextReminder(
          doneReminder: r,
          currentOdometerKm: null,
          now: baseNow,
          nextId: nextId,
        ),
        isNull,
      );
    });
  });

  group('Caso 2 — só intervalDays com dueDate', () {
    test('próximo dueDate = dueDate original + intervalDays (30 dias)', () {
      final original = DateTime.utc(2026, 6, 1);
      final r = base(dueDate: original, intervalDays: 30);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next, isNotNull);
      expect(next!.dueDate, DateTime.utc(2026, 7, 1));
    });

    test('próximo dueDate = dueDate original + intervalDays (90 dias)', () {
      final original = DateTime.utc(2026, 1, 1);
      final r = base(dueDate: original, intervalDays: 90);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.dueDate, DateTime.utc(2026, 4, 1));
    });
  });

  group('Caso 3 — só intervalKm com currentOdometerKm', () {
    test('dueKm = currentOdometerKm + intervalKm', () {
      final r = base(type: ReminderType.porKm, dueKm: 50000, intervalKm: 10000);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: 51234,
        now: baseNow,
        nextId: nextId,
      );
      expect(next, isNotNull);
      expect(next!.dueKm, 61234); // 51234 + 10000
    });

    test('usa exatamente o odômetro atual, não o dueKm anterior', () {
      final r = base(type: ReminderType.porKm, dueKm: 50000, intervalKm: 5000);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: 50500, // ligeiramente acima do alvo
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.dueKm, 55500); // 50500 + 5000, não 55000
    });
  });

  group('Caso 4 — só intervalKm SEM currentOdometerKm (fallback)', () {
    test('dueKm = dueKm original + intervalKm', () {
      final r = base(type: ReminderType.porKm, dueKm: 50000, intervalKm: 10000);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next, isNotNull);
      expect(next!.dueKm, 60000); // 50000 + 10000
    });
  });

  group('Caso 5 — ambos intervalDays e intervalKm definidos', () {
    test('calcula dueDate E dueKm', () {
      final original = DateTime.utc(2026, 6, 1);
      final r = base(
        type: ReminderType.porKm,
        dueDate: original,
        dueKm: 50000,
        intervalDays: 180,
        intervalKm: 10000,
      );
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: 51000,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.dueDate, DateTime.utc(2026, 11, 28));
      expect(next.dueKm, 61000);
    });
  });

  group('Caso 6/7 — rastreabilidade e unicidade de id', () {
    test('parentReminderId aponta para o lembrete original', () {
      final r = base(
        id: 'original-abc',
        dueDate: DateTime.utc(2026, 7, 1),
        intervalDays: 30,
      );
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.parentReminderId, 'original-abc');
    });

    test('id do próximo é o nextId fornecido, diferente do original', () {
      final r = base(
        id: 'original-id',
        dueDate: DateTime.utc(2026, 7, 1),
        intervalDays: 30,
      );
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: 'completely-new-id',
      );
      expect(next!.id, 'completely-new-id');
      expect(next.id, isNot('original-id'));
    });
  });

  group('Casos 8/9 — estado do próximo', () {
    test('próximo nasce com isDone=false', () {
      final r = base(dueDate: DateTime.utc(2026, 7, 1), intervalDays: 30);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.isDone, false);
    });

    test('próximo nasce com syncStatus=pending', () {
      final r = base(dueDate: DateTime.utc(2026, 7, 1), intervalDays: 30);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.syncStatus, SyncStatus.pending);
    });
  });

  group('Casos 10–14 — campos copiados', () {
    test('intervalDays é preservado no próximo', () {
      final r = base(dueDate: DateTime.utc(2026, 7, 1), intervalDays: 365);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.intervalDays, 365);
    });

    test('intervalKm é preservado no próximo', () {
      final r = base(type: ReminderType.porKm, dueKm: 50000, intervalKm: 10000);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.intervalKm, 10000);
    });

    test('title é copiado', () {
      final r = base(dueDate: DateTime.utc(2026, 7, 1), intervalDays: 30);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.title, 'Troca de óleo');
    });

    test('vehicleId é copiado', () {
      final r = base(dueDate: DateTime.utc(2026, 7, 1), intervalDays: 30);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.vehicleId, 'v1');
    });

    test('type é copiado', () {
      final r = base(type: ReminderType.porKm, dueKm: 50000, intervalKm: 10000);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.type, ReminderType.porKm);
    });
  });

  group('Casos 15/16 — intervalo definido mas due* ausente → one-shot', () {
    test('intervalDays definido mas dueDate null → retorna null', () {
      final r = base(
        dueDate: null,
        intervalDays: 30,
        // dueDate é null, intervalDays não tem ponto de ancoragem
      );
      expect(
        createNextReminder(
          doneReminder: r,
          currentOdometerKm: null,
          now: baseNow,
          nextId: nextId,
        ),
        isNull,
      );
    });

    test('intervalKm definido mas dueKm null → retorna null', () {
      final r = base(type: ReminderType.porKm, dueKm: null, intervalKm: 10000);
      expect(
        createNextReminder(
          doneReminder: r,
          currentOdometerKm: null,
          now: baseNow,
          nextId: nextId,
        ),
        isNull,
      );
    });
  });

  group('Caso 17 — ano bissexto', () {
    test('intervalDays=365 a partir de 2024-02-29 (ano bissexto)', () {
      final r = base(dueDate: DateTime.utc(2024, 2, 29), intervalDays: 365);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      // 2024-02-29 + 365 dias = 2025-02-28 (2024 tem 366 dias; 29/02 + 365 = 28/02)
      // Duration.days é calendário estrito, não "próximo ano mesmo dia".
      expect(next!.dueDate, DateTime.utc(2025, 2, 28));
    });

    test('intervalDays=366 a partir de 2024-02-29 → cai em 2025-03-01', () {
      final r = base(dueDate: DateTime.utc(2024, 2, 29), intervalDays: 366);
      final next = createNextReminder(
        doneReminder: r,
        currentOdometerKm: null,
        now: baseNow,
        nextId: nextId,
      );
      expect(next!.dueDate, DateTime.utc(2025, 3, 1));
    });
  });
}

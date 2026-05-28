import 'package:autolog/data/local/database.dart';
import 'package:autolog/features/calendar/calendar_event_link_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.EE — Testes do CalendarEventLinkRepository (get/save/remove/listAll).

void main() {
  late AppDatabase db;
  late DriftCalendarEventLinkRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftCalendarEventLinkRepository(db);
  });

  tearDown(() => db.close());

  group('getEventIdFor', () {
    test('retorna null para reminderId inexistente', () async {
      final result = await repo.getEventIdFor('nonexistent-id');
      expect(result, isNull);
    });

    test('retorna o calendarEventId correto após save', () async {
      await repo.save('reminder-1', 'gcal-event-xyz');
      final result = await repo.getEventIdFor('reminder-1');
      expect(result, 'gcal-event-xyz');
    });

    test('retorna null para reminder diferente', () async {
      await repo.save('reminder-1', 'gcal-event-xyz');
      final result = await repo.getEventIdFor('reminder-2');
      expect(result, isNull);
    });
  });

  group('save', () {
    test('salva um novo link', () async {
      await repo.save('r-new', 'ev-new');
      final result = await repo.getEventIdFor('r-new');
      expect(result, 'ev-new');
    });

    test('atualiza link existente (upsert)', () async {
      await repo.save('r-1', 'ev-v1');
      await repo.save('r-1', 'ev-v2');

      final result = await repo.getEventIdFor('r-1');
      expect(result, 'ev-v2');

      // Só deve ter um registro.
      final all = await repo.listAll();
      expect(all, hasLength(1));
    });

    test('save múltiplos reminders distintos', () async {
      await repo.save('r-a', 'ev-a');
      await repo.save('r-b', 'ev-b');
      await repo.save('r-c', 'ev-c');

      expect(await repo.getEventIdFor('r-a'), 'ev-a');
      expect(await repo.getEventIdFor('r-b'), 'ev-b');
      expect(await repo.getEventIdFor('r-c'), 'ev-c');
    });
  });

  group('remove', () {
    test('remove link existente', () async {
      await repo.save('r-del', 'ev-del');
      await repo.remove('r-del');

      final result = await repo.getEventIdFor('r-del');
      expect(result, isNull);
    });

    test('remove de id inexistente é no-op (não lança)', () async {
      // Não deve lançar exceção.
      await expectLater(
        repo.remove('inexistente'),
        completes,
      );
    });

    test('remove só apaga o reminder correto', () async {
      await repo.save('r-keep', 'ev-keep');
      await repo.save('r-del', 'ev-del');

      await repo.remove('r-del');

      expect(await repo.getEventIdFor('r-keep'), 'ev-keep');
      expect(await repo.getEventIdFor('r-del'), isNull);
    });
  });

  group('listAll', () {
    test('retorna lista vazia quando não há links', () async {
      final result = await repo.listAll();
      expect(result, isEmpty);
    });

    test('retorna todos os links salvos', () async {
      await repo.save('r-1', 'ev-1');
      await repo.save('r-2', 'ev-2');
      await repo.save('r-3', 'ev-3');

      final result = await repo.listAll();
      expect(result, hasLength(3));
    });

    test('listAll reflete estado após remoção', () async {
      await repo.save('r-1', 'ev-1');
      await repo.save('r-2', 'ev-2');

      await repo.remove('r-1');

      final result = await repo.listAll();
      expect(result, hasLength(1));
      expect(result.single.reminderId, 'r-2');
    });
  });
}

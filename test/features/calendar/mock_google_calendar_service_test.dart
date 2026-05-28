import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/calendar/google_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.EE — Testes do MockGoogleCalendarService.
/// Valida: toggle de conexão, contadores de chamadas, e-mail mock.

void main() {
  late MockGoogleCalendarService svc;

  final reminder = Reminder(
    id: 'rem-1',
    vehicleId: 'veh-1',
    type: ReminderType.porData,
    title: 'Troca de óleo',
    isDone: false,
    createdAt: DateTime.utc(2026, 5, 28),
    updatedAt: DateTime.utc(2026, 5, 28),
    syncStatus: SyncStatus.pending,
  );

  setUp(() {
    svc = MockGoogleCalendarService();
  });

  group('isConnected — estado inicial', () {
    test('começa desconectado', () async {
      expect(await svc.isConnected(), isFalse);
    });

    test('connectedEmail retorna null quando desconectado', () async {
      expect(await svc.connectedEmail(), isNull);
    });
  });

  group('connect / disconnect', () {
    test('connect → isConnected = true', () async {
      await svc.connect();
      expect(await svc.isConnected(), isTrue);
    });

    test('connect → connectedEmail retorna e-mail mock', () async {
      await svc.connect();
      final email = await svc.connectedEmail();
      expect(email, isNotNull);
      expect(email, 'mock@google.com');
    });

    test('disconnect após connect → isConnected = false', () async {
      await svc.connect();
      await svc.disconnect();
      expect(await svc.isConnected(), isFalse);
    });

    test('disconnect → connectedEmail retorna null', () async {
      await svc.connect();
      await svc.disconnect();
      expect(await svc.connectedEmail(), isNull);
    });

    test('disconnect sem connect prévia é no-op (não lança)', () async {
      await expectLater(svc.disconnect(), completes);
    });
  });

  group('upsertEvent', () {
    test('retorna null quando desconectado', () async {
      final result = await svc.upsertEvent(reminder);
      expect(result, isNull);
    });

    test('retorna eventId mock quando conectado', () async {
      await svc.connect();
      final result = await svc.upsertEvent(reminder);
      expect(result, 'mock-event-${reminder.id}');
    });

    test('incrementa upsertCallCount', () async {
      await svc.connect();
      expect(svc.upsertCallCount, 0);

      await svc.upsertEvent(reminder);
      expect(svc.upsertCallCount, 1);

      await svc.upsertEvent(reminder);
      expect(svc.upsertCallCount, 2);
    });

    test('upsertCallCount NÃO incrementa quando desconectado', () async {
      await svc.upsertEvent(reminder);
      expect(svc.upsertCallCount, 0);
    });

    test('registra lastUpsertedReminderId', () async {
      await svc.connect();
      await svc.upsertEvent(reminder);
      expect(svc.lastUpsertedReminderId, reminder.id);
    });
  });

  group('deleteEvent', () {
    test('no-op quando desconectado', () async {
      await svc.deleteEvent('gcal-event-1');
      expect(svc.deleteCallCount, 0);
    });

    test('incrementa deleteCallCount quando conectado', () async {
      await svc.connect();
      await svc.deleteEvent('gcal-event-1');
      expect(svc.deleteCallCount, 1);
    });

    test('múltiplos deletes acumulam o count', () async {
      await svc.connect();
      await svc.deleteEvent('ev-1');
      await svc.deleteEvent('ev-2');
      await svc.deleteEvent('ev-3');
      expect(svc.deleteCallCount, 3);
    });

    test('registra lastDeletedEventId', () async {
      await svc.connect();
      await svc.deleteEvent('gcal-event-xyz');
      expect(svc.lastDeletedEventId, 'gcal-event-xyz');
    });
  });

  group('reset', () {
    test('reset limpa todo o estado', () async {
      await svc.connect();
      await svc.upsertEvent(reminder);
      await svc.deleteEvent('ev-1');

      svc.reset();

      expect(await svc.isConnected(), isFalse);
      expect(svc.upsertCallCount, 0);
      expect(svc.deleteCallCount, 0);
      expect(svc.lastUpsertedReminderId, isNull);
      expect(svc.lastDeletedEventId, isNull);
    });
  });

  group('contadores isolados por instância', () {
    test('instâncias distintas não compartilham estado', () async {
      final svc2 = MockGoogleCalendarService();
      await svc.connect();
      await svc.upsertEvent(reminder);

      expect(svc.upsertCallCount, 1);
      expect(svc2.upsertCallCount, 0);
    });
  });
}

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart';
import 'package:autolog/features/reminders/notification_scheduler.dart';
import 'package:autolog/features/reminders/reminder_saver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 4.3 — integração ReminderSaver + NotificationScheduler.
/// Spec: docs/specs/sprint-4.3-local-notifications.md

class _FakeRepo implements ReminderRepository {
  final Map<String, Reminder> _store = {};

  @override
  Future<Reminder> create(Reminder reminder) async {
    final saved = reminder.copyWith(
      createdAt: DateTime.utc(2026, 5, 24),
      updatedAt: DateTime.utc(2026, 5, 24),
      syncStatus: SyncStatus.pending,
    );
    _store[saved.id] = saved;
    return saved;
  }

  @override
  Future<Reminder> update(Reminder reminder) async {
    final existing = _store[reminder.id];
    if (existing == null) throw StateError('not found');
    final updated = reminder.copyWith(
      createdAt: existing.createdAt,
      updatedAt: DateTime.utc(2026, 5, 24, 1),
      syncStatus: SyncStatus.pending,
    );
    _store[updated.id] = updated;
    return updated;
  }

  @override
  Future<void> softDelete(String id) async {
    _store.remove(id);
  }

  @override
  Future<Reminder?> getById(String id) async => _store[id];
  @override
  Future<List<Reminder>> listByVehicle(String vehicleId) async => const [];
  @override
  Stream<List<Reminder>> watchByVehicle(String vehicleId) =>
      const Stream.empty();
}

void main() {
  late _FakeRepo repo;
  late FakeNotificationScheduler scheduler;
  late ReminderSaver saver;

  setUp(() {
    repo = _FakeRepo();
    scheduler = FakeNotificationScheduler();
    int counter = 0;
    saver = ReminderSaver(
      repo,
      generateId: () => 'id-${++counter}',
      scheduler: scheduler,
    );
  });

  group('create', () {
    test('porData futuro: scheduler.scheduled[id] tem o reminder', () async {
      final saved = await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: DateTime.utc(2026, 12, 31),
      );
      expect(scheduler.scheduled[saved.id], isNotNull);
      expect(scheduler.scheduled[saved.id]!.title, 'IPVA');
    });

    test('porKm: scheduler não agenda (no-op)', () async {
      await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porKm,
        title: 'Troca de óleo',
        dueKm: 50000,
      );
      expect(scheduler.scheduled, isEmpty);
    });

    test('porData no passado: scheduler não agenda', () async {
      await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porData,
        title: 'Vencido',
        dueDate: DateTime.utc(2020, 1, 1),
      );
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('update', () {
    test('mudando dueDate: substitui agendamento', () async {
      final saved = await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: DateTime.utc(2026, 12, 31),
      );

      final newDate = DateTime.utc(2027, 3, 15);
      await saver.update(
        saved,
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: newDate,
        isDone: false,
      );
      expect(scheduler.scheduled[saved.id]!.dueDate, newDate);
    });

    test('marcando isDone=true: cancela agendamento', () async {
      final saved = await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: DateTime.utc(2026, 12, 31),
      );
      expect(scheduler.scheduled[saved.id], isNotNull);

      await saver.update(
        saved,
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: DateTime.utc(2026, 12, 31),
        isDone: true,
      );
      expect(scheduler.scheduled[saved.id], isNull);
      expect(scheduler.cancelled, contains(saved.id));
    });
  });

  group('toggleDone', () {
    test('false→true: cancela', () async {
      final saved = await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: DateTime.utc(2026, 12, 31),
      );
      await saver.toggleDone(saved);
      expect(scheduler.scheduled[saved.id], isNull);
      expect(scheduler.cancelled, contains(saved.id));
    });

    test('true→false (com porData futuro): re-agenda', () async {
      // Cria já done.
      final saved = await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: DateTime.utc(2026, 12, 31),
        isDone: true,
      );
      expect(scheduler.scheduled[saved.id], isNull); // done → não agendou

      // Toggle pra false.
      await saver.toggleDone(saved);
      expect(scheduler.scheduled[saved.id], isNotNull);
    });
  });

  group('delete', () {
    test('cancela agendamento', () async {
      final saved = await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: DateTime.utc(2026, 12, 31),
      );
      await saver.delete(saved.id);
      expect(scheduler.scheduled[saved.id], isNull);
      expect(scheduler.cancelled, contains(saved.id));
    });
  });
}

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart';
import 'package:autolog/features/reminders/reminder_saver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 4.2b — ReminderSaver: orquestra criar/editar/excluir + toggleDone.
/// Spec: docs/specs/sprint-4.2b-reminders-ui.md

class _FakeReminderRepository implements ReminderRepository {
  Reminder? lastCreated;
  Reminder? lastUpdated;
  String? lastDeletedId;
  bool throwOnUpdate = false;

  @override
  Future<Reminder> create(Reminder reminder) async {
    lastCreated = reminder;
    return reminder;
  }

  @override
  Future<Reminder> update(Reminder reminder) async {
    if (throwOnUpdate) throw StateError('forçado pra teste');
    lastUpdated = reminder;
    return reminder;
  }

  @override
  Future<void> softDelete(String id) async {
    lastDeletedId = id;
  }

  @override
  Future<Reminder?> getById(String id) async => null;
  @override
  Future<List<Reminder>> listByVehicle(String vehicleId) async => const [];
  @override
  Stream<List<Reminder>> watchByVehicle(String vehicleId) =>
      const Stream.empty();
  @override
  Future<Reminder> markDone(
    String id, {
    int? currentOdometerKm,
    required DateTime now,
    required String Function() generateId,
  }) async {
    throw UnimplementedError('markDone não usado neste teste');
  }
}

void main() {
  late _FakeReminderRepository repo;
  late ReminderSaver saver;

  setUp(() {
    repo = _FakeReminderRepository();
    int counter = 0;
    saver = ReminderSaver(repo, generateId: () => 'id-${++counter}');
  });

  group('create', () {
    test(
      'por_km: dueKm preservado, dueDate null, isDone false (default)',
      () async {
        final saved = await saver.create(
          vehicleId: 'v1',
          type: ReminderType.porKm,
          title: 'Troca de óleo',
          dueKm: 50000,
        );

        expect(repo.lastCreated, isNotNull);
        expect(repo.lastCreated!.id, 'id-1');
        expect(repo.lastCreated!.vehicleId, 'v1');
        expect(repo.lastCreated!.type, ReminderType.porKm);
        expect(repo.lastCreated!.title, 'Troca de óleo');
        expect(repo.lastCreated!.dueKm, 50000);
        expect(repo.lastCreated!.dueDate, isNull);
        expect(repo.lastCreated!.isDone, false);

        expect(saved, repo.lastCreated);
      },
    );

    test('por_data: dueDate preservado, dueKm null', () async {
      final due = DateTime.utc(2026, 12, 31);
      await saver.create(
        vehicleId: 'v1',
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: due,
      );

      expect(repo.lastCreated!.type, ReminderType.porData);
      expect(repo.lastCreated!.dueDate, due);
      expect(repo.lastCreated!.dueKm, isNull);
    });
  });

  group('update', () {
    test('preserva id, vehicleId, createdAt; aplica campos novos', () async {
      final original = Reminder(
        id: 'orig',
        vehicleId: 'v1',
        type: ReminderType.porKm,
        title: 'Velho',
        dueKm: 40000,
        isDone: false,
        createdAt: DateTime.utc(2026, 5, 20),
        updatedAt: DateTime.utc(2026, 5, 20),
        syncStatus: SyncStatus.synced,
      );

      final updated = await saver.update(
        original,
        type: ReminderType.porData,
        title: 'Novo',
        dueDate: DateTime.utc(2027, 1, 1),
        isDone: true,
      );

      expect(repo.lastUpdated, isNotNull);
      expect(repo.lastUpdated!.id, 'orig'); // preservado
      expect(repo.lastUpdated!.vehicleId, 'v1'); // preservado
      expect(repo.lastUpdated!.createdAt, original.createdAt); // preservado
      expect(repo.lastUpdated!.type, ReminderType.porData);
      expect(repo.lastUpdated!.title, 'Novo');
      expect(repo.lastUpdated!.dueDate, DateTime.utc(2027, 1, 1));
      expect(repo.lastUpdated!.isDone, true);

      expect(updated, repo.lastUpdated);
    });
  });

  group('toggleDone', () {
    test('flipa isDone preservando outros campos', () async {
      final original = Reminder(
        id: 'orig',
        vehicleId: 'v1',
        type: ReminderType.porKm,
        title: 'Lavagem',
        dueKm: 60000,
        isDone: false,
        createdAt: DateTime.utc(2026, 5, 20),
        updatedAt: DateTime.utc(2026, 5, 20),
        syncStatus: SyncStatus.synced,
      );

      final toggled = await saver.toggleDone(original);

      expect(repo.lastUpdated!.isDone, true);
      expect(repo.lastUpdated!.id, 'orig');
      expect(repo.lastUpdated!.title, 'Lavagem');
      expect(repo.lastUpdated!.dueKm, 60000);
      expect(toggled, repo.lastUpdated);

      // E flipa de volta.
      final flippedBack = await saver.toggleDone(toggled);
      expect(repo.lastUpdated!.isDone, false);
      expect(flippedBack, repo.lastUpdated);
    });
  });

  group('delete', () {
    test('chama repo.softDelete com o id', () async {
      await saver.delete('algum-id');
      expect(repo.lastDeletedId, 'algum-id');
    });
  });

  group('propagação de erro', () {
    test('update propaga erro do repo', () async {
      repo.throwOnUpdate = true;
      final original = Reminder(
        id: 'orig',
        vehicleId: 'v1',
        type: ReminderType.porKm,
        title: 'X',
        dueKm: 1,
        isDone: false,
        createdAt: DateTime.utc(2026, 5, 20),
        updatedAt: DateTime.utc(2026, 5, 20),
        syncStatus: SyncStatus.synced,
      );
      expect(
        () => saver.update(
          original,
          type: ReminderType.porKm,
          title: 'Y',
          dueKm: 2,
          isDone: false,
        ),
        throwsStateError,
      );
    });
  });
}

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart';
import 'package:autolog/features/reminders/notification_scheduler.dart';
import 'package:autolog/features/reminders/reminder_trigger_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 4.4 — disparo de lembretes por km.
/// Spec: docs/specs/sprint-4.4-km-trigger.md

class _FakeReminderRepo implements ReminderRepository {
  final List<Reminder> store = [];

  @override
  Future<List<Reminder>> listByVehicle(String vehicleId) async => store
      .where((r) => r.vehicleId == vehicleId && r.deletedAt == null)
      .toList();

  // Stubs irrelevantes para este teste.
  @override
  Future<Reminder> create(Reminder reminder) async => reminder;
  @override
  Future<Reminder> update(Reminder reminder) async => reminder;
  @override
  Future<void> softDelete(String id) async {}
  @override
  Future<Reminder?> getById(String id) async => null;
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

class _FakeFuelRepo implements FuelEntryRepository {
  final List<FuelEntry> store = [];

  @override
  Future<List<FuelEntry>> listByVehicle(String vehicleId) async => store
      .where((e) => e.vehicleId == vehicleId && e.deletedAt == null)
      .toList();

  @override
  Future<FuelEntry> create(FuelEntry entry) async => entry;
  @override
  Future<FuelEntry> update(FuelEntry entry) async => entry;
  @override
  Future<void> softDelete(String id) async {}
  @override
  Future<FuelEntry?> getById(String id) async => null;
  @override
  Stream<List<FuelEntry>> watchByVehicle(String vehicleId) =>
      const Stream.empty();
}

class _ThrowingScheduler extends FakeNotificationScheduler {
  @override
  Future<void> showNow({
    required String id,
    required String title,
    required String body,
  }) async {
    throw StateError('boom');
  }
}

void main() {
  late _FakeReminderRepo reminders;
  late _FakeFuelRepo fuelEntries;
  late FakeNotificationScheduler scheduler;
  late ReminderTriggerService service;
  late Vehicle vehicle;

  Reminder kmReminder({
    required String id,
    required int dueKm,
    bool isDone = false,
    DateTime? deletedAt,
  }) {
    return Reminder(
      id: id,
      vehicleId: 'v1',
      type: ReminderType.porKm,
      title: 'Troca de óleo $id',
      dueKm: dueKm,
      isDone: isDone,
      createdAt: DateTime.utc(2026, 5, 24),
      updatedAt: DateTime.utc(2026, 5, 24),
      deletedAt: deletedAt,
      syncStatus: SyncStatus.pending,
    );
  }

  Reminder dateReminder({required String id, required DateTime dueDate}) {
    return Reminder(
      id: id,
      vehicleId: 'v1',
      type: ReminderType.porData,
      title: 'IPVA $id',
      dueDate: dueDate,
      isDone: false,
      createdAt: DateTime.utc(2026, 5, 24),
      updatedAt: DateTime.utc(2026, 5, 24),
      syncStatus: SyncStatus.pending,
    );
  }

  FuelEntry fuel({
    required String id,
    required int odometer,
    required DateTime date,
  }) {
    return FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: odometer,
      liters: Decimal.parse('40'),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse('200'),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  setUp(() {
    reminders = _FakeReminderRepo();
    fuelEntries = _FakeFuelRepo();
    scheduler = FakeNotificationScheduler();
    service = ReminderTriggerService(
      reminders: reminders,
      fuelEntries: fuelEntries,
      scheduler: scheduler,
    );
    vehicle = Vehicle(
      id: 'v1',
      userId: 'u1',
      nickname: 'Civic',
      fuelType: FuelType.gasolina,
      initialOdometer: 10000,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      syncStatus: SyncStatus.pending,
    );
  });

  test(
    'cruzamento simples — sem fuel anterior, usa vehicle.initialOdometer',
    () async {
      reminders.store.add(kmReminder(id: 'r1', dueKm: 15000));
      final entry = fuel(
        id: 'f1',
        odometer: 16000,
        date: DateTime.utc(2026, 5, 24),
      );

      await service.onFuelEntryRecorded(vehicle, entry);

      expect(scheduler.fired, hasLength(1));
      expect(scheduler.fired.first.id, 'r1');
    },
  );

  test('cruzamento com fuel anterior em 14000 → dispara', () async {
    reminders.store.add(kmReminder(id: 'r1', dueKm: 15000));
    fuelEntries.store.add(
      fuel(id: 'f0', odometer: 14000, date: DateTime.utc(2026, 5, 20)),
    );
    final entry = fuel(
      id: 'f1',
      odometer: 16000,
      date: DateTime.utc(2026, 5, 24),
    );

    await service.onFuelEntryRecorded(vehicle, entry);

    expect(scheduler.fired, hasLength(1));
  });

  test('não cruza — alvo já passou em fuel anterior', () async {
    reminders.store.add(kmReminder(id: 'r1', dueKm: 15000));
    fuelEntries.store.add(
      fuel(id: 'f0', odometer: 16000, date: DateTime.utc(2026, 5, 20)),
    );
    final entry = fuel(
      id: 'f1',
      odometer: 17000,
      date: DateTime.utc(2026, 5, 24),
    );

    await service.onFuelEntryRecorded(vehicle, entry);

    expect(scheduler.fired, isEmpty);
  });

  test('não cruza — alvo acima do novo entry', () async {
    reminders.store.add(kmReminder(id: 'r1', dueKm: 20000));
    final entry = fuel(
      id: 'f1',
      odometer: 16000,
      date: DateTime.utc(2026, 5, 24),
    );

    await service.onFuelEntryRecorded(vehicle, entry);

    expect(scheduler.fired, isEmpty);
  });

  test('reminder porData não dispara', () async {
    reminders.store.add(
      dateReminder(id: 'r1', dueDate: DateTime.utc(2026, 6, 1)),
    );
    final entry = fuel(
      id: 'f1',
      odometer: 16000,
      date: DateTime.utc(2026, 5, 24),
    );

    await service.onFuelEntryRecorded(vehicle, entry);

    expect(scheduler.fired, isEmpty);
  });

  test('reminder done não dispara mesmo cruzando', () async {
    reminders.store.add(kmReminder(id: 'r1', dueKm: 15000, isDone: true));
    final entry = fuel(
      id: 'f1',
      odometer: 16000,
      date: DateTime.utc(2026, 5, 24),
    );

    await service.onFuelEntryRecorded(vehicle, entry);

    expect(scheduler.fired, isEmpty);
  });

  test(
    'reminder soft-deletado não aparece em listByVehicle, não dispara',
    () async {
      reminders.store.add(
        kmReminder(
          id: 'r1',
          dueKm: 15000,
          deletedAt: DateTime.utc(2026, 5, 23),
        ),
      );
      final entry = fuel(
        id: 'f1',
        odometer: 16000,
        date: DateTime.utc(2026, 5, 24),
      );

      await service.onFuelEntryRecorded(vehicle, entry);

      expect(scheduler.fired, isEmpty);
    },
  );

  test('múltiplos reminders cruzando: dispara uma vez por reminder', () async {
    reminders.store.addAll([
      kmReminder(id: 'r1', dueKm: 15000),
      kmReminder(id: 'r2', dueKm: 15500),
      kmReminder(id: 'r3', dueKm: 16000),
    ]);
    final entry = fuel(
      id: 'f1',
      odometer: 17000,
      date: DateTime.utc(2026, 5, 24),
    );

    await service.onFuelEntryRecorded(vehicle, entry);

    expect(
      scheduler.fired.map((e) => e.id).toSet(),
      equals({'r1', 'r2', 'r3'}),
    );
  });

  test(
    'vehicle.initialOdometer como baseline quando não há fuel anterior',
    () async {
      // initial=10000 (do setUp), reminder dueKm=10500, novo entry odometer=11000.
      reminders.store.add(kmReminder(id: 'r1', dueKm: 10500));
      final entry = fuel(
        id: 'f1',
        odometer: 11000,
        date: DateTime.utc(2026, 5, 24),
      );

      await service.onFuelEntryRecorded(vehicle, entry);

      expect(scheduler.fired, hasLength(1));
    },
  );

  test('sem reminders: 0 firings, sem erro', () async {
    final entry = fuel(
      id: 'f1',
      odometer: 16000,
      date: DateTime.utc(2026, 5, 24),
    );
    await service.onFuelEntryRecorded(vehicle, entry);
    expect(scheduler.fired, isEmpty);
  });

  test('NUNCA lança: scheduler que lança não propaga', () async {
    final throwingService = ReminderTriggerService(
      reminders: reminders,
      fuelEntries: fuelEntries,
      scheduler: _ThrowingScheduler(),
    );
    reminders.store.add(kmReminder(id: 'r1', dueKm: 15000));
    final entry = fuel(
      id: 'f1',
      odometer: 16000,
      date: DateTime.utc(2026, 5, 24),
    );

    // Não deve lançar.
    await throwingService.onFuelEntryRecorded(vehicle, entry);
  });
}

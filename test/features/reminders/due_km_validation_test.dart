import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reminders/reminder_validators.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 4.5 — validação dueKm > odômetro atual.
/// Spec: docs/specs/sprint-4.5-due-km-validation.md
void main() {
  FuelEntry fuel({
    required String id,
    required int odometer,
    DateTime? deletedAt,
  }) {
    final date = DateTime.utc(2026, 5, 24);
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
      deletedAt: deletedAt,
      syncStatus: SyncStatus.pending,
    );
  }

  group('validateDueKm', () {
    test('sem entries, dueKm > initial: null', () {
      expect(
        validateDueKm(
          dueKm: 15000,
          vehicleInitialOdometer: 10000,
          entries: const [],
        ),
        isNull,
      );
    });

    test('sem entries, dueKm == initial: erro com "atual" e o valor', () {
      final r = validateDueKm(
        dueKm: 10000,
        vehicleInitialOdometer: 10000,
        entries: const [],
      );
      expect(r, isNotNull);
      expect(r!.toLowerCase(), contains('atual'));
      expect(r, contains('10000'));
    });

    test('sem entries, dueKm < initial: erro', () {
      final r = validateDueKm(
        dueKm: 9000,
        vehicleInitialOdometer: 10000,
        entries: const [],
      );
      expect(r, isNotNull);
      expect(r, contains('10000'));
    });

    test('com entries, dueKm > max(odometers): null', () {
      expect(
        validateDueKm(
          dueKm: 20000,
          vehicleInitialOdometer: 10000,
          entries: [fuel(id: 'f1', odometer: 16000)],
        ),
        isNull,
      );
    });

    test('com entries, dueKm == max(odometers): erro com o max', () {
      final r = validateDueKm(
        dueKm: 16000,
        vehicleInitialOdometer: 10000,
        entries: [fuel(id: 'f1', odometer: 16000)],
      );
      expect(r, isNotNull);
      expect(r, contains('16000'));
    });

    test('com entries, dueKm < max(odometers): erro', () {
      final r = validateDueKm(
        dueKm: 12000,
        vehicleInitialOdometer: 10000,
        entries: [fuel(id: 'f1', odometer: 16000)],
      );
      expect(r, isNotNull);
      expect(r, contains('16000'));
    });

    test('entries soft-deletados são ignorados', () {
      // Maior odômetro (15000) tá deletado → max efetivo = max(initial=10000, 12000) = 12000.
      final entries = [
        fuel(id: 'f1', odometer: 15000, deletedAt: DateTime.utc(2026, 5, 23)),
        fuel(id: 'f2', odometer: 12000),
      ];
      // dueKm=13000 > 12000 → válido.
      expect(
        validateDueKm(
          dueKm: 13000,
          vehicleInitialOdometer: 10000,
          entries: entries,
        ),
        isNull,
      );
    });

    test('mistura: initial < entries.max, dueKm entre initial e entries.max → '
        'erro', () {
      // initial=10000, entries.max=15000, dueKm=12000 → erro (15000 é o atual).
      final r = validateDueKm(
        dueKm: 12000,
        vehicleInitialOdometer: 10000,
        entries: [fuel(id: 'f1', odometer: 15000)],
      );
      expect(r, isNotNull);
      expect(r, contains('15000'));
    });
  });
}

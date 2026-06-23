// Roundtrip toJson/fromJson do BackupBundle — garante que dados podem ser
// exportados e re-importados sem perda.

import 'dart:convert';

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/backup/backup_models.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

BackupBundle _sampleBundle() {
  final now = DateTime.utc(2026, 6, 22, 12);
  return BackupBundle(
    version: kBackupSchemaVersion,
    exportedAt: now,
    appVersion: '1.0.0',
    userId: 'user-42',
    vehicles: [
      Vehicle(
        id: 'v-1',
        userId: 'user-42',
        nickname: 'Civic',
        fuelType: FuelType.flex,
        initialOdometer: 10000,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ),
    ],
    fuelEntries: [
      FuelEntry(
        id: 'f-1',
        vehicleId: 'v-1',
        date: now,
        odometer: 11000,
        liters: Decimal.parse('30'),
        pricePerLiter: Decimal.parse('5.89'),
        totalCost: Decimal.parse('176.70'),
        fullTank: true,
        fuelType: FuelType.gasolina,
        source: FuelSource.manual,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ),
    ],
    expenses: [
      Expense(
        id: 'e-1',
        vehicleId: 'v-1',
        date: now,
        category: ExpenseCategory.manutencao,
        description: 'Troca de óleo',
        amount: Decimal.parse('150.00'),
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ),
    ],
    reminders: [
      Reminder(
        id: 'r-1',
        vehicleId: 'v-1',
        type: ReminderType.porData,
        title: 'IPVA',
        dueDate: DateTime.utc(2027),
        isDone: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ),
    ],
    fines: [
      Fine(
        id: 'fi-1',
        vehicleId: 'v-1',
        issuedAt: now,
        description: 'Avanço de sinal',
        amount: Decimal.parse('195.23'),
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ),
    ],
    insurances: [
      Insurance(
        id: 'i-1',
        vehicleId: 'v-1',
        insurer: 'Porto',
        startsAt: now,
        endsAt: DateTime.utc(2027),
        premiumPaid: Decimal.parse('2400'),
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      ),
    ],
    userProfile: UserProfile(
      userId: 'user-42',
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    ),
  );
}

void main() {
  group('BackupBundle', () {
    test('toJson + fromJson preservam contagens das listas', () {
      final original = _sampleBundle();
      final json = jsonDecode(jsonEncode(original.toJson()))
          as Map<String, dynamic>;
      final round = BackupBundle.fromJson(json);

      expect(round.vehicles.length, 1);
      expect(round.fuelEntries.length, 1);
      expect(round.expenses.length, 1);
      expect(round.reminders.length, 1);
      expect(round.fines.length, 1);
      expect(round.insurances.length, 1);
      expect(round.userProfile, isNotNull);
    });

    test('toJson + fromJson preservam valores monetários como Decimal', () {
      final original = _sampleBundle();
      final json = jsonDecode(jsonEncode(original.toJson()))
          as Map<String, dynamic>;
      final round = BackupBundle.fromJson(json);

      expect(round.fuelEntries.first.totalCost, Decimal.parse('176.70'));
      expect(round.expenses.first.amount, Decimal.parse('150.00'));
      expect(round.fines.first.amount, Decimal.parse('195.23'));
      expect(round.insurances.first.premiumPaid, Decimal.parse('2400'));
    });

    test('fromJson rejeita version != atual', () {
      final json = {
        ..._sampleBundle().toJson(),
        'version': 999,
      };
      expect(
        () => BackupBundle.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'mensagem',
            contains('999'),
          ),
        ),
      );
    });

    test('fromJson rejeita JSON sem version', () {
      final json = _sampleBundle().toJson()..remove('version');
      expect(
        () => BackupBundle.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('exportedAt é serializado em ISO-8601 UTC', () {
      final original = _sampleBundle();
      final json = original.toJson();
      expect(json['exported_at'], '2026-06-22T12:00:00.000Z');
    });
  });
}

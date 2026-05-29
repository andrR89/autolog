// Sprint 6.MM — Schema v18: colunas de recorrência na tabela reminders.
//
// Verifica:
// - schemaVersion = 18
// - novas colunas: interval_km, interval_days, parent_reminder_id
// - colunas nullable (default null)
// - lembrete legacy (sem essas colunas) funciona com NULL nesses campos
// - migration v17 → v18 adiciona as 3 colunas

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schema v18 — Recorrência em Reminders', () {
    test('schemaVersion é 18', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 18);
      db.close();
    });

    test(
      'insert com interval_days, interval_km e parent_reminder_id',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final now = DateTime.utc(2026, 5, 29, 10, 0, 0);

        await db
            .into(db.reminders)
            .insert(
              RemindersCompanion.insert(
                id: 'r-recorrente',
                vehicleId: 'v1',
                type: ReminderType.porData,
                title: 'IPVA anual',
                dueDate: drift.Value(DateTime.utc(2026, 12, 31)),
                isDone: const drift.Value(false),
                createdAt: now,
                updatedAt: now,
                intervalDays: const drift.Value(365),
                intervalKm: const drift.Value(null),
                parentReminderId: const drift.Value(null),
              ),
            );

        final row = await (db.select(
          db.reminders,
        )..where((t) => t.id.equals('r-recorrente'))).getSingle();

        expect(row.intervalDays, 365);
        expect(row.intervalKm, isNull);
        expect(row.parentReminderId, isNull);

        await db.close();
      },
    );

    test('insert com parent_reminder_id preenchido', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 29, 10, 0, 0);

      // Insert do pai.
      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              id: 'r-pai',
              vehicleId: 'v1',
              type: ReminderType.porKm,
              title: 'Troca de óleo',
              dueKm: const drift.Value(50000),
              isDone: const drift.Value(true),
              createdAt: now,
              updatedAt: now,
              intervalKm: const drift.Value(10000),
            ),
          );

      // Insert do filho.
      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              id: 'r-filho',
              vehicleId: 'v1',
              type: ReminderType.porKm,
              title: 'Troca de óleo',
              dueKm: const drift.Value(60000),
              isDone: const drift.Value(false),
              createdAt: now,
              updatedAt: now,
              intervalKm: const drift.Value(10000),
              parentReminderId: const drift.Value('r-pai'),
            ),
          );

      final filho = await (db.select(
        db.reminders,
      )..where((t) => t.id.equals('r-filho'))).getSingle();

      expect(filho.parentReminderId, 'r-pai');
      expect(filho.intervalKm, 10000);

      await db.close();
    });

    test('insert sem colunas de recorrência → nullable por default', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 29, 10, 0, 0);

      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              id: 'r-oneshot',
              vehicleId: 'v1',
              type: ReminderType.porData,
              title: 'Revisão simples',
              dueDate: drift.Value(DateTime.utc(2026, 8, 1)),
              isDone: const drift.Value(false),
              createdAt: now,
              updatedAt: now,
              // intervalDays, intervalKm, parentReminderId omitidos → null
            ),
          );

      final row = await (db.select(
        db.reminders,
      )..where((t) => t.id.equals('r-oneshot'))).getSingle();

      expect(row.intervalDays, isNull);
      expect(row.intervalKm, isNull);
      expect(row.parentReminderId, isNull);

      await db.close();
    });

    test('múltiplos lembretes com e sem recorrência coexistem', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 29, 10, 0, 0);

      for (var i = 1; i <= 3; i++) {
        await db
            .into(db.reminders)
            .insert(
              RemindersCompanion.insert(
                id: 'r$i',
                vehicleId: 'v1',
                type: ReminderType.porData,
                title: 'Lembrete $i',
                dueDate: drift.Value(DateTime.utc(2026, i, 1)),
                isDone: const drift.Value(false),
                createdAt: now,
                updatedAt: now,
                intervalDays: i == 1
                    ? const drift.Value(365)
                    : const drift.Value(null),
              ),
            );
      }

      final rows = await db.select(db.reminders).get();
      expect(rows, hasLength(3));

      final recurring = rows.where((r) => r.intervalDays != null).toList();
      expect(recurring, hasLength(1));
      expect(recurring.single.id, 'r1');

      await db.close();
    });
  });

  group('Migration v17 → v18', () {
    test(
      'addColumn interval_days/interval_km/parent_reminder_id em banco existente',
      () async {
        // Simula um banco v17 sem as colunas novas.
        final raw = NativeDatabase.memory();
        final legacyDb = _LegacyDbV17(raw);

        // Cria a tabela reminders com o schema v17 (sem colunas de recorrência).
        await legacyDb.customStatement('''
        CREATE TABLE reminders (
          id TEXT NOT NULL PRIMARY KEY,
          vehicle_id TEXT NOT NULL,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          due_km INTEGER,
          due_date INTEGER,
          is_done INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');

        // Insere dado legacy.
        await legacyDb.customStatement('''
        INSERT INTO reminders (id, vehicle_id, type, title, due_date, is_done, created_at, updated_at)
        VALUES ('r-legacy', 'v1', 'por_data', 'IPVA', 1748520000, 0, 1748520000, 1748520000)
      ''');

        // Simula migration: adiciona as 3 colunas.
        await legacyDb.customStatement(
          'ALTER TABLE reminders ADD COLUMN interval_days INTEGER',
        );
        await legacyDb.customStatement(
          'ALTER TABLE reminders ADD COLUMN interval_km INTEGER',
        );
        await legacyDb.customStatement(
          'ALTER TABLE reminders ADD COLUMN parent_reminder_id TEXT',
        );

        // Legacy row deve ter NULL nas novas colunas.
        final rows = await legacyDb
            .customSelect('SELECT * FROM reminders WHERE id = \'r-legacy\'')
            .get();
        expect(rows, hasLength(1));
        expect(rows.single.data['interval_days'], isNull);
        expect(rows.single.data['interval_km'], isNull);
        expect(rows.single.data['parent_reminder_id'], isNull);

        // Nova linha pode preencher os campos.
        await legacyDb.customStatement('''
        INSERT INTO reminders
          (id, vehicle_id, type, title, due_date, is_done, created_at, updated_at,
           interval_days, interval_km, parent_reminder_id)
        VALUES ('r-recorrente', 'v1', 'por_data', 'IPVA anual', 1748520000, 0,
                1748520000, 1748520000, 365, NULL, 'r-legacy')
      ''');

        final newRows = await legacyDb
            .customSelect('SELECT * FROM reminders WHERE id = \'r-recorrente\'')
            .get();
        expect(newRows.single.data['interval_days'], 365);
        expect(newRows.single.data['parent_reminder_id'], 'r-legacy');

        await legacyDb.close();
      },
    );
  });
}

class _LegacyDbV17 extends drift.GeneratedDatabase {
  _LegacyDbV17(super.executor);

  @override
  int get schemaVersion => 17;

  @override
  Iterable<drift.TableInfo<drift.Table, dynamic>> get allTables => const [];

  @override
  drift.DriftDatabaseOptions get options => const drift.DriftDatabaseOptions();
}

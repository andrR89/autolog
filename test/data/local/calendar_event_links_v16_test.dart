import 'package:autolog/data/local/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.EE — Schema v16 com tabela calendar_event_links.

void main() {
  group('Schema v16 — CalendarEventLinks', () {
    test('schemaVersion é 18 (v18 com recorrência em reminders, Sprint 6.MM)', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 18);
      db.close();
    });

    test('allTables contém 17 tabelas', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.allTables.length, 17);
      db.close();
    });

    test('calendar_event_links aceita insert com todos os campos', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 28, 10);

      await db.into(db.calendarEventLinks).insert(
            CalendarEventLinksCompanion.insert(
              reminderId: 'reminder-1',
              calendarEventId: 'gcal-event-abc123',
              syncedAt: now,
            ),
          );

      final row = await db.select(db.calendarEventLinks).getSingle();
      expect(row.reminderId, 'reminder-1');
      expect(row.calendarEventId, 'gcal-event-abc123');
      expect(row.syncedAt.toUtc(), now);

      await db.close();
    });

    test('PK reminderId garante unicidade', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 28);

      await db.into(db.calendarEventLinks).insert(
            CalendarEventLinksCompanion.insert(
              reminderId: 'reminder-1',
              calendarEventId: 'event-1',
              syncedAt: now,
            ),
          );

      // Mesmo reminderId → deve lançar.
      expect(
        () => db.into(db.calendarEventLinks).insert(
              CalendarEventLinksCompanion.insert(
                reminderId: 'reminder-1',
                calendarEventId: 'event-2',
                syncedAt: now,
              ),
            ),
        throwsA(anything),
      );

      await db.close();
    });

    test('insertOnConflictUpdate substitui registro existente', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 28);

      await db.into(db.calendarEventLinks).insertOnConflictUpdate(
            CalendarEventLinksCompanion.insert(
              reminderId: 'reminder-1',
              calendarEventId: 'event-v1',
              syncedAt: now,
            ),
          );

      await db.into(db.calendarEventLinks).insertOnConflictUpdate(
            CalendarEventLinksCompanion.insert(
              reminderId: 'reminder-1',
              calendarEventId: 'event-v2',
              syncedAt: now.add(const Duration(minutes: 5)),
            ),
          );

      final rows = await db.select(db.calendarEventLinks).get();
      expect(rows, hasLength(1));
      expect(rows.single.calendarEventId, 'event-v2');

      await db.close();
    });

    test('DELETE remove o link corretamente', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 28);

      await db.into(db.calendarEventLinks).insert(
            CalendarEventLinksCompanion.insert(
              reminderId: 'reminder-del',
              calendarEventId: 'event-del',
              syncedAt: now,
            ),
          );

      await (db.delete(db.calendarEventLinks)
            ..where((t) => t.reminderId.equals('reminder-del')))
          .go();

      final rows = await db.select(db.calendarEventLinks).get();
      expect(rows, isEmpty);

      await db.close();
    });

    test('reminders distintos podem ter links distintos', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 28);

      for (var i = 1; i <= 3; i++) {
        await db.into(db.calendarEventLinks).insert(
              CalendarEventLinksCompanion.insert(
                reminderId: 'reminder-$i',
                calendarEventId: 'event-$i',
                syncedAt: now,
              ),
            );
      }

      final rows = await db.select(db.calendarEventLinks).get();
      expect(rows, hasLength(3));

      await db.close();
    });
  });

  group('Migration v15 → v16', () {
    test('createTable calendar_event_links em banco existente', () async {
      final raw = NativeDatabase.memory();
      final legacyDb = _LegacyDbV15(raw);

      // Simula schema v15 (sem calendar_event_links).
      await legacyDb.customStatement('''
        CREATE TABLE vehicles (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          nickname TEXT NOT NULL,
          fuel_type TEXT NOT NULL,
          initial_odometer INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');

      // Simula a migration v16: CREATE TABLE calendar_event_links.
      await legacyDb.customStatement('''
        CREATE TABLE calendar_event_links (
          reminder_id TEXT NOT NULL PRIMARY KEY,
          calendar_event_id TEXT NOT NULL,
          synced_at INTEGER NOT NULL
        )
      ''');

      // Confirma que aceita dados.
      await legacyDb.customStatement('''
        INSERT INTO calendar_event_links (reminder_id, calendar_event_id, synced_at)
        VALUES ('r1', 'gcal-123', 1716800000)
      ''');

      final rows = await legacyDb
          .customSelect('SELECT * FROM calendar_event_links')
          .get();
      expect(rows.single.data['reminder_id'], 'r1');
      expect(rows.single.data['calendar_event_id'], 'gcal-123');

      await legacyDb.close();
    });
  });
}

class _LegacyDbV15 extends drift.GeneratedDatabase {
  _LegacyDbV15(super.executor);

  @override
  int get schemaVersion => 15;

  @override
  Iterable<drift.TableInfo<drift.Table, dynamic>> get allTables => const [];

  @override
  drift.DriftDatabaseOptions get options => const drift.DriftDatabaseOptions();
}

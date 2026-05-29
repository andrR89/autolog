import 'package:autolog/data/local/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.W.4 — Schema v14 com 4 colunas de prefs de notificação.

void main() {
  group('Schema v14', () {
    test('schemaVersion bumped to 18 (inclui onboarding_seen, Sprint 6.GG)', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 18);
      db.close();
    });

    test('allTables contém 17 tabelas', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.allTables.length, 17);
      db.close();
    });

    test('user_settings tem 4 colunas de notif com default true', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userSettings).insert(
            UserSettingsCompanion.insert(userId: 'user-1'),
          );
      final row = await db.select(db.userSettings).getSingle();
      expect(row.notifConsumptionDrop, isTrue);
      expect(row.notifCnh, isTrue);
      expect(row.notifFiscal, isTrue);
      expect(row.notifRecapReady, isTrue);
      await db.close();
    });

    test('user_settings notifConsumptionDrop pode ser false', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userSettings).insertOnConflictUpdate(
            UserSettingsCompanion.insert(
              userId: 'user-1',
              notifConsumptionDrop: const drift.Value(false),
            ),
          );
      final row = await (db.select(db.userSettings)
            ..where((t) => t.userId.equals('user-1')))
          .getSingle();
      expect(row.notifConsumptionDrop, isFalse);
      expect(row.notifCnh, isTrue); // outros permanecem true
      await db.close();
    });

    test('user_settings notifCnh pode ser false', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userSettings).insertOnConflictUpdate(
            UserSettingsCompanion.insert(
              userId: 'user-1',
              notifCnh: const drift.Value(false),
            ),
          );
      final row = await (db.select(db.userSettings)
            ..where((t) => t.userId.equals('user-1')))
          .getSingle();
      expect(row.notifCnh, isFalse);
      expect(row.notifFiscal, isTrue);
      await db.close();
    });

    test('user_settings notifFiscal pode ser false', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userSettings).insertOnConflictUpdate(
            UserSettingsCompanion.insert(
              userId: 'user-1',
              notifFiscal: const drift.Value(false),
            ),
          );
      final row = await (db.select(db.userSettings)
            ..where((t) => t.userId.equals('user-1')))
          .getSingle();
      expect(row.notifFiscal, isFalse);
      expect(row.notifRecapReady, isTrue);
      await db.close();
    });

    test('user_settings notifRecapReady pode ser false', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userSettings).insertOnConflictUpdate(
            UserSettingsCompanion.insert(
              userId: 'user-1',
              notifRecapReady: const drift.Value(false),
            ),
          );
      final row = await (db.select(db.userSettings)
            ..where((t) => t.userId.equals('user-1')))
          .getSingle();
      expect(row.notifRecapReady, isFalse);
      expect(row.notifConsumptionDrop, isTrue);
      await db.close();
    });

    test('user_settings: themePref persiste junto das prefs de notif', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userSettings).insertOnConflictUpdate(
            UserSettingsCompanion.insert(
              userId: 'user-1',
              themePref: const drift.Value('dark'),
              notifCnh: const drift.Value(false),
            ),
          );
      final row = await (db.select(db.userSettings)
            ..where((t) => t.userId.equals('user-1')))
          .getSingle();
      expect(row.themePref, 'dark');
      expect(row.notifCnh, isFalse);
      expect(row.notifFiscal, isTrue);
      await db.close();
    });
  });

  group('Migration v13 → v14', () {
    test('addColumn das 4 colunas de notif (simulação manual)', () async {
      final raw = NativeDatabase.memory();
      final legacyDb = _LegacyDbV13(raw);

      // Cria tabela como estava em v13.
      await legacyDb.customStatement('''
        CREATE TABLE user_settings (
          user_id TEXT NOT NULL PRIMARY KEY,
          theme_pref TEXT NOT NULL DEFAULT 'system'
        )
      ''');
      await legacyDb.customStatement('''
        INSERT INTO user_settings (user_id) VALUES ('user-abc')
      ''');

      // Simula addColumn das 4 colunas com default true.
      await legacyDb.customStatement('''
        ALTER TABLE user_settings
        ADD COLUMN notif_consumption_drop INTEGER NOT NULL DEFAULT 1
      ''');
      await legacyDb.customStatement('''
        ALTER TABLE user_settings
        ADD COLUMN notif_cnh INTEGER NOT NULL DEFAULT 1
      ''');
      await legacyDb.customStatement('''
        ALTER TABLE user_settings
        ADD COLUMN notif_fiscal INTEGER NOT NULL DEFAULT 1
      ''');
      await legacyDb.customStatement('''
        ALTER TABLE user_settings
        ADD COLUMN notif_recap_ready INTEGER NOT NULL DEFAULT 1
      ''');

      final rows =
          await legacyDb.customSelect('SELECT * FROM user_settings').get();
      expect(rows.single.data['user_id'], 'user-abc');
      expect(rows.single.data['theme_pref'], 'system');
      expect(rows.single.data['notif_consumption_drop'], 1);
      expect(rows.single.data['notif_cnh'], 1);
      expect(rows.single.data['notif_fiscal'], 1);
      expect(rows.single.data['notif_recap_ready'], 1);

      await legacyDb.close();
    });
  });
}

class _LegacyDbV13 extends drift.GeneratedDatabase {
  _LegacyDbV13(super.executor);

  @override
  int get schemaVersion => 13;

  @override
  Iterable<drift.TableInfo<drift.Table, dynamic>> get allTables => const [];

  @override
  drift.DriftDatabaseOptions get options => const drift.DriftDatabaseOptions();
}

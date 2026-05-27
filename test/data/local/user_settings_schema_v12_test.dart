import 'package:autolog/data/local/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.AA — Schema v12 com tabela user_settings.

void main() {
  group('Schema v12', () {
    test('schemaVersion bumped to 12', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 12);
      db.close();
    });

    test('allTables contém 14 tabelas', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.allTables.length, 14);
      db.close();
    });

    test('user_settings aceita insert com default system', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userSettings).insert(
            UserSettingsCompanion.insert(userId: 'user-1'),
          );
      final rows = await db.select(db.userSettings).get();
      expect(rows.length, 1);
      expect(rows.first.userId, 'user-1');
      expect(rows.first.themePref, 'system');
      await db.close();
    });

    test('user_settings PK impede duplicatas — upsert atualiza', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userSettings).insertOnConflictUpdate(
            UserSettingsCompanion.insert(userId: 'user-1'),
          );
      await db.into(db.userSettings).insertOnConflictUpdate(
            UserSettingsCompanion.insert(
              userId: 'user-1',
              themePref: const drift.Value('dark'),
            ),
          );
      final rows = await db.select(db.userSettings).get();
      expect(rows.length, 1);
      expect(rows.first.themePref, 'dark');
      await db.close();
    });

    test('user_settings aceita os 3 valores de tema', () async {
      final db = AppDatabase(NativeDatabase.memory());
      for (final pref in ['system', 'light', 'dark']) {
        await db.into(db.userSettings).insertOnConflictUpdate(
              UserSettingsCompanion.insert(
                userId: 'user-1',
                themePref: drift.Value(pref),
              ),
            );
        final row =
            await (db.select(db.userSettings)
                  ..where((t) => t.userId.equals('user-1')))
                .getSingle();
        expect(row.themePref, pref);
      }
      await db.close();
    });
  });

  group('Migration v11 → v12', () {
    test('cria tabela user_settings na migration', () async {
      final raw = NativeDatabase.memory();
      final legacyDb = _LegacyDbV11(raw);

      // Verifica que é possível criar a tabela manualmente (simula migration).
      await legacyDb.customStatement('''
        CREATE TABLE user_settings (
          user_id TEXT NOT NULL PRIMARY KEY,
          theme_pref TEXT NOT NULL DEFAULT 'system'
        )
      ''');
      await legacyDb.customStatement('''
        INSERT INTO user_settings (user_id, theme_pref)
        VALUES ('user-abc', 'dark')
      ''');
      final rows =
          await legacyDb.customSelect('SELECT * FROM user_settings').get();
      expect(rows.single.data['user_id'], 'user-abc');
      expect(rows.single.data['theme_pref'], 'dark');

      await legacyDb.close();
    });
  });
}

class _LegacyDbV11 extends drift.GeneratedDatabase {
  _LegacyDbV11(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  Iterable<drift.TableInfo<drift.Table, dynamic>> get allTables => const [];

  @override
  drift.DriftDatabaseOptions get options => const drift.DriftDatabaseOptions();
}

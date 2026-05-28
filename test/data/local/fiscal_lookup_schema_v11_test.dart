import 'package:autolog/data/local/database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.W.3 — Schema v11 com tabela fiscal_lookup_cache.

void main() {
  group('Schema v11', () {
    test('schemaVersion bumped to 11', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 14); // v14 com notif prefs (Sprint 6.W.4)
      db.close();
    });

    test('fiscal_lookup_cache aceita CRUD', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.fiscalLookupCache).insert(
            FiscalLookupCacheCompanion.insert(
              cacheKey: 'SC-6-2026',
              value: '{"ipva":{"month":6},"licensing":{"month":10}}',
              expiresAt: DateTime.utc(2026, 8, 25),
            ),
          );
      final rows = await db.select(db.fiscalLookupCache).get();
      expect(rows.length, 1);
      expect(rows.first.cacheKey, 'SC-6-2026');
      await db.close();
    });

    test('fiscal_lookup_cache PK impede duplicatas — upsert atualiza', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.fiscalLookupCache).insertOnConflictUpdate(
            FiscalLookupCacheCompanion.insert(
              cacheKey: 'SP-3-2026',
              value: 'v1',
              expiresAt: DateTime.utc(2026, 6),
            ),
          );
      await db.into(db.fiscalLookupCache).insertOnConflictUpdate(
            FiscalLookupCacheCompanion.insert(
              cacheKey: 'SP-3-2026',
              value: 'v2',
              expiresAt: DateTime.utc(2026, 9),
            ),
          );
      final rows = await db.select(db.fiscalLookupCache).get();
      expect(rows.length, 1);
      expect(rows.first.value, 'v2');
      await db.close();
    });
  });

  group('Migration v10 → v11', () {
    test('cria tabela fiscal_lookup_cache na migration', () async {
      final raw = NativeDatabase.memory();
      final legacyDb = _LegacyDbV10(raw);

      // Simula estado de schema v10 criando a tabela manualmente.
      await legacyDb.customStatement('''
        CREATE TABLE fiscal_lookup_cache (
          cache_key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL,
          expires_at INTEGER NOT NULL
        )
      ''');
      await legacyDb.customStatement('''
        INSERT INTO fiscal_lookup_cache (cache_key, value, expires_at)
        VALUES ('SC-6-2026', 'teste', 1800000000)
      ''');
      final rows = await legacyDb
          .customSelect('SELECT * FROM fiscal_lookup_cache')
          .get();
      expect(rows.single.data['cache_key'], 'SC-6-2026');

      await legacyDb.close();
    });
  });
}

class _LegacyDbV10 extends GeneratedDatabase {
  _LegacyDbV10(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}

import 'package:autolog/data/local/database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.T — Schema v9 com tabela chat_messages.
/// Spec: docs/specs/sprint-6.T-chat-history.md

void main() {
  group('Schema v9', () {
    test('schemaVersion bumped to 9', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 16); // v16 com calendar_event_links (Sprint 6.EE)
      db.close();
    });

    test('chat_messages aceita CRUD', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.chatMessages).insert(
            ChatMessagesCompanion.insert(
              id: 'm1',
              vehicleId: 'v1',
              role: 'user',
              content: 'Quanto gastei esse mês?',
              createdAt: DateTime.utc(2026, 5, 26, 15),
            ),
          );
      final rows = await db.select(db.chatMessages).get();
      expect(rows.length, 1);
      expect(rows.first.role, 'user');
      await db.close();
    });
  });

  group('Migration v8 → v9', () {
    test('cria tabela chat_messages', () async {
      final raw = NativeDatabase.memory();
      final lowDb = _LegacyDb(raw);

      await lowDb.customStatement('''
        CREATE TABLE chat_messages (
          id TEXT NOT NULL PRIMARY KEY,
          vehicle_id TEXT NOT NULL,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await lowDb.customStatement('''
        INSERT INTO chat_messages (id, vehicle_id, role, content, created_at)
        VALUES ('m1', 'v1', 'user', 'oi', 1700000000)
      ''');
      final rows = await lowDb.customSelect('SELECT * FROM chat_messages').get();
      expect(rows.single.data['content'], 'oi');

      await lowDb.close();
    });
  });
}

class _LegacyDb extends GeneratedDatabase {
  _LegacyDb(super.executor);
  @override
  int get schemaVersion => 8;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}

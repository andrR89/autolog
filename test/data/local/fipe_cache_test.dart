import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/local/fipe_cache.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.I — DriftFipeCacheStore.
/// Spec: docs/specs/sprint-6.I-fipe-autocomplete.md

void main() {
  late AppDatabase db;
  late DriftFipeCacheStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftFipeCacheStore(db);
  });

  tearDown(() => db.close());

  test('read em key inexistente → null', () async {
    final r = await store.read('/cars/brands');
    expect(r, isNull);
  });

  test('write + read roundtrip', () async {
    final exp = DateTime.utc(2026, 6, 2);
    await store.write('/cars/brands', '[{"code":"1","name":"Acura"}]', exp);
    final r = await store.read('/cars/brands');
    expect(r, isNotNull);
    expect(r!.value, '[{"code":"1","name":"Acura"}]');
    expect(r.expiresAt, exp);
  });

  test('overwrite mesma key atualiza value e expiresAt', () async {
    await store.write('/k', 'old', DateTime.utc(2026, 6));
    await store.write('/k', 'new', DateTime.utc(2026, 7));
    final r = await store.read('/k');
    expect(r!.value, 'new');
    expect(r.expiresAt, DateTime.utc(2026, 7));
  });

  test('keys diferentes não interferem', () async {
    await store.write('/a', 'A', DateTime.utc(2026, 6));
    await store.write('/b', 'B', DateTime.utc(2026, 6));
    expect((await store.read('/a'))!.value, 'A');
    expect((await store.read('/b'))!.value, 'B');
  });
}

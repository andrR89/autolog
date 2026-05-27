import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/local/fiscal_lookup_cache.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.W.3 — DriftFiscalLookupCache CRUD.

void main() {
  late AppDatabase db;
  late DriftFiscalLookupCache store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftFiscalLookupCache(db);
  });

  tearDown(() => db.close());

  test('read em key inexistente → null', () async {
    final r = await store.read('SC-6-2026');
    expect(r, isNull);
  });

  test('write + read roundtrip', () async {
    final exp = DateTime.utc(2026, 8, 25);
    await store.write(
      'SC-6-2026',
      '{"ipva":{"month":6},"licensing":{"month":10}}',
      exp,
    );
    final r = await store.read('SC-6-2026');
    expect(r, isNotNull);
    expect(r!.cacheKey, 'SC-6-2026');
    expect(r.value, '{"ipva":{"month":6},"licensing":{"month":10}}');
    expect(r.expiresAt, exp);
  });

  test('overwrite mesma key atualiza value e expiresAt', () async {
    await store.write('SP-3-2026', 'old', DateTime.utc(2026, 6));
    await store.write('SP-3-2026', 'new', DateTime.utc(2026, 9));
    final r = await store.read('SP-3-2026');
    expect(r!.value, 'new');
    expect(r.expiresAt, DateTime.utc(2026, 9));
  });

  test('keys diferentes não interferem', () async {
    await store.write('SC-1-2026', 'A', DateTime.utc(2026, 6));
    await store.write('SP-1-2026', 'B', DateTime.utc(2026, 6));
    expect((await store.read('SC-1-2026'))!.value, 'A');
    expect((await store.read('SP-1-2026'))!.value, 'B');
    expect(await store.read('RJ-1-2026'), isNull);
  });

  test('expiresAt normalizado para UTC', () async {
    final exp = DateTime.utc(2026, 8, 1, 12, 30);
    await store.write('DF-0-2026', 'v', exp);
    final r = await store.read('DF-0-2026');
    expect(r!.expiresAt.isUtc, isTrue);
  });
}

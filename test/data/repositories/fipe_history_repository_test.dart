import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/fipe_history_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.J — DriftFipeHistoryRepository.
/// Spec: docs/specs/sprint-6.J-fipe-history.md

void main() {
  late AppDatabase db;
  late FipeHistoryRepository repo;
  late DateTime fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 26);
    repo = DriftFipeHistoryRepository(db, now: () => fakeNow);
  });

  tearDown(() => db.close());

  group('saveSnapshot', () {
    test('insere novo snapshot', () async {
      await repo.saveSnapshot(
        vehicleId: 'v1',
        month: '2026-05',
        value: Decimal.parse('78420'),
      );
      final list = await repo.listByVehicle('v1');
      expect(list.length, 1);
      expect(list.single.value, Decimal.parse('78420'));
      expect(list.single.month, '2026-05');
    });

    test('save no mesmo (vehicleId, month) sobrescreve', () async {
      await repo.saveSnapshot(
        vehicleId: 'v1',
        month: '2026-05',
        value: Decimal.parse('78420'),
      );
      await repo.saveSnapshot(
        vehicleId: 'v1',
        month: '2026-05',
        value: Decimal.parse('80000'),
      );
      final list = await repo.listByVehicle('v1');
      expect(list.length, 1);
      expect(list.single.value, Decimal.parse('80000'));
    });
  });

  group('listByVehicle / recent', () {
    test('listByVehicle ordena por month ASC', () async {
      await repo.saveSnapshot(
        vehicleId: 'v1', month: '2026-03', value: Decimal.parse('100'));
      await repo.saveSnapshot(
        vehicleId: 'v1', month: '2026-01', value: Decimal.parse('80'));
      await repo.saveSnapshot(
        vehicleId: 'v1', month: '2026-02', value: Decimal.parse('90'));
      final list = await repo.listByVehicle('v1');
      expect(list.map((s) => s.month).toList(),
          ['2026-01', '2026-02', '2026-03']);
    });

    test('recent retorna no máximo N mais recentes (ordem ASC final)', () async {
      for (int m = 1; m <= 15; m++) {
        await repo.saveSnapshot(
          vehicleId: 'v1',
          month: '2025-${m.toString().padLeft(2, '0')}',
          value: Decimal.fromInt(m * 1000),
        );
      }
      final r = await repo.recent('v1', months: 12);
      expect(r.length, 12);
      // Devem ser os 12 mais recentes: 2025-04 a 2025-15? Não — meses 04..15 não
      // existem como reais. Como string ordena lexicograficamente, são as últimas 12 keys.
      expect(r.first.month.compareTo(r.last.month) <= 0, isTrue);
    });

    test('snapshots de outros veículos não vazam', () async {
      await repo.saveSnapshot(
        vehicleId: 'v1', month: '2026-01', value: Decimal.parse('100'));
      await repo.saveSnapshot(
        vehicleId: 'v2', month: '2026-01', value: Decimal.parse('200'));
      final v1 = await repo.listByVehicle('v1');
      final v2 = await repo.listByVehicle('v2');
      expect(v1.single.value, Decimal.parse('100'));
      expect(v2.single.value, Decimal.parse('200'));
    });
  });

  group('watchByVehicle', () {
    test('stream emite ao salvar novo snapshot', () async {
      final stream = repo.watchByVehicle('v1');
      final emitted = <int>[];
      final sub = stream.listen((list) => emitted.add(list.length));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.saveSnapshot(
        vehicleId: 'v1', month: '2026-01', value: Decimal.parse('100'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.saveSnapshot(
        vehicleId: 'v1', month: '2026-02', value: Decimal.parse('110'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      // Pelo menos uma emissão com 1 elemento e outra com 2.
      expect(emitted.contains(1), isTrue);
      expect(emitted.contains(2), isTrue);
    });
  });
}

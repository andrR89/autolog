import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.AA — Repositório de configurações do usuário (theme mode).
void main() {
  late AppDatabase db;
  late UserSettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftUserSettingsRepository(db);
  });

  tearDown(() => db.close());

  group('getThemeMode', () {
    test('retorna system e cria row se não existir', () async {
      final mode = await repo.getThemeMode('user-1');
      expect(mode, ThemeModeEnum.system);

      // Deve ter criado um registro no banco.
      final rows = await db.select(db.userSettings).get();
      expect(rows.length, 1);
      expect(rows.first.userId, 'user-1');
      expect(rows.first.themePref, 'system');
    });

    test('retorna o valor persistido quando já existe', () async {
      await repo.setThemeMode('user-1', ThemeModeEnum.dark);
      final mode = await repo.getThemeMode('user-1');
      expect(mode, ThemeModeEnum.dark);
    });

    test('isolamento por userId', () async {
      await repo.setThemeMode('user-1', ThemeModeEnum.light);
      await repo.setThemeMode('user-2', ThemeModeEnum.dark);

      expect(await repo.getThemeMode('user-1'), ThemeModeEnum.light);
      expect(await repo.getThemeMode('user-2'), ThemeModeEnum.dark);
    });
  });

  group('setThemeMode', () {
    test('persiste light', () async {
      await repo.setThemeMode('user-1', ThemeModeEnum.light);
      expect(await repo.getThemeMode('user-1'), ThemeModeEnum.light);
    });

    test('persiste dark', () async {
      await repo.setThemeMode('user-1', ThemeModeEnum.dark);
      expect(await repo.getThemeMode('user-1'), ThemeModeEnum.dark);
    });

    test('persiste system', () async {
      await repo.setThemeMode('user-1', ThemeModeEnum.dark);
      await repo.setThemeMode('user-1', ThemeModeEnum.system);
      expect(await repo.getThemeMode('user-1'), ThemeModeEnum.system);
    });

    test('sobrescreve valor anterior via upsert', () async {
      await repo.setThemeMode('user-1', ThemeModeEnum.light);
      await repo.setThemeMode('user-1', ThemeModeEnum.dark);
      expect(await repo.getThemeMode('user-1'), ThemeModeEnum.dark);

      // Só deve existir uma row.
      final rows = await db.select(db.userSettings).get();
      expect(rows.length, 1);
    });
  });

  group('watchThemeMode', () {
    test('emite system enquanto não há registro', () async {
      final values = <ThemeModeEnum>[];
      final sub = repo.watchThemeMode('user-1').listen(values.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(values, isNotEmpty);
      expect(values.first, ThemeModeEnum.system);
    });

    test('emite novo valor ao mudar', () async {
      final values = <ThemeModeEnum>[];
      final sub = repo.watchThemeMode('user-1').listen(values.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.setThemeMode('user-1', ThemeModeEnum.dark);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.setThemeMode('user-1', ThemeModeEnum.light);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await sub.cancel();

      expect(values.length, greaterThanOrEqualTo(3));
      expect(values.first, ThemeModeEnum.system);
      expect(values.last, ThemeModeEnum.light);
    });
  });
}

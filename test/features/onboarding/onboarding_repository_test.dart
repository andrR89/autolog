import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testes de repositório para onboardingSeen (Sprint 6.GG).
void main() {
  late AppDatabase db;
  late UserSettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftUserSettingsRepository(db);
  });

  tearDown(() => db.close());

  group('getOnboardingSeen', () {
    test('retorna false para usuário novo (sem registro)', () async {
      final seen = await repo.getOnboardingSeen('user-1');
      expect(seen, isFalse);
    });

    test('retorna false antes de chamar setOnboardingSeen', () async {
      // Cria um registro via outro setter (simula usuário que já usou o app).
      await repo.setThemeMode('user-1', ThemeModeEnum.dark);

      final seen = await repo.getOnboardingSeen('user-1');
      expect(seen, isFalse);
    });
  });

  group('setOnboardingSeen', () {
    test('marca como visto — getOnboardingSeen retorna true', () async {
      await repo.setOnboardingSeen('user-1');
      expect(await repo.getOnboardingSeen('user-1'), isTrue);
    });

    test('idempotente — chamar duas vezes mantém true', () async {
      await repo.setOnboardingSeen('user-1');
      await repo.setOnboardingSeen('user-1');
      expect(await repo.getOnboardingSeen('user-1'), isTrue);
    });

    test('não afeta outros campos — theme ainda existe', () async {
      await repo.setThemeMode('user-1', ThemeModeEnum.dark);
      await repo.setOnboardingSeen('user-1');

      expect(await repo.getThemeMode('user-1'), ThemeModeEnum.dark);
      expect(await repo.getOnboardingSeen('user-1'), isTrue);
    });

    test('isolamento por userId', () async {
      await repo.setOnboardingSeen('user-1');

      expect(await repo.getOnboardingSeen('user-1'), isTrue);
      expect(await repo.getOnboardingSeen('user-2'), isFalse);
    });
  });
}

import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.W.4 — Repositório de prefs de notificação (get/set/watch).

void main() {
  late AppDatabase db;
  late DriftUserSettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftUserSettingsRepository(db);
  });

  tearDown(() => db.close());

  group('getNotifPrefs', () {
    test('retorna defaults (todas true) e cria row se não existir', () async {
      final prefs = await repo.getNotifPrefs('user-1');
      expect(prefs.consumptionDrop, isTrue);
      expect(prefs.cnh, isTrue);
      expect(prefs.fiscal, isTrue);
      expect(prefs.recapReady, isTrue);

      // Deve ter criado um registro no banco.
      final rows = await db.select(db.userSettings).get();
      expect(rows.length, 1);
      expect(rows.first.userId, 'user-1');
    });

    test('retorna prefs persistidas quando já existem', () async {
      await repo.setNotifPref('user-1', 'cnh', false);
      final prefs = await repo.getNotifPrefs('user-1');
      expect(prefs.cnh, isFalse);
      expect(prefs.consumptionDrop, isTrue); // os outros permanecem
    });

    test('isolamento por userId', () async {
      await repo.setNotifPref('user-1', 'fiscal', false);
      await repo.setNotifPref('user-2', 'consumption_drop', false);

      final prefs1 = await repo.getNotifPrefs('user-1');
      final prefs2 = await repo.getNotifPrefs('user-2');

      expect(prefs1.fiscal, isFalse);
      expect(prefs1.consumptionDrop, isTrue);
      expect(prefs2.consumptionDrop, isFalse);
      expect(prefs2.fiscal, isTrue);
    });
  });

  group('setNotifPref', () {
    test('persiste consumption_drop = false', () async {
      await repo.setNotifPref('user-1', 'consumption_drop', false);
      final prefs = await repo.getNotifPrefs('user-1');
      expect(prefs.consumptionDrop, isFalse);
      expect(prefs.cnh, isTrue);
      expect(prefs.fiscal, isTrue);
      expect(prefs.recapReady, isTrue);
    });

    test('persiste cnh = false', () async {
      await repo.setNotifPref('user-1', 'cnh', false);
      final prefs = await repo.getNotifPrefs('user-1');
      expect(prefs.cnh, isFalse);
      expect(prefs.consumptionDrop, isTrue);
    });

    test('persiste fiscal = false', () async {
      await repo.setNotifPref('user-1', 'fiscal', false);
      final prefs = await repo.getNotifPrefs('user-1');
      expect(prefs.fiscal, isFalse);
      expect(prefs.recapReady, isTrue);
    });

    test('persiste recap_ready = false', () async {
      await repo.setNotifPref('user-1', 'recap_ready', false);
      final prefs = await repo.getNotifPrefs('user-1');
      expect(prefs.recapReady, isFalse);
      expect(prefs.fiscal, isTrue);
    });

    test('NÃO sobrescreve themePref ao mudar notif', () async {
      await repo.setThemeMode('user-1', ThemeModeEnum.dark);
      await repo.setNotifPref('user-1', 'cnh', false);

      final theme = await repo.getThemeMode('user-1');
      expect(theme, ThemeModeEnum.dark); // themePref intacto
    });

    test('NÃO sobrescreve outras prefs de notif ao mudar uma', () async {
      await repo.setNotifPref('user-1', 'fiscal', false);
      await repo.setNotifPref('user-1', 'cnh', false);

      final prefs = await repo.getNotifPrefs('user-1');
      expect(prefs.fiscal, isFalse); // fiscal ainda false
      expect(prefs.cnh, isFalse);
      expect(prefs.consumptionDrop, isTrue);
      expect(prefs.recapReady, isTrue);
    });

    test('pode re-ligar uma pref previamente desligada', () async {
      await repo.setNotifPref('user-1', 'cnh', false);
      await repo.setNotifPref('user-1', 'cnh', true);
      final prefs = await repo.getNotifPrefs('user-1');
      expect(prefs.cnh, isTrue);
    });

    test('sobrescreve via upsert — só 1 row no banco', () async {
      await repo.setNotifPref('user-1', 'cnh', false);
      await repo.setNotifPref('user-1', 'fiscal', false);
      final rows = await db.select(db.userSettings).get();
      expect(rows.length, 1);
    });
  });

  group('watchNotifPrefs', () {
    test('emite defaults enquanto não há registro', () async {
      final values = <NotificationPreferences>[];
      final sub = repo.watchNotifPrefs('user-1').listen(values.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(values, isNotEmpty);
      expect(values.first.consumptionDrop, isTrue);
      expect(values.first.cnh, isTrue);
    });

    test('emite novo valor ao mudar uma pref', () async {
      final values = <NotificationPreferences>[];
      final sub = repo.watchNotifPrefs('user-1').listen(values.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.setNotifPref('user-1', 'cnh', false);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.setNotifPref('user-1', 'cnh', true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await sub.cancel();

      expect(values.length, greaterThanOrEqualTo(3));
      // Após primeiro setNotifPref, cnh = false.
      final afterFirst = values.firstWhere((p) => !p.cnh, orElse: () =>
          const NotificationPreferences(cnh: true));
      expect(afterFirst.cnh, isFalse);
      // Último valor: cnh = true novamente.
      expect(values.last.cnh, isTrue);
    });
  });

  group('NotificationPreferences.enabled', () {
    test('enabled retorna false para categoria desligada', () {
      const prefs = NotificationPreferences(cnh: false);
      expect(prefs.enabled('cnh'), isFalse);
      expect(prefs.enabled('fiscal'), isTrue);
    });

    test('enabled retorna true para categoria desconhecida', () {
      const prefs = NotificationPreferences();
      expect(prefs.enabled('unknown_category'), isTrue);
    });

    test('enabled mapeia todas as categorias corretamente', () {
      const prefs = NotificationPreferences(
        consumptionDrop: false,
        cnh: false,
        fiscal: false,
        recapReady: false,
      );
      expect(prefs.enabled('consumption_drop'), isFalse);
      expect(prefs.enabled('cnh'), isFalse);
      expect(prefs.enabled('fiscal'), isFalse);
      expect(prefs.enabled('recap_ready'), isFalse);
    });
  });
}

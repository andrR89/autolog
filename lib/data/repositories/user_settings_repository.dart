import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Helpers: string ↔ enum
// ---------------------------------------------------------------------------

ThemeModeEnum _fromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeModeEnum.light;
    case 'dark':
      return ThemeModeEnum.dark;
    case 'system':
    default:
      return ThemeModeEnum.system;
  }
}

String _toString(ThemeModeEnum mode) {
  switch (mode) {
    case ThemeModeEnum.light:
      return 'light';
    case ThemeModeEnum.dark:
      return 'dark';
    case ThemeModeEnum.system:
      return 'system';
  }
}

// ---------------------------------------------------------------------------
// DriftUserSettingsRepository
// ---------------------------------------------------------------------------

class DriftUserSettingsRepository implements UserSettingsRepository {
  DriftUserSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ThemeModeEnum> getThemeMode(String userId) async {
    final row = await (_db.select(_db.userSettings)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();

    if (row == null) {
      // Cria registro com default 'system'.
      await _db.into(_db.userSettings).insertOnConflictUpdate(
            UserSettingsCompanion.insert(
              userId: userId,
              themePref: const Value('system'),
            ),
          );
      return ThemeModeEnum.system;
    }

    return _fromString(row.themePref);
  }

  @override
  Future<void> setThemeMode(String userId, ThemeModeEnum mode) async {
    await _db.into(_db.userSettings).insertOnConflictUpdate(
          UserSettingsCompanion.insert(
            userId: userId,
            themePref: Value(_toString(mode)),
          ),
        );
  }

  @override
  Stream<ThemeModeEnum> watchThemeMode(String userId) {
    return (_db.select(_db.userSettings)
          ..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull()
        .map((row) => _fromString(row?.themePref));
  }

  // ---------------------------------------------------------------------------
  // NotificationPreferences
  // ---------------------------------------------------------------------------

  /// Garante que o registro do userId existe e retorna o row.
  Future<UserSettingsRow> _getOrCreate(String userId) async {
    final row = await (_db.select(_db.userSettings)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
    if (row != null) return row;

    // Cria com todos os defaults.
    await _db.into(_db.userSettings).insertOnConflictUpdate(
          UserSettingsCompanion.insert(userId: userId),
        );
    return (_db.select(_db.userSettings)
          ..where((t) => t.userId.equals(userId)))
        .getSingle();
  }

  NotificationPreferences _rowToPrefs(UserSettingsRow row) =>
      NotificationPreferences(
        consumptionDrop: row.notifConsumptionDrop,
        cnh: row.notifCnh,
        fiscal: row.notifFiscal,
        recapReady: row.notifRecapReady,
      );

  @override
  Future<NotificationPreferences> getNotifPrefs(String userId) async {
    final row = await _getOrCreate(userId);
    return _rowToPrefs(row);
  }

  @override
  Future<void> setNotifPref(
    String userId,
    String category,
    bool enabled,
  ) async {
    // Lê row atual (cria se não existir) pra não sobrescrever os outros campos.
    final row = await _getOrCreate(userId);

    final companion = UserSettingsCompanion.insert(
      userId: userId,
      themePref: Value(row.themePref),
      notifConsumptionDrop: Value(
        category == 'consumption_drop' ? enabled : row.notifConsumptionDrop,
      ),
      notifCnh: Value(
        category == 'cnh' ? enabled : row.notifCnh,
      ),
      notifFiscal: Value(
        category == 'fiscal' ? enabled : row.notifFiscal,
      ),
      notifRecapReady: Value(
        category == 'recap_ready' ? enabled : row.notifRecapReady,
      ),
    );

    await _db.into(_db.userSettings).insertOnConflictUpdate(companion);
  }

  @override
  Stream<NotificationPreferences> watchNotifPrefs(String userId) {
    return (_db.select(_db.userSettings)
          ..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull()
        .map(
          (row) => row != null
              ? _rowToPrefs(row)
              : const NotificationPreferences(),
        );
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftUserSettingsRepository(db);
});

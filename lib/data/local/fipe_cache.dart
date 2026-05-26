import 'package:autolog/data/local/database.dart';

// Re-export FipeCacheRow so consumers can import from this file directly.
export 'package:autolog/data/local/database.dart' show FipeCacheRow;

// ---------------------------------------------------------------------------
// Contrato
// ---------------------------------------------------------------------------

abstract class FipeCacheStore {
  Future<FipeCacheRow?> read(String key);
  Future<void> write(String key, String value, DateTime expiresAt);
}

// ---------------------------------------------------------------------------
// Implementação Drift
// ---------------------------------------------------------------------------

class DriftFipeCacheStore implements FipeCacheStore {
  DriftFipeCacheStore(this._db);

  final AppDatabase _db;

  @override
  Future<FipeCacheRow?> read(String key) async {
    final row = await (_db.select(_db.fipeCache)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    // Drift armazena DateTime como unix timestamp e lê como hora local.
    // Normaliza para UTC para garantir consistência nas comparações.
    return row.copyWith(expiresAt: row.expiresAt.toUtc());
  }

  @override
  Future<void> write(String key, String value, DateTime expiresAt) {
    return _db.into(_db.fipeCache).insertOnConflictUpdate(
          FipeCacheCompanion.insert(
            key: key,
            value: value,
            expiresAt: expiresAt,
          ),
        );
  }
}

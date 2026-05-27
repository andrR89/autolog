import 'package:autolog/data/local/database.dart';

// Re-export FiscalLookupCacheRow so consumers can import from this file directly.
export 'package:autolog/data/local/database.dart' show FiscalLookupCacheRow;

// ---------------------------------------------------------------------------
// Contrato
// ---------------------------------------------------------------------------

abstract class FiscalLookupCache {
  Future<FiscalLookupCacheRow?> read(String key);
  Future<void> write(String key, String value, DateTime expiresAt);
}

// ---------------------------------------------------------------------------
// Implementação Drift
// ---------------------------------------------------------------------------

class DriftFiscalLookupCache implements FiscalLookupCache {
  DriftFiscalLookupCache(this._db);

  final AppDatabase _db;

  @override
  Future<FiscalLookupCacheRow?> read(String key) async {
    final row = await (_db.select(_db.fiscalLookupCache)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    // Normaliza para UTC para garantir consistência nas comparações.
    return row.copyWith(expiresAt: row.expiresAt.toUtc());
  }

  @override
  Future<void> write(String key, String value, DateTime expiresAt) {
    return _db.into(_db.fiscalLookupCache).insertOnConflictUpdate(
          FiscalLookupCacheCompanion.insert(
            cacheKey: key,
            value: value,
            expiresAt: expiresAt,
          ),
        );
  }
}

import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_fine_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/repositories/fine_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// DriftFineRepository
// ---------------------------------------------------------------------------

DateTime _utcNow() => DateTime.now().toUtc();

class DriftFineRepository implements FineRepository {
  DriftFineRepository(this._db, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  // -------------------------------------------------------------------------
  // create
  // -------------------------------------------------------------------------

  @override
  Future<void> create(Fine fine) async {
    final timestamp = _now();
    final companion = fineToCompanion(
      fine.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
        deletedAt: null,
      ),
    );
    await _db.into(_db.fines).insert(companion);
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  @override
  Future<void> update(Fine fine) async {
    final existing = await (_db.select(
      _db.fines,
    )..where((t) => t.id.equals(fine.id))).getSingleOrNull();

    if (existing == null) {
      throw StateError('Multa não encontrada: ${fine.id}');
    }

    final timestamp = _now();
    final companion = fineToCompanion(
      fine.copyWith(
        createdAt: existing.createdAt,
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
      ),
    );
    await (_db.update(_db.fines)..where((t) => t.id.equals(fine.id))).write(
      companion,
    );
  }

  // -------------------------------------------------------------------------
  // softDelete
  // -------------------------------------------------------------------------

  @override
  Future<void> softDelete(String id) async {
    final existing = await (_db.select(
      _db.fines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing == null) return;
    if (existing.deletedAt != null) return;

    final timestamp = _now();
    await (_db.update(_db.fines)..where((t) => t.id.equals(id))).write(
      FinesCompanion(
        deletedAt: Value(timestamp),
        updatedAt: Value(timestamp),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // listByVehicle
  // -------------------------------------------------------------------------

  @override
  Future<List<Fine>> listByVehicle(String vehicleId) async {
    final rows = await (_db.select(_db.fines)
          ..where(
            (t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]))
        .get();
    return rows.map(fineToDomain).toList();
  }

  // -------------------------------------------------------------------------
  // watchUnpaid
  // -------------------------------------------------------------------------

  @override
  Stream<List<Fine>> watchUnpaid(String vehicleId) {
    return (_db.select(_db.fines)
          ..where(
            (t) =>
                t.vehicleId.equals(vehicleId) &
                t.deletedAt.isNull() &
                t.paid.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]))
        .watch()
        .map((rows) => rows.map(fineToDomain).toList());
  }

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  @override
  Future<Fine?> getById(String id) async {
    final row = await (_db.select(
      _db.fines,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : fineToDomain(row);
  }

  // -------------------------------------------------------------------------
  // togglePaid
  // -------------------------------------------------------------------------

  @override
  Future<void> togglePaid(String id) async {
    final existing = await (_db.select(
      _db.fines,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

    if (existing == null) return;

    final timestamp = _now();
    await (_db.update(_db.fines)..where((t) => t.id.equals(id))).write(
      FinesCompanion(
        paid: Value(!existing.paid),
        updatedAt: Value(timestamp),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

final fineRepositoryProvider = Provider<FineRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFineRepository(db);
});

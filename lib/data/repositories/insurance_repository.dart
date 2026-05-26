import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_insurance_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/repositories/insurance_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// DriftInsuranceRepository
// ---------------------------------------------------------------------------

DateTime _utcNow() => DateTime.now().toUtc();

class DriftInsuranceRepository implements InsuranceRepository {
  DriftInsuranceRepository(this._db, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  // -------------------------------------------------------------------------
  // create
  // -------------------------------------------------------------------------

  @override
  Future<void> create(Insurance insurance) async {
    final timestamp = _now();
    final companion = insuranceToCompanion(
      insurance.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
        deletedAt: null,
      ),
    );
    await _db.into(_db.insurances).insert(companion);
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  @override
  Future<void> update(Insurance insurance) async {
    final existing = await (_db.select(
      _db.insurances,
    )..where((t) => t.id.equals(insurance.id))).getSingleOrNull();

    if (existing == null) {
      throw StateError('Apólice não encontrada: ${insurance.id}');
    }

    final timestamp = _now();
    final companion = insuranceToCompanion(
      insurance.copyWith(
        createdAt: existing.createdAt,
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
      ),
    );
    await (_db.update(
      _db.insurances,
    )..where((t) => t.id.equals(insurance.id))).write(companion);
  }

  // -------------------------------------------------------------------------
  // softDelete
  // -------------------------------------------------------------------------

  @override
  Future<void> softDelete(String id) async {
    final existing = await (_db.select(
      _db.insurances,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing == null) return;
    if (existing.deletedAt != null) return;

    final timestamp = _now();
    await (_db.update(_db.insurances)..where((t) => t.id.equals(id))).write(
      InsurancesCompanion(
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
  Future<List<Insurance>> listByVehicle(String vehicleId) async {
    final rows = await (_db.select(_db.insurances)
          ..where(
            (t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.endsAt)]))
        .get();
    return rows.map(insuranceToDomain).toList();
  }

  // -------------------------------------------------------------------------
  // watchActive
  // -------------------------------------------------------------------------

  @override
  Stream<List<Insurance>> watchActive(String vehicleId, DateTime now) {
    // Drift não tem comparação nativa de DateTime com variável — filtra no Dart.
    return (_db.select(_db.insurances)
          ..where(
            (t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.endsAt)]))
        .watch()
        .map(
          (rows) => rows
              .where((row) => row.endsAt.toUtc().isAfter(now))
              .map(insuranceToDomain)
              .toList(),
        );
  }

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  @override
  Future<Insurance?> getById(String id) async {
    final row = await (_db.select(
      _db.insurances,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : insuranceToDomain(row);
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

final insuranceRepositoryProvider = Provider<InsuranceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftInsuranceRepository(db);
});

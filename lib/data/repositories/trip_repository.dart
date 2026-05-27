import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_trip_mapper.dart';
import 'package:autolog/domain/models/trip.dart';
import 'package:autolog/domain/repositories/trip_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// DriftTripRepository
// ---------------------------------------------------------------------------

/// Implementação local de [TripRepository] sobre Drift.
///
/// Recebe [AppDatabase] e um relógio opcional [now] para facilitar testes
/// determinísticos. Trip é local-only no MVP (Regra de Ouro: offline-first).
DateTime _utcNow() => DateTime.now().toUtc();

class DriftTripRepository implements TripRepository {
  DriftTripRepository(this._db, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  // -------------------------------------------------------------------------
  // create
  // -------------------------------------------------------------------------

  @override
  Future<Trip> create(Trip trip) async {
    final timestamp = _now();
    final companion = tripToCompanion(
      trip.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        deletedAt: null,
      ),
    );

    await _db.into(_db.trips).insert(companion);

    final row = await (_db.select(
      _db.trips,
    )..where((t) => t.id.equals(trip.id))).getSingle();

    return tripToDomain(row);
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  @override
  Future<Trip> update(Trip trip) async {
    final existing = await (_db.select(
      _db.trips,
    )..where((t) => t.id.equals(trip.id))).getSingleOrNull();

    if (existing == null) {
      throw StateError('Viagem não encontrada: ${trip.id}');
    }
    if (existing.deletedAt != null) {
      throw StateError(
        'Viagem soft-deletada não pode ser atualizada: ${trip.id}',
      );
    }

    final timestamp = _now();
    final companion = tripToCompanion(
      trip.copyWith(
        createdAt: existing.createdAt,
        updatedAt: timestamp,
      ),
    );

    await (_db.update(
      _db.trips,
    )..where((t) => t.id.equals(trip.id))).write(companion);

    final row = await (_db.select(
      _db.trips,
    )..where((t) => t.id.equals(trip.id))).getSingle();

    return tripToDomain(row);
  }

  // -------------------------------------------------------------------------
  // softDelete
  // -------------------------------------------------------------------------

  @override
  Future<void> softDelete(String id) async {
    final existing = await (_db.select(
      _db.trips,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing == null) return;
    if (existing.deletedAt != null) return;

    final timestamp = _now();
    await (_db.update(_db.trips)..where((t) => t.id.equals(id))).write(
      TripsCompanion(
        deletedAt: Value(timestamp),
        updatedAt: Value(timestamp),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  @override
  Future<Trip?> getById(String id) async {
    final row = await (_db.select(
      _db.trips,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

    return row == null ? null : tripToDomain(row);
  }

  // -------------------------------------------------------------------------
  // listByVehicle
  // -------------------------------------------------------------------------

  @override
  Future<List<Trip>> listByVehicle(String vehicleId) async {
    final rows =
        await (_db.select(_db.trips)
              ..where(
                (t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
            .get();

    return rows.map(tripToDomain).toList();
  }

  // -------------------------------------------------------------------------
  // watchByVehicle
  // -------------------------------------------------------------------------

  @override
  Stream<List<Trip>> watchByVehicle(String vehicleId) {
    return (_db.select(_db.trips)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .watch()
        .map((rows) => rows.map(tripToDomain).toList());
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Expõe [DriftTripRepository] para o app.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftTripRepository(db);
});

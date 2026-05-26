import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/vehicle_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Mapper — funções puras, sem estado
// ---------------------------------------------------------------------------

Vehicle _toDomain(VehicleRow row) {
  return Vehicle(
    id: row.id,
    userId: row.userId,
    nickname: row.nickname,
    make: row.make,
    model: row.model,
    year: row.year,
    uf: row.uf,
    color: row.color,
    type: row.type,
    engineDisplacementCc: row.engineDisplacementCc,
    tankCapacityL: row.tankCapacityL,
    horsepower: row.horsepower,
    fipeCode: row.fipeCode,
    fipeValue: row.fipeValue,
    fipeReferenceMonth: row.fipeReferenceMonth,
    plate: row.plate,
    renavam: row.renavam,
    chassi: row.chassi,
    fuelType: row.fuelType,
    initialOdometer: row.initialOdometer,
    // Drift armazena DateTime como unix timestamp e lê como hora local.
    // Normaliza para UTC para garantir consistência nas comparações.
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    syncStatus: row.syncStatus,
  );
}

VehiclesCompanion _toCompanion(Vehicle v) {
  return VehiclesCompanion(
    id: Value(v.id),
    userId: Value(v.userId),
    nickname: Value(v.nickname),
    make: Value(v.make),
    model: Value(v.model),
    year: Value(v.year),
    uf: Value(v.uf),
    color: Value(v.color),
    type: Value(v.type),
    engineDisplacementCc: Value(v.engineDisplacementCc),
    tankCapacityL: Value(v.tankCapacityL),
    horsepower: Value(v.horsepower),
    fipeCode: Value(v.fipeCode),
    fipeValue: Value(v.fipeValue),
    fipeReferenceMonth: Value(v.fipeReferenceMonth),
    plate: Value(v.plate),
    renavam: Value(v.renavam),
    chassi: Value(v.chassi),
    fuelType: Value(v.fuelType),
    initialOdometer: Value(v.initialOdometer),
    createdAt: Value(v.createdAt),
    updatedAt: Value(v.updatedAt),
    deletedAt: Value(v.deletedAt),
    syncStatus: Value(v.syncStatus),
  );
}

// ---------------------------------------------------------------------------
// DriftVehicleRepository
// ---------------------------------------------------------------------------

/// Implementação local de [VehicleRepository] sobre Drift.
///
/// Recebe [AppDatabase] e um relógio opcional [now] para facilitar testes
/// determinísticos. Toda mutação grava localmente, marca sync_status=pending
/// e bumpa updated_at (Regra de Ouro: offline-first).
DateTime _utcNow() => DateTime.now().toUtc();

class DriftVehicleRepository implements VehicleRepository {
  DriftVehicleRepository(this._db, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  // -------------------------------------------------------------------------
  // create
  // -------------------------------------------------------------------------

  @override
  Future<Vehicle> create(Vehicle vehicle) async {
    final timestamp = _now();
    final companion = _toCompanion(
      vehicle.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
        deletedAt: null,
      ),
    );

    await _db.into(_db.vehicles).insert(companion);

    final row = await (_db.select(
      _db.vehicles,
    )..where((t) => t.id.equals(vehicle.id))).getSingle();

    return _toDomain(row);
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  @override
  Future<Vehicle> update(Vehicle vehicle) async {
    // Busca a linha incluindo soft-deleted para distinguir "não existe" de "deletado".
    final existing = await (_db.select(
      _db.vehicles,
    )..where((t) => t.id.equals(vehicle.id))).getSingleOrNull();

    if (existing == null) {
      throw StateError('Veículo não encontrado: ${vehicle.id}');
    }
    if (existing.deletedAt != null) {
      throw StateError(
        'Veículo soft-deletado não pode ser atualizado: ${vehicle.id}',
      );
    }

    final timestamp = _now();
    final companion = _toCompanion(
      vehicle.copyWith(
        // Preserva createdAt original.
        createdAt: existing.createdAt,
        // Repositório controla updated_at.
        updatedAt: timestamp,
        // Toda escrita local vira pending.
        syncStatus: SyncStatus.pending,
      ),
    );

    await (_db.update(
      _db.vehicles,
    )..where((t) => t.id.equals(vehicle.id))).write(companion);

    final row = await (_db.select(
      _db.vehicles,
    )..where((t) => t.id.equals(vehicle.id))).getSingle();

    return _toDomain(row);
  }

  // -------------------------------------------------------------------------
  // softDelete
  // -------------------------------------------------------------------------

  @override
  Future<void> softDelete(String id) async {
    // Idempotente: se já deletado, preserva o deleted_at original.
    final existing = await (_db.select(
      _db.vehicles,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing == null) return; // Não existe — nada a fazer.
    if (existing.deletedAt != null) return; // Já deletado — idempotente.

    final timestamp = _now();
    await (_db.update(_db.vehicles)..where((t) => t.id.equals(id))).write(
      VehiclesCompanion(
        deletedAt: Value(timestamp),
        updatedAt: Value(timestamp),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  @override
  Future<Vehicle?> getById(String id) async {
    final row = await (_db.select(
      _db.vehicles,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  // -------------------------------------------------------------------------
  // listByUser
  // -------------------------------------------------------------------------

  @override
  Future<List<Vehicle>> listByUser(String userId) async {
    final rows =
        await (_db.select(_db.vehicles)
              ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  // -------------------------------------------------------------------------
  // watchByUser
  // -------------------------------------------------------------------------

  @override
  Stream<List<Vehicle>> watchByUser(String userId) {
    return (_db.select(_db.vehicles)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Expõe [DriftVehicleRepository] para o app.
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftVehicleRepository(db);
});

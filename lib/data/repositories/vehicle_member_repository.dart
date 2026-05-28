import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/vehicle_member.dart';
import 'package:autolog/domain/repositories/vehicle_member_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Mapper privado
// ---------------------------------------------------------------------------

VehicleMember _toDomain(VehicleMemberRow row) {
  return VehicleMember(
    vehicleId: row.vehicleId,
    userId: row.userId,
    role: row.role,
    createdAt: row.createdAt.toUtc(),
  );
}

VehicleMembersCompanion _toCompanion(VehicleMember m) {
  return VehicleMembersCompanion(
    vehicleId: Value(m.vehicleId),
    userId: Value(m.userId),
    role: Value(m.role),
    createdAt: Value(m.createdAt),
  );
}

// ---------------------------------------------------------------------------
// DriftVehicleMemberRepository
// ---------------------------------------------------------------------------

/// Implementação local de [VehicleMemberRepository] sobre Drift.
///
/// vehicle_members NÃO usa soft delete — remoção é DELETE direto.
/// Sem sync no MVP (TODO pós-MVP).
class DriftVehicleMemberRepository implements VehicleMemberRepository {
  DriftVehicleMemberRepository(this._db);

  final AppDatabase _db;

  // -------------------------------------------------------------------------
  // listByVehicle
  // -------------------------------------------------------------------------

  @override
  Future<List<VehicleMember>> listByVehicle(String vehicleId) async {
    final rows =
        await (_db.select(_db.vehicleMembers)
              ..where((t) => t.vehicleId.equals(vehicleId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  // -------------------------------------------------------------------------
  // watchByVehicle
  // -------------------------------------------------------------------------

  @override
  Stream<List<VehicleMember>> watchByVehicle(String vehicleId) {
    return (_db.select(_db.vehicleMembers)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  // -------------------------------------------------------------------------
  // upsert
  // -------------------------------------------------------------------------

  @override
  Future<void> upsert(VehicleMember member) async {
    await _db.into(_db.vehicleMembers).insertOnConflictUpdate(_toCompanion(member));
  }

  // -------------------------------------------------------------------------
  // remove
  // -------------------------------------------------------------------------

  @override
  Future<void> remove(String vehicleId, String userId) async {
    await (_db.delete(_db.vehicleMembers)
          ..where(
            (t) => t.vehicleId.equals(vehicleId) & t.userId.equals(userId),
          ))
        .go();
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Expõe [DriftVehicleMemberRepository] para o app.
final vehicleMemberRepositoryProvider = Provider<VehicleMemberRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftVehicleMemberRepository(db);
});

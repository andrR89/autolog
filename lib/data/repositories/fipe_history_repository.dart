import 'package:autolog/data/local/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Value object que representa um snapshot do valor FIPE de um veículo.
class FipeSnapshot {
  const FipeSnapshot({required this.month, required this.value});

  /// Mês no formato "YYYY-MM".
  final String month;
  final Decimal value;
}

abstract class FipeHistoryRepository {
  /// Upsert idempotente — PK composta (vehicleId, month) garante que salvar
  /// o mesmo mês duas vezes sobrescreve o valor anterior.
  Future<void> saveSnapshot({
    required String vehicleId,
    required String month,
    required Decimal value,
  });

  /// Lista todos os snapshots do veículo, ordenados por mês ASC.
  Future<List<FipeSnapshot>> listByVehicle(String vehicleId);

  /// Retorna os últimos [months] snapshots mais recentes (ordem ASC final).
  Future<List<FipeSnapshot>> recent(String vehicleId, {int months = 12});

  /// Stream reativo para widgets que exibem o histórico.
  Stream<List<FipeSnapshot>> watchByVehicle(String vehicleId);
}

class DriftFipeHistoryRepository implements FipeHistoryRepository {
  DriftFipeHistoryRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Future<void> saveSnapshot({
    required String vehicleId,
    required String month,
    required Decimal value,
  }) async {
    await _db.into(_db.fipeHistory).insertOnConflictUpdate(
      FipeHistoryCompanion.insert(
        vehicleId: vehicleId,
        month: month,
        value: value,
        capturedAt: _now(),
      ),
    );
  }

  @override
  Future<List<FipeSnapshot>> listByVehicle(String vehicleId) async {
    final q = _db.select(_db.fipeHistory)
      ..where((t) => t.vehicleId.equals(vehicleId))
      ..orderBy([(t) => OrderingTerm.asc(t.month)]);
    final rows = await q.get();
    return rows
        .map((r) => FipeSnapshot(month: r.month, value: r.value))
        .toList();
  }

  @override
  Future<List<FipeSnapshot>> recent(
    String vehicleId, {
    int months = 12,
  }) async {
    final q = _db.select(_db.fipeHistory)
      ..where((t) => t.vehicleId.equals(vehicleId))
      ..orderBy([(t) => OrderingTerm.desc(t.month)])
      ..limit(months);
    final rows = await q.get();
    final snaps =
        rows.map((r) => FipeSnapshot(month: r.month, value: r.value)).toList();
    // Reordena ASC após pegar os mais recentes com DESC
    snaps.sort((a, b) => a.month.compareTo(b.month));
    return snaps;
  }

  @override
  Stream<List<FipeSnapshot>> watchByVehicle(String vehicleId) {
    final q = _db.select(_db.fipeHistory)
      ..where((t) => t.vehicleId.equals(vehicleId))
      ..orderBy([(t) => OrderingTerm.asc(t.month)]);
    return q.watch().map(
      (rows) =>
          rows.map((r) => FipeSnapshot(month: r.month, value: r.value)).toList(),
    );
  }
}

/// Provider do repositório — usa o AppDatabase de produção.
final fipeHistoryRepositoryProvider = Provider<FipeHistoryRepository>((ref) {
  return DriftFipeHistoryRepository(ref.watch(appDatabaseProvider));
});

/// Stream provider familiar para widgets consumirem o histórico FIPE de um
/// veículo de forma reativa.
final fipeHistoryProvider =
    StreamProvider.family<List<FipeSnapshot>, String>((ref, vehicleId) {
      return ref.watch(fipeHistoryRepositoryProvider).watchByVehicle(vehicleId);
    });

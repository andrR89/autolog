import 'package:autolog/domain/models/trip.dart';

/// Interface de repositório de viagens — fala só na linguagem de domínio.
/// Implementação Drift: [DriftTripRepository] em lib/data/repositories/.
abstract class TripRepository {
  /// Cria uma viagem. Repositório define createdAt/updatedAt (UTC now).
  /// O caller fornece id (UUID) e demais campos.
  Future<Trip> create(Trip trip);

  /// Atualiza. Bumpa updated_at (UTC now). Preserva createdAt.
  /// Lança [StateError] se o id não existir ou estiver soft-deleted.
  Future<Trip> update(Trip trip);

  /// Soft delete: set deleted_at=now, bump updated_at.
  /// Idempotente: deletar duas vezes não lança e não sobrescreve o deleted_at original.
  Future<void> softDelete(String id);

  /// Busca por id. Retorna null se não existir OU se estiver soft-deleted.
  Future<Trip?> getById(String id);

  /// Lista todas as viagens NÃO deletadas do veículo, ordenadas por
  /// startDate DESC (mais recente primeiro).
  Future<List<Trip>> listByVehicle(String vehicleId);

  /// Stream reativo da mesma lista (Drift watch). Emite a cada mudança.
  Stream<List<Trip>> watchByVehicle(String vehicleId);
}

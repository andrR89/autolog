import 'package:autolog/domain/models/vehicle.dart';

/// Interface de repositório de veículos — fala só na linguagem de domínio.
/// Implementação Drift: [DriftVehicleRepository] em lib/data/repositories/.
abstract class VehicleRepository {
  /// Cria um veículo. Repositório define createdAt/updatedAt (UTC now)
  /// e sync_status=pending. Espera o caller fornecer id (UUID).
  Future<Vehicle> create(Vehicle vehicle);

  /// Atualiza. Bumpa updated_at (UTC now), marca pending. Preserva createdAt.
  /// Lança [StateError] se o id não existir ou estiver soft-deleted.
  Future<Vehicle> update(Vehicle vehicle);

  /// Soft delete: set deleted_at=now, sync_status=pending, bump updated_at.
  /// Idempotente: deletar duas vezes não lança e não sobrescreve o deleted_at original.
  Future<void> softDelete(String id);

  /// Busca por id. Retorna null se não existir OU se estiver soft-deleted.
  Future<Vehicle?> getById(String id);

  /// Lista todos os veículos NÃO deletados do usuário, ordenados por createdAt asc.
  Future<List<Vehicle>> listByUser(String userId);

  /// Stream reativo da mesma lista (Drift watch). Emite a cada mudança.
  Stream<List<Vehicle>> watchByUser(String userId);
}

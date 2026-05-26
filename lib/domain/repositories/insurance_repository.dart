import 'package:autolog/domain/models/insurance.dart';

/// Interface de repositório de apólices de seguro — fala só na linguagem de domínio.
/// Implementação Drift: [DriftInsuranceRepository] em lib/data/repositories/.
abstract class InsuranceRepository {
  /// Cria uma apólice. Repositório define createdAt/updatedAt (UTC now)
  /// e sync_status=pending.
  Future<void> create(Insurance insurance);

  /// Atualiza. Bumpa updated_at (UTC now), marca pending. Preserva createdAt.
  Future<void> update(Insurance insurance);

  /// Soft delete: set deleted_at=now, sync_status=pending, bump updated_at.
  Future<void> softDelete(String id);

  /// Lista apólices NÃO deletadas do veículo, ordenadas por endsAt DESC.
  Future<List<Insurance>> listByVehicle(String vehicleId);

  /// Stream reativo de apólices ativas (não deletadas e endsAt > now) do veículo.
  Stream<List<Insurance>> watchActive(String vehicleId, DateTime now);

  /// Busca por id. Retorna null se não existir OU soft-deleted.
  Future<Insurance?> getById(String id);
}

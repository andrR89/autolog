import 'package:autolog/domain/models/fine.dart';

/// Interface de repositório de multas — fala só na linguagem de domínio.
/// Implementação Drift: [DriftFineRepository] em lib/data/repositories/.
abstract class FineRepository {
  /// Cria uma multa. Repositório define createdAt/updatedAt (UTC now)
  /// e sync_status=pending.
  Future<void> create(Fine fine);

  /// Atualiza. Bumpa updated_at (UTC now), marca pending. Preserva createdAt.
  Future<void> update(Fine fine);

  /// Soft delete: set deleted_at=now, sync_status=pending, bump updated_at.
  Future<void> softDelete(String id);

  /// Lista multas NÃO deletadas do veículo, ordenadas por issuedAt DESC.
  Future<List<Fine>> listByVehicle(String vehicleId);

  /// Stream reativo de multas não pagas e não deletadas do veículo.
  Stream<List<Fine>> watchUnpaid(String vehicleId);

  /// Busca por id. Retorna null se não existir OU soft-deleted.
  Future<Fine?> getById(String id);

  /// Flipa o campo [paid] da multa e bumpa updated_at / marca pending.
  Future<void> togglePaid(String id);
}

import 'package:autolog/domain/models/fuel_entry.dart';

/// Interface de repositório de abastecimentos — fala só na linguagem de domínio.
/// Implementação Drift: [DriftFuelEntryRepository] em lib/data/repositories/.
abstract class FuelEntryRepository {
  /// Cria um abastecimento. Repositório define createdAt/updatedAt (UTC now)
  /// e sync_status=pending. Espera o caller fornecer id (UUID) e demais campos.
  Future<FuelEntry> create(FuelEntry entry);

  /// Atualiza. Bumpa updated_at (UTC now), marca pending. Preserva createdAt.
  /// Lança [StateError] se o id não existir ou estiver soft-deleted.
  Future<FuelEntry> update(FuelEntry entry);

  /// Soft delete: set deleted_at=now, sync_status=pending, bump updated_at.
  /// Idempotente: deletar duas vezes não lança e não sobrescreve o deleted_at original.
  Future<void> softDelete(String id);

  /// Busca por id. Retorna null se não existir OU se estiver soft-deleted.
  Future<FuelEntry?> getById(String id);

  /// Lista todos os abastecimentos NÃO deletados do veículo, ordenados por
  /// date DESC (mais recente primeiro — natural pra UX e pro cálculo de consumo).
  Future<List<FuelEntry>> listByVehicle(String vehicleId);

  /// Stream reativo da mesma lista (Drift watch). Emite a cada mudança.
  Stream<List<FuelEntry>> watchByVehicle(String vehicleId);
}

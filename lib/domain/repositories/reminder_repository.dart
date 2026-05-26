import 'package:autolog/domain/models/reminder.dart';

/// Interface de repositório de lembretes — fala só na linguagem de domínio.
/// Implementação Drift: [DriftReminderRepository] em lib/data/repositories/.
abstract class ReminderRepository {
  /// Cria um lembrete. Repositório define createdAt/updatedAt (UTC now)
  /// e sync_status=pending. Espera o caller fornecer id (UUID) e demais campos.
  Future<Reminder> create(Reminder reminder);

  /// Atualiza. Bumpa updated_at (UTC now), marca pending. Preserva createdAt.
  /// Lança [StateError] se o id não existir ou estiver soft-deleted.
  Future<Reminder> update(Reminder reminder);

  /// Soft delete: set deleted_at=now, sync_status=pending, bump updated_at.
  /// Idempotente: deletar duas vezes não lança e não sobrescreve o deleted_at original.
  Future<void> softDelete(String id);

  /// Busca por id. Retorna null se não existir OU se estiver soft-deleted.
  Future<Reminder?> getById(String id);

  /// Lista todos os lembretes NÃO deletados do veículo, ordenados por
  /// is_done ASC (não-concluídos primeiro), createdAt DESC (mais recente primeiro).
  Future<List<Reminder>> listByVehicle(String vehicleId);

  /// Stream reativo da mesma lista (Drift watch). Emite a cada mudança.
  Stream<List<Reminder>> watchByVehicle(String vehicleId);
}

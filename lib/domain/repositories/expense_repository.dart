import 'package:autolog/domain/models/expense.dart';

/// Interface de repositório de despesas — fala só na linguagem de domínio.
/// Implementação Drift: [DriftExpenseRepository] em lib/data/repositories/.
abstract class ExpenseRepository {
  /// Cria uma despesa. Repositório define createdAt/updatedAt (UTC now)
  /// e sync_status=pending. Espera o caller fornecer id (UUID) e demais campos.
  Future<Expense> create(Expense expense);

  /// Atualiza. Bumpa updated_at (UTC now), marca pending. Preserva createdAt.
  /// Lança [StateError] se o id não existir ou estiver soft-deleted.
  Future<Expense> update(Expense expense);

  /// Soft delete: set deleted_at=now, sync_status=pending, bump updated_at.
  /// Idempotente: deletar duas vezes não lança e não sobrescreve o deleted_at original.
  Future<void> softDelete(String id);

  /// Busca por id. Retorna null se não existir OU se estiver soft-deleted.
  Future<Expense?> getById(String id);

  /// Lista todas as despesas NÃO deletadas do veículo, ordenadas por
  /// date DESC, createdAt DESC (mais recente primeiro).
  Future<List<Expense>> listByVehicle(String vehicleId);

  /// Stream reativo da mesma lista (Drift watch). Emite a cada mudança.
  Stream<List<Expense>> watchByVehicle(String vehicleId);
}

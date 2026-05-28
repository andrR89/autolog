import 'package:autolog/domain/models/vehicle_member.dart';

/// Interface de repositório de membros compartilhados de veículo.
///
/// Implementação Drift: [DriftVehicleMemberRepository] em lib/data/repositories/.
/// No MVP, vehicle_members NÃO entra no GlobalSyncService. Operação via
/// Edge Fn share-vehicle popula remoto; local atualiza após a operação.
abstract class VehicleMemberRepository {
  /// Lista todos os membros de um veículo.
  Future<List<VehicleMember>> listByVehicle(String vehicleId);

  /// Stream reativo da lista de membros (Drift watch). Emite a cada mudança.
  Stream<List<VehicleMember>> watchByVehicle(String vehicleId);

  /// Insere ou atualiza um membro. Usado pós-share-vehicle para persistir
  /// localmente o novo membro sem aguardar um sync completo.
  Future<void> upsert(VehicleMember member);

  /// Remove um membro (DELETE direto — sem soft delete nesta tabela).
  Future<void> remove(String vehicleId, String userId);
}

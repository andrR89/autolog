import 'package:autolog/core/observability/analytics.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/vehicle_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Orquestra criação, edição e exclusão de veículos via [VehicleRepository].
///
/// Recebe o repositório e um gerador de IDs injetáveis para facilitar testes.
class VehicleSaver {
  VehicleSaver(this._repo, {required String Function() generateId})
    : _generateId = generateId;

  final VehicleRepository _repo;
  final String Function() _generateId;

  /// Cria um veículo novo. O repositório define timestamps e sync_status.
  ///
  /// [id] é opcional: se fornecido, usa o UUID pré-gerado (ex.: para associar
  /// snapshots FIPE gravados antes do submit). Se omitido, gera um novo UUID.
  Future<Vehicle> create({
    String? id,
    required String userId,
    required String nickname,
    String? make,
    String? model,
    int? year,
    String? uf,
    String? color,
    VehicleType type = VehicleType.carro,
    int? engineDisplacementCc,
    Decimal? tankCapacityL,
    int? horsepower,
    String? fipeCode,
    Decimal? fipeValue,
    String? fipeReferenceMonth,
    String? plate,
    String? renavam,
    String? chassi,
    required FuelType fuelType,
    required int initialOdometer,
  }) async {
    final now = DateTime.now().toUtc();
    final vehicle = Vehicle(
      id: id ?? _generateId(),
      userId: userId,
      nickname: nickname,
      make: make,
      model: model,
      year: year,
      uf: uf,
      color: color,
      type: type,
      engineDisplacementCc: engineDisplacementCc,
      tankCapacityL: tankCapacityL,
      horsepower: horsepower,
      fipeCode: fipeCode,
      fipeValue: fipeValue,
      fipeReferenceMonth: fipeReferenceMonth,
      plate: plate,
      renavam: renavam,
      chassi: chassi,
      fuelType: fuelType,
      initialOdometer: initialOdometer,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );
    final saved = await _repo.create(vehicle);
    await track(AnalyticsEvent.vehicleCreated, props: {
      'fuel_type': fuelType.wire,
      'vehicle_type': type.wire,
      'has_year': year != null,
      'has_fipe': fipeCode != null,
      'used_fipe_search': fipeCode != null,
    });
    return saved;
  }

  /// Atualiza um veículo existente, preservando id/userId/createdAt do [existing].
  /// O repositório bumpa updated_at e sync_status.
  Future<Vehicle> update(
    Vehicle existing, {
    required String nickname,
    String? make,
    String? model,
    int? year,
    String? uf,
    String? color,
    VehicleType type = VehicleType.carro,
    int? engineDisplacementCc,
    Decimal? tankCapacityL,
    int? horsepower,
    String? fipeCode,
    Decimal? fipeValue,
    String? fipeReferenceMonth,
    String? plate,
    String? renavam,
    String? chassi,
    required FuelType fuelType,
    required int initialOdometer,
  }) async {
    final updated = existing.copyWith(
      nickname: nickname,
      make: make,
      model: model,
      year: year,
      uf: uf,
      color: color,
      type: type,
      engineDisplacementCc: engineDisplacementCc,
      tankCapacityL: tankCapacityL,
      horsepower: horsepower,
      fipeCode: fipeCode,
      fipeValue: fipeValue,
      fipeReferenceMonth: fipeReferenceMonth,
      plate: plate,
      renavam: renavam,
      chassi: chassi,
      fuelType: fuelType,
      initialOdometer: initialOdometer,
    );
    final saved = await _repo.update(updated);
    await track(AnalyticsEvent.vehicleEdited);
    return saved;
  }

  /// Soft delete via [VehicleRepository.softDelete]. Nunca hard delete.
  Future<void> delete(String id) async {
    await _repo.softDelete(id);
    await track(AnalyticsEvent.vehicleDeleted);
  }
}

/// Provider Riverpod que expõe o [VehicleSaver] configurado para produção.
final vehicleSaverProvider = Provider<VehicleSaver>((ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return VehicleSaver(repo, generateId: () => const Uuid().v4());
});

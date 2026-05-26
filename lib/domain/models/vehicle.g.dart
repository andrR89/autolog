// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Vehicle _$VehicleFromJson(Map<String, dynamic> json) => _Vehicle(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  nickname: json['nickname'] as String,
  make: json['make'] as String?,
  model: json['model'] as String?,
  year: (json['year'] as num?)?.toInt(),
  uf: json['uf'] as String?,
  color: json['color'] as String?,
  type: json['type'] == null
      ? VehicleType.carro
      : const VehicleTypeConverter().fromJson(json['type'] as String),
  engineDisplacementCc: (json['engine_displacement_cc'] as num?)?.toInt(),
  tankCapacityL: const DecimalNullableJsonConverter().fromJson(
    json['tank_capacity_l'] as String?,
  ),
  horsepower: (json['horsepower'] as num?)?.toInt(),
  fipeCode: json['fipe_code'] as String?,
  fipeValue: const DecimalNullableJsonConverter().fromJson(
    json['fipe_value'] as String?,
  ),
  fipeReferenceMonth: json['fipe_reference_month'] as String?,
  plate: json['plate'] as String?,
  renavam: json['renavam'] as String?,
  chassi: json['chassi'] as String?,
  fuelType: const FuelTypeConverter().fromJson(json['fuel_type'] as String),
  initialOdometer: (json['initial_odometer'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
  syncStatus: const SyncStatusConverter().fromJson(
    json['sync_status'] as String,
  ),
);

Map<String, dynamic> _$VehicleToJson(_Vehicle instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'nickname': instance.nickname,
  'make': instance.make,
  'model': instance.model,
  'year': instance.year,
  'uf': instance.uf,
  'color': instance.color,
  'type': const VehicleTypeConverter().toJson(instance.type),
  'engine_displacement_cc': instance.engineDisplacementCc,
  'tank_capacity_l': const DecimalNullableJsonConverter().toJson(
    instance.tankCapacityL,
  ),
  'horsepower': instance.horsepower,
  'fipe_code': instance.fipeCode,
  'fipe_value': const DecimalNullableJsonConverter().toJson(instance.fipeValue),
  'fipe_reference_month': instance.fipeReferenceMonth,
  'plate': instance.plate,
  'renavam': instance.renavam,
  'chassi': instance.chassi,
  'fuel_type': const FuelTypeConverter().toJson(instance.fuelType),
  'initial_odometer': instance.initialOdometer,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
  'sync_status': const SyncStatusConverter().toJson(instance.syncStatus),
};

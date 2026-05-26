// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FuelEntry _$FuelEntryFromJson(Map<String, dynamic> json) => _FuelEntry(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  date: DateTime.parse(json['date'] as String),
  odometer: (json['odometer'] as num).toInt(),
  liters: const DecimalJsonConverter().fromJson(json['liters'] as String),
  pricePerLiter: const DecimalJsonConverter().fromJson(
    json['price_per_liter'] as String,
  ),
  totalCost: const DecimalJsonConverter().fromJson(
    json['total_cost'] as String,
  ),
  fullTank: json['full_tank'] as bool,
  fuelType: const FuelTypeConverter().fromJson(json['fuel_type'] as String),
  source: const FuelSourceConverter().fromJson(json['source'] as String),
  receiptImageUrl: json['receipt_image_url'] as String?,
  stationName: json['station_name'] as String?,
  stationBrand: json['station_brand'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
  syncStatus: const SyncStatusConverter().fromJson(
    json['sync_status'] as String,
  ),
);

Map<String, dynamic> _$FuelEntryToJson(_FuelEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'date': instance.date.toIso8601String(),
      'odometer': instance.odometer,
      'liters': const DecimalJsonConverter().toJson(instance.liters),
      'price_per_liter': const DecimalJsonConverter().toJson(
        instance.pricePerLiter,
      ),
      'total_cost': const DecimalJsonConverter().toJson(instance.totalCost),
      'full_tank': instance.fullTank,
      'fuel_type': const FuelTypeConverter().toJson(instance.fuelType),
      'source': const FuelSourceConverter().toJson(instance.source),
      'receipt_image_url': instance.receiptImageUrl,
      'station_name': instance.stationName,
      'station_brand': instance.stationBrand,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'sync_status': const SyncStatusConverter().toJson(instance.syncStatus),
    };

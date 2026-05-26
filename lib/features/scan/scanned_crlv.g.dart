// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanned_crlv.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScannedCrlv _$ScannedCrlvFromJson(Map<String, dynamic> json) => _ScannedCrlv(
  plate: json['plate'] as String?,
  renavam: json['renavam'] as String?,
  chassi: json['chassi'] as String?,
  color: json['color'] as String?,
  fuelType: const FuelTypeNullableConverter().fromJson(
    json['fuel_type'] as String?,
  ),
  make: json['make'] as String?,
  model: json['model'] as String?,
  year: (json['year'] as num?)?.toInt(),
);

Map<String, dynamic> _$ScannedCrlvToJson(_ScannedCrlv instance) =>
    <String, dynamic>{
      'plate': instance.plate,
      'renavam': instance.renavam,
      'chassi': instance.chassi,
      'color': instance.color,
      'fuel_type': const FuelTypeNullableConverter().toJson(instance.fuelType),
      'make': instance.make,
      'model': instance.model,
      'year': instance.year,
    };

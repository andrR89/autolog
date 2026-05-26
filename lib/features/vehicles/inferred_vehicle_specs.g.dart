// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inferred_vehicle_specs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InferredVehicleSpecs _$InferredVehicleSpecsFromJson(
  Map<String, dynamic> json,
) => _InferredVehicleSpecs(
  engineDisplacementCc: (json['engine_displacement_cc'] as num?)?.toInt(),
  tankCapacityL: const DecimalNullableJsonConverter().fromJson(
    json['tank_capacity_l'] as String?,
  ),
  horsepower: (json['horsepower'] as num?)?.toInt(),
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$InferredVehicleSpecsToJson(
  _InferredVehicleSpecs instance,
) => <String, dynamic>{
  'engine_displacement_cc': instance.engineDisplacementCc,
  'tank_capacity_l': const DecimalNullableJsonConverter().toJson(
    instance.tankCapacityL,
  ),
  'horsepower': instance.horsepower,
  'confidence': instance.confidence,
};

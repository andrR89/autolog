import 'package:autolog/domain/models/json_converters.dart';
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'inferred_vehicle_specs.freezed.dart';
part 'inferred_vehicle_specs.g.dart';

/// Specs técnicos inferidos pela IA para um veículo.
///
/// Retornado pelo [VehicleSpecsInferenceService] após chamada à Edge Function
/// `infer-vehicle-specs`. Todos os campos podem ser null (IA sem certeza).
/// Snake_case é configurado globalmente via build.yaml (field_rename: snake).
@freezed
abstract class InferredVehicleSpecs with _$InferredVehicleSpecs {
  const factory InferredVehicleSpecs({
    int? engineDisplacementCc,
    @DecimalNullableJsonConverter() Decimal? tankCapacityL,
    int? horsepower,
    @Default(0.0) double confidence,
  }) = _InferredVehicleSpecs;

  factory InferredVehicleSpecs.fromJson(Map<String, dynamic> json) =>
      _$InferredVehicleSpecsFromJson(json);
}

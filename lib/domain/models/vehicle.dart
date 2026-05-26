import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'vehicle.freezed.dart';
part 'vehicle.g.dart';

@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,
    required String userId,
    required String nickname,
    String? make,
    String? model,
    int? year,
    String? uf,
    String? color,
    @VehicleTypeConverter() @Default(VehicleType.carro) VehicleType type,
    int? engineDisplacementCc,
    @DecimalNullableJsonConverter() Decimal? tankCapacityL,
    int? horsepower,
    String? fipeCode,
    @DecimalNullableJsonConverter() Decimal? fipeValue,
    String? fipeReferenceMonth,
    String? plate,
    String? renavam,
    String? chassi,
    @FuelTypeConverter() required FuelType fuelType,
    required int initialOdometer,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    @SyncStatusConverter() required SyncStatus syncStatus,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);
}

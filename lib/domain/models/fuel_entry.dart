import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'fuel_entry.freezed.dart';
part 'fuel_entry.g.dart';

@freezed
abstract class FuelEntry with _$FuelEntry {
  const factory FuelEntry({
    required String id,
    required String vehicleId,
    required DateTime date,
    required int odometer,
    @DecimalJsonConverter() required Decimal liters,
    @DecimalJsonConverter() required Decimal pricePerLiter,
    @DecimalJsonConverter() required Decimal totalCost,
    required bool fullTank,
    @FuelTypeConverter() required FuelType fuelType,
    @FuelSourceConverter() required FuelSource source,
    String? receiptImageUrl,
    String? stationName,
    String? stationBrand,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    @SyncStatusConverter() required SyncStatus syncStatus,
  }) = _FuelEntry;

  factory FuelEntry.fromJson(Map<String, dynamic> json) =>
      _$FuelEntryFromJson(json);
}

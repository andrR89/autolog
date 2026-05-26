// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanned_receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScannedReceipt _$ScannedReceiptFromJson(Map<String, dynamic> json) =>
    _ScannedReceipt(
      liters: _$JsonConverterFromJson<String, Decimal>(
        json['liters'],
        const DecimalJsonConverter().fromJson,
      ),
      pricePerLiter: _$JsonConverterFromJson<String, Decimal>(
        json['price_per_liter'],
        const DecimalJsonConverter().fromJson,
      ),
      totalCost: _$JsonConverterFromJson<String, Decimal>(
        json['total_cost'],
        const DecimalJsonConverter().fromJson,
      ),
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
      fuelType: _$JsonConverterFromJson<String, FuelType>(
        json['fuel_type'],
        const FuelTypeConverter().fromJson,
      ),
    );

Map<String, dynamic> _$ScannedReceiptToJson(_ScannedReceipt instance) =>
    <String, dynamic>{
      'liters': _$JsonConverterToJson<String, Decimal>(
        instance.liters,
        const DecimalJsonConverter().toJson,
      ),
      'price_per_liter': _$JsonConverterToJson<String, Decimal>(
        instance.pricePerLiter,
        const DecimalJsonConverter().toJson,
      ),
      'total_cost': _$JsonConverterToJson<String, Decimal>(
        instance.totalCost,
        const DecimalJsonConverter().toJson,
      ),
      'date': instance.date?.toIso8601String(),
      'fuel_type': _$JsonConverterToJson<String, FuelType>(
        instance.fuelType,
        const FuelTypeConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

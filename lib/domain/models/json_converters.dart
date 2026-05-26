import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

/// Serializa [Decimal] como String em JSON (nunca double).
class DecimalJsonConverter implements JsonConverter<Decimal, String> {
  const DecimalJsonConverter();

  @override
  Decimal fromJson(String json) => Decimal.parse(json);

  @override
  String toJson(Decimal object) => object.toString();
}

/// Serializa [FuelType] usando o wire value canônico.
class FuelTypeConverter implements JsonConverter<FuelType, String> {
  const FuelTypeConverter();

  @override
  FuelType fromJson(String json) => FuelType.fromWire(json);

  @override
  String toJson(FuelType object) => object.wire;
}

/// Serializa [FuelSource] usando o wire value canônico.
class FuelSourceConverter implements JsonConverter<FuelSource, String> {
  const FuelSourceConverter();

  @override
  FuelSource fromJson(String json) => FuelSource.fromWire(json);

  @override
  String toJson(FuelSource object) => object.wire;
}

/// Serializa [ExpenseCategory] usando o wire value canônico.
class ExpenseCategoryConverter
    implements JsonConverter<ExpenseCategory, String> {
  const ExpenseCategoryConverter();

  @override
  ExpenseCategory fromJson(String json) => ExpenseCategory.fromWire(json);

  @override
  String toJson(ExpenseCategory object) => object.wire;
}

/// Serializa [ExpenseCategory?] de forma defensiva — strings desconhecidas
/// retornam null em vez de lançar exceção (Regra de Ouro: parse defensivo).
class ExpenseCategoryNullableConverter
    implements JsonConverter<ExpenseCategory?, String?> {
  const ExpenseCategoryNullableConverter();

  @override
  ExpenseCategory? fromJson(String? json) {
    if (json == null) return null;
    try {
      return ExpenseCategory.fromWire(json);
    } catch (_) {
      return null; // defensivo — desconhecido → null
    }
  }

  @override
  String? toJson(ExpenseCategory? object) => object?.wire;
}

/// Serializa [ReminderType] usando o wire value canônico.
class ReminderTypeConverter implements JsonConverter<ReminderType, String> {
  const ReminderTypeConverter();

  @override
  ReminderType fromJson(String json) => ReminderType.fromWire(json);

  @override
  String toJson(ReminderType object) => object.wire;
}

/// Serializa [SyncStatus] usando o wire value canônico.
class SyncStatusConverter implements JsonConverter<SyncStatus, String> {
  const SyncStatusConverter();

  @override
  SyncStatus fromJson(String json) => SyncStatus.fromWire(json);

  @override
  String toJson(SyncStatus object) => object.wire;
}

/// Serializa [VehicleType] usando o wire value canônico.
class VehicleTypeConverter implements JsonConverter<VehicleType, String> {
  const VehicleTypeConverter();

  @override
  VehicleType fromJson(String json) => VehicleType.fromWire(json);

  @override
  String toJson(VehicleType object) => object.wire;
}

/// Serializa [Decimal?] como String? em JSON (nunca double). Null-safe.
class DecimalNullableJsonConverter implements JsonConverter<Decimal?, String?> {
  const DecimalNullableJsonConverter();

  @override
  Decimal? fromJson(String? json) => json == null ? null : Decimal.parse(json);

  @override
  String? toJson(Decimal? object) => object?.toString();
}

/// Serializa [FuelType?] de forma defensiva — strings desconhecidas retornam
/// null em vez de lançar exceção (Regra de Ouro: parse defensivo).
class FuelTypeNullableConverter
    implements JsonConverter<FuelType?, String?> {
  const FuelTypeNullableConverter();

  @override
  FuelType? fromJson(String? json) {
    if (json == null) return null;
    try {
      return FuelType.fromWire(json);
    } catch (_) {
      return null; // defensivo — desconhecido → null
    }
  }

  @override
  String? toJson(FuelType? object) => object?.wire;
}

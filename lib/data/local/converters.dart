import 'package:autolog/domain/models/enums.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

/// Converte [Decimal] ↔ TEXT no SQLite.
/// Usa [Decimal.toString()] e [Decimal.parse()] — sem roundtrip por double,
/// garantindo precisão arbitrária (Regra de Ouro #1 do CLAUDE.md).
class DecimalConverter extends TypeConverter<Decimal, String> {
  const DecimalConverter();

  @override
  Decimal fromSql(String fromDb) => Decimal.parse(fromDb);

  @override
  String toSql(Decimal value) => value.toString();
}

/// Converte [FuelType] ↔ TEXT usando o valor canônico [FuelType.wire].
class FuelTypeConverter extends TypeConverter<FuelType, String> {
  const FuelTypeConverter();

  @override
  FuelType fromSql(String fromDb) => FuelType.fromWire(fromDb);

  @override
  String toSql(FuelType value) => value.wire;
}

/// Converte [FuelSource] ↔ TEXT usando o valor canônico [FuelSource.wire].
class FuelSourceConverter extends TypeConverter<FuelSource, String> {
  const FuelSourceConverter();

  @override
  FuelSource fromSql(String fromDb) => FuelSource.fromWire(fromDb);

  @override
  String toSql(FuelSource value) => value.wire;
}

/// Converte [ExpenseCategory] ↔ TEXT usando o valor canônico [ExpenseCategory.wire].
class ExpenseCategoryConverter extends TypeConverter<ExpenseCategory, String> {
  const ExpenseCategoryConverter();

  @override
  ExpenseCategory fromSql(String fromDb) => ExpenseCategory.fromWire(fromDb);

  @override
  String toSql(ExpenseCategory value) => value.wire;
}

/// Converte [ReminderType] ↔ TEXT usando o valor canônico [ReminderType.wire].
class ReminderTypeConverter extends TypeConverter<ReminderType, String> {
  const ReminderTypeConverter();

  @override
  ReminderType fromSql(String fromDb) => ReminderType.fromWire(fromDb);

  @override
  String toSql(ReminderType value) => value.wire;
}

/// Converte [SyncStatus] ↔ TEXT usando o valor canônico [SyncStatus.wire].
class SyncStatusConverter extends TypeConverter<SyncStatus, String> {
  const SyncStatusConverter();

  @override
  SyncStatus fromSql(String fromDb) => SyncStatus.fromWire(fromDb);

  @override
  String toSql(SyncStatus value) => value.wire;
}

/// Converte [VehicleType] ↔ TEXT usando o valor canônico [VehicleType.wire].
class VehicleTypeConverter extends TypeConverter<VehicleType, String> {
  const VehicleTypeConverter();

  @override
  VehicleType fromSql(String fromDb) => VehicleType.fromWire(fromDb);

  @override
  String toSql(VehicleType value) => value.wire;
}

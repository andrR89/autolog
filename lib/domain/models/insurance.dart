import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'insurance.freezed.dart';
part 'insurance.g.dart';

@freezed
abstract class Insurance with _$Insurance {
  const factory Insurance({
    required String id,
    required String vehicleId,
    String? insurer,
    String? policyNumber,
    required DateTime startsAt,
    required DateTime endsAt,
    @DecimalNullableJsonConverter() Decimal? premiumPaid,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    @SyncStatusConverter() required SyncStatus syncStatus,
  }) = _Insurance;

  factory Insurance.fromJson(Map<String, dynamic> json) =>
      _$InsuranceFromJson(json);
}

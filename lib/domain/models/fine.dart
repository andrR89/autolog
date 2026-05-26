import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'fine.freezed.dart';
part 'fine.g.dart';

@freezed
abstract class Fine with _$Fine {
  const factory Fine({
    required String id,
    required String vehicleId,
    String? autoNumber,
    required DateTime issuedAt,
    required String description,
    @DecimalJsonConverter() required Decimal amount,
    DateTime? dueDate,
    @Default(false) bool paid,
    int? points,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    @SyncStatusConverter() required SyncStatus syncStatus,
  }) = _Fine;

  factory Fine.fromJson(Map<String, dynamic> json) => _$FineFromJson(json);
}

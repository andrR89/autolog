// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Fine _$FineFromJson(Map<String, dynamic> json) => _Fine(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  autoNumber: json['auto_number'] as String?,
  issuedAt: DateTime.parse(json['issued_at'] as String),
  description: json['description'] as String,
  amount: const DecimalJsonConverter().fromJson(json['amount'] as String),
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  paid: json['paid'] as bool? ?? false,
  points: (json['points'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
  syncStatus: const SyncStatusConverter().fromJson(
    json['sync_status'] as String,
  ),
);

Map<String, dynamic> _$FineToJson(_Fine instance) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'auto_number': instance.autoNumber,
  'issued_at': instance.issuedAt.toIso8601String(),
  'description': instance.description,
  'amount': const DecimalJsonConverter().toJson(instance.amount),
  'due_date': instance.dueDate?.toIso8601String(),
  'paid': instance.paid,
  'points': instance.points,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
  'sync_status': const SyncStatusConverter().toJson(instance.syncStatus),
};

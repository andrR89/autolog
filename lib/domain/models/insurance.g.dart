// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insurance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Insurance _$InsuranceFromJson(Map<String, dynamic> json) => _Insurance(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  insurer: json['insurer'] as String?,
  policyNumber: json['policy_number'] as String?,
  startsAt: DateTime.parse(json['starts_at'] as String),
  endsAt: DateTime.parse(json['ends_at'] as String),
  premiumPaid: const DecimalNullableJsonConverter().fromJson(
    json['premium_paid'] as String?,
  ),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
  syncStatus: const SyncStatusConverter().fromJson(
    json['sync_status'] as String,
  ),
);

Map<String, dynamic> _$InsuranceToJson(_Insurance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'insurer': instance.insurer,
      'policy_number': instance.policyNumber,
      'starts_at': instance.startsAt.toIso8601String(),
      'ends_at': instance.endsAt.toIso8601String(),
      'premium_paid': const DecimalNullableJsonConverter().toJson(
        instance.premiumPaid,
      ),
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'sync_status': const SyncStatusConverter().toJson(instance.syncStatus),
    };

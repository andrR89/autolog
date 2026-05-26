// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  userId: json['user_id'] as String,
  cnhNumber: json['cnh_number'] as String?,
  cnhCategory: json['cnh_category'] as String?,
  cnhExpiresAt: json['cnh_expires_at'] == null
      ? null
      : DateTime.parse(json['cnh_expires_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  syncStatus: const SyncStatusConverter().fromJson(
    json['sync_status'] as String,
  ),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'cnh_number': instance.cnhNumber,
      'cnh_category': instance.cnhCategory,
      'cnh_expires_at': instance.cnhExpiresAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'sync_status': const SyncStatusConverter().toJson(instance.syncStatus),
    };

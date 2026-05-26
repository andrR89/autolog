// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_quota.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UsageQuota _$UsageQuotaFromJson(Map<String, dynamic> json) => _UsageQuota(
  userId: json['user_id'] as String,
  month: json['month'] as String,
  scanCount: (json['scan_count'] as num).toInt(),
  isPremium: json['is_premium'] as bool,
);

Map<String, dynamic> _$UsageQuotaToJson(_UsageQuota instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'month': instance.month,
      'scan_count': instance.scanCount,
      'is_premium': instance.isPremium,
    };

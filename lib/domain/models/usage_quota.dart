import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_quota.freezed.dart';
part 'usage_quota.g.dart';

@freezed
abstract class UsageQuota with _$UsageQuota {
  const factory UsageQuota({
    required String userId,
    required String month,
    required int scanCount,
    required bool isPremium,
  }) = _UsageQuota;

  factory UsageQuota.fromJson(Map<String, dynamic> json) =>
      _$UsageQuotaFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    String? cnhNumber,
    String? cnhCategory,
    DateTime? cnhExpiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    @SyncStatusConverter() required SyncStatus syncStatus,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

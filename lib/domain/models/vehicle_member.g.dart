// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VehicleMember _$VehicleMemberFromJson(Map<String, dynamic> json) =>
    _VehicleMember(
      vehicleId: json['vehicle_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$VehicleMemberToJson(_VehicleMember instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'user_id': instance.userId,
      'role': instance.role,
      'created_at': instance.createdAt.toIso8601String(),
    };

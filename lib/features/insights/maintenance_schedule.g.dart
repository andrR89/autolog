// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MaintenanceSchedule _$MaintenanceScheduleFromJson(Map<String, dynamic> json) =>
    _MaintenanceSchedule(
      items: (json['items'] as List<dynamic>)
          .map((e) => MaintenanceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MaintenanceScheduleToJson(
  _MaintenanceSchedule instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

_MaintenanceItem _$MaintenanceItemFromJson(Map<String, dynamic> json) =>
    _MaintenanceItem(
      task: json['task'] as String,
      cadenceType: json['cadence_type'] as String,
      everyKm: (json['every_km'] as num?)?.toInt(),
      everyMonths: (json['every_months'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$MaintenanceItemToJson(_MaintenanceItem instance) =>
    <String, dynamic>{
      'task': instance.task,
      'cadence_type': instance.cadenceType,
      'every_km': instance.everyKm,
      'every_months': instance.everyMonths,
      'notes': instance.notes,
    };

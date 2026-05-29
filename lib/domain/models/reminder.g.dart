// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reminder _$ReminderFromJson(Map<String, dynamic> json) => _Reminder(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  type: const ReminderTypeConverter().fromJson(json['type'] as String),
  title: json['title'] as String,
  dueKm: (json['due_km'] as num?)?.toInt(),
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  isDone: json['is_done'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
  syncStatus: const SyncStatusConverter().fromJson(
    json['sync_status'] as String,
  ),
  intervalDays: (json['interval_days'] as num?)?.toInt(),
  intervalKm: (json['interval_km'] as num?)?.toInt(),
  parentReminderId: json['parent_reminder_id'] as String?,
);

Map<String, dynamic> _$ReminderToJson(_Reminder instance) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'type': const ReminderTypeConverter().toJson(instance.type),
  'title': instance.title,
  'due_km': instance.dueKm,
  'due_date': instance.dueDate?.toIso8601String(),
  'is_done': instance.isDone,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
  'sync_status': const SyncStatusConverter().toJson(instance.syncStatus),
  'interval_days': instance.intervalDays,
  'interval_km': instance.intervalKm,
  'parent_reminder_id': instance.parentReminderId,
};

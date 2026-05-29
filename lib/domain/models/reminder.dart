import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'reminder.freezed.dart';
part 'reminder.g.dart';

@freezed
abstract class Reminder with _$Reminder {
  const factory Reminder({
    required String id,
    required String vehicleId,
    @ReminderTypeConverter() required ReminderType type,
    required String title,
    int? dueKm,
    DateTime? dueDate,
    required bool isDone,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    @SyncStatusConverter() required SyncStatus syncStatus,
    // Recorrência (Sprint 6.MM) — ambos null = one-shot (comportamento original).
    // intervalDays exige dueDate; intervalKm exige dueKm.
    int? intervalDays,
    int? intervalKm,
    // Id do lembrete anterior que gerou este (rastreabilidade).
    String? parentReminderId,
  }) = _Reminder;

  factory Reminder.fromJson(Map<String, dynamic> json) =>
      _$ReminderFromJson(json);
}

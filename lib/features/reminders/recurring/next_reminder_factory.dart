import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';

/// Fábrica pura para criar o próximo lembrete recorrente a partir de um
/// lembrete marcado como done.
///
/// Regras:
/// - Sem intervalo (intervalDays == null && intervalKm == null) → retorna null (one-shot).
/// - intervalDays definido E dueDate definido:
///     próximo dueDate = doneReminder.dueDate + intervalDays dias
/// - intervalKm definido E dueKm definido:
///     Se currentOdometerKm fornecido → dueKm = currentOdometerKm + intervalKm
///     Senão → dueKm = doneReminder.dueKm + intervalKm (fallback)
/// - Se ambos (intervalDays e intervalKm) estiverem definidos, ambos os campos
///   são propagados para o próximo lembrete.
/// - Copia: title, description, vehicleId, type, intervalKm, intervalDays.
/// - Novo id (gerado externamente), parentReminderId = doneReminder.id,
///   status = pending, deletedAt = null.
Reminder? createNextReminder({
  required Reminder doneReminder,
  required int? currentOdometerKm,
  required DateTime now,
  required String nextId,
}) {
  final hasIntervalDays =
      doneReminder.intervalDays != null && doneReminder.dueDate != null;
  final hasIntervalKm =
      doneReminder.intervalKm != null && doneReminder.dueKm != null;

  // One-shot: sem intervalo configurado.
  if (!hasIntervalDays && !hasIntervalKm) return null;

  // Calcula campos de gatilho do próximo.
  DateTime? nextDueDate;
  int? nextDueKm;

  if (hasIntervalDays) {
    nextDueDate = doneReminder.dueDate!.add(
      Duration(days: doneReminder.intervalDays!),
    );
  }

  if (hasIntervalKm) {
    if (currentOdometerKm != null) {
      nextDueKm = currentOdometerKm + doneReminder.intervalKm!;
    } else {
      // Fallback: usa o dueKm anterior como base.
      nextDueKm = doneReminder.dueKm! + doneReminder.intervalKm!;
    }
  }

  // Determina o tipo: se apenas intervalDays → porData; se apenas intervalKm
  // ou ambos → porKm (o tipo original é preservado).
  final nextType = doneReminder.type;

  return Reminder(
    id: nextId,
    vehicleId: doneReminder.vehicleId,
    type: nextType,
    title: doneReminder.title,
    dueKm: nextDueKm,
    dueDate: nextDueDate,
    isDone: false,
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatus.pending,
    intervalDays: doneReminder.intervalDays,
    intervalKm: doneReminder.intervalKm,
    parentReminderId: doneReminder.id,
  );
}

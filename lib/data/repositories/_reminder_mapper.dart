// Mapper privado da camada de dados — não exportar fora de lib/data/repositories/.
// Converte entre ReminderRow (Drift) e Reminder (domínio).

import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:drift/drift.dart';

/// Converte uma linha do banco para o modelo de domínio.
///
/// Aplica [toUtc()] em todos os [DateTime] lidos do banco (Drift armazena
/// como unix timestamp e pode retornar hora local dependendo da plataforma).
/// dueDate é nullable — aplica [toUtc()] apenas se não-null.
Reminder reminderToDomain(ReminderRow row) {
  return Reminder(
    id: row.id,
    vehicleId: row.vehicleId,
    type: row.type,
    title: row.title,
    dueKm: row.dueKm,
    dueDate: row.dueDate?.toUtc(),
    isDone: row.isDone,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    syncStatus: row.syncStatus,
    intervalDays: row.intervalDays,
    intervalKm: row.intervalKm,
    parentReminderId: row.parentReminderId,
  );
}

/// Converte o modelo de domínio para o companion do Drift.
///
/// Todos os campos são embrulhados em [Value].
RemindersCompanion reminderToCompanion(Reminder r) {
  return RemindersCompanion(
    id: Value(r.id),
    vehicleId: Value(r.vehicleId),
    type: Value(r.type),
    title: Value(r.title),
    dueKm: Value(r.dueKm),
    dueDate: Value(r.dueDate),
    isDone: Value(r.isDone),
    createdAt: Value(r.createdAt),
    updatedAt: Value(r.updatedAt),
    deletedAt: Value(r.deletedAt),
    syncStatus: Value(r.syncStatus),
    intervalDays: Value(r.intervalDays),
    intervalKm: Value(r.intervalKm),
    parentReminderId: Value(r.parentReminderId),
  );
}

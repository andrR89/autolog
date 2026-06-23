import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart';
import 'package:autolog/features/reminders/local_notification_scheduler.dart';
import 'package:autolog/features/reminders/notification_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Orquestra criação, edição, toggle e exclusão de lembretes via [ReminderRepository].
///
/// Espelha o padrão de [ExpenseSaver] (Sprint 4.1b).
/// Recebe o repositório e um gerador de IDs injetáveis para facilitar testes.
/// O parâmetro [scheduler] é opcional: quando null, nenhum side-effect de
/// notificação ocorre (comportamento da Sprint 4.2b preservado).
class ReminderSaver {
  ReminderSaver(
    this._repo, {
    required String Function() generateId,
    NotificationScheduler? scheduler,
  }) : _generateId = generateId,
       _scheduler = scheduler;

  final ReminderRepository _repo;
  final String Function() _generateId;
  final NotificationScheduler? _scheduler;

  /// Cria um lembrete.
  ///
  /// O id é gerado por [generateId]. O repositório define timestamps e sync_status.
  /// Após criação bem-sucedida, agenda notificação via [_scheduler] (se fornecido).
  Future<Reminder> create({
    required String vehicleId,
    required ReminderType type,
    required String title,
    int? dueKm,
    DateTime? dueDate,
    bool isDone = false,
    int? intervalDays,
    int? intervalKm,
  }) async {
    final now = DateTime.now().toUtc();
    final reminder = Reminder(
      id: _generateId(),
      vehicleId: vehicleId,
      type: type,
      title: title,
      dueKm: dueKm,
      dueDate: dueDate,
      isDone: isDone,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      intervalDays: intervalDays,
      intervalKm: intervalKm,
    );
    final saved = await _repo.create(reminder);
    if (_scheduler != null) {
      // Lembrete por data dispara notificação local → pedimos permissão
      // ANTES de agendar. Por km não usa notificação local, então pula.
      if (type == ReminderType.porData) {
        await _scheduler.requestPermissionIfNeeded();
      }
      await _scheduler.scheduleReminder(saved);
    }
    return saved;
  }

  /// Atualiza um lembrete existente, preservando campos de identidade.
  ///
  /// Preserva: [Reminder.id], [Reminder.vehicleId], [Reminder.createdAt].
  /// O repositório bumpa updated_at e sync_status.
  /// Cancela o agendamento antigo e re-agenda com os novos dados (se [_scheduler]
  /// fornecido). Cancela antes para garantir que mudanças de tipo/data/status
  /// não deixem notificações obsoletas.
  Future<Reminder> update(
    Reminder existing, {
    required ReminderType type,
    required String title,
    int? dueKm,
    DateTime? dueDate,
    required bool isDone,
    int? intervalDays,
    int? intervalKm,
  }) async {
    final updated = existing.copyWith(
      type: type,
      title: title,
      dueKm: dueKm,
      dueDate: dueDate,
      isDone: isDone,
      intervalDays: intervalDays,
      intervalKm: intervalKm,
      // id, vehicleId, createdAt → intocados pelo copyWith.
    );
    final saved = await _repo.update(updated);
    if (_scheduler != null) {
      await _scheduler.cancelReminder(saved.id);
      // Em update, se o tipo mudou pra porData precisa pedir permissão
      // (caso user tenha negado o popup antigo do boot).
      if (type == ReminderType.porData) {
        await _scheduler.requestPermissionIfNeeded();
      }
      await _scheduler.scheduleReminder(saved);
    }
    return saved;
  }

  /// Atalho para toggle do checkbox de "feito" na lista.
  ///
  /// Quando marcando como done (isDone: false → true) E o lembrete tem intervalo,
  /// delega para [ReminderRepository.markDone] que cria o próximo automaticamente.
  /// Quando desmarcando (done → não-done) ou sem intervalo, usa [update] simples.
  Future<Reminder> toggleDone(Reminder existing) async {
    final newDone = !existing.isDone;

    // Marcando como done com intervalo: usa markDone para criar o próximo.
    if (newDone &&
        (existing.intervalDays != null || existing.intervalKm != null)) {
      return _repo.markDone(
        existing.id,
        now: DateTime.now().toUtc(),
        generateId: _generateId,
      );
    }

    // Caso simples: sem intervalo ou desmarcando.
    return update(
      existing,
      type: existing.type,
      title: existing.title,
      dueKm: existing.dueKm,
      dueDate: existing.dueDate,
      isDone: newDone,
      intervalDays: existing.intervalDays,
      intervalKm: existing.intervalKm,
    );
  }

  /// Soft delete via [ReminderRepository.softDelete]. Nunca hard delete.
  ///
  /// Cancela a notificação pendente via [_scheduler] (se fornecido) após o delete.
  Future<void> delete(String id) async {
    await _repo.softDelete(id);
    if (_scheduler != null) {
      await _scheduler.cancelReminder(id);
    }
  }
}

/// Provider singleton para o [NotificationScheduler] de produção.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return LocalNotificationScheduler();
});

/// Provider Riverpod que expõe o [ReminderSaver] configurado para produção.
final reminderSaverProvider = Provider<ReminderSaver>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  final scheduler = ref.watch(notificationSchedulerProvider);
  return ReminderSaver(
    repo,
    generateId: () => const Uuid().v4(),
    scheduler: scheduler,
  );
});

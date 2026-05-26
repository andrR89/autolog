import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart';
import 'package:autolog/features/reminders/notification_scheduler.dart';
import 'package:autolog/features/reminders/reminder_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Serviço que verifica lembretes por km após um abastecimento ser registrado
/// e dispara notificações imediatas para os que foram cruzados.
///
/// Nunca lança — erros são silenciosos para não interferir com o save do
/// abastecimento que já foi gravado.
class ReminderTriggerService {
  ReminderTriggerService({
    required ReminderRepository reminders,
    required FuelEntryRepository fuelEntries,
    required NotificationScheduler scheduler,
  }) : _reminders = reminders,
       _fuelEntries = fuelEntries,
       _scheduler = scheduler;

  final ReminderRepository _reminders;
  final FuelEntryRepository _fuelEntries;
  final NotificationScheduler _scheduler;

  /// Chamado após um abastecimento ser criado. Encontra lembretes porKm do
  /// veículo cujo [dueKm] foi cruzado por este registro e dispara notificação
  /// imediata. Nunca lança.
  Future<void> onFuelEntryRecorded(Vehicle vehicle, FuelEntry newEntry) async {
    try {
      // 1. Lista abastecimentos do veículo.
      final allEntries = await _fuelEntries.listByVehicle(vehicle.id);

      // 2. Filtra entradas ANTERIORES ao newEntry.
      //    Empate de data: exclui self por id (conservador — não conta o próprio).
      final previousEntries = allEntries.where((e) {
        if (e.id == newEntry.id) return false;
        return e.date.isBefore(newEntry.date) ||
            (e.date.isAtSameMomentAs(newEntry.date));
      }).toList();

      // 3. previous_odometer = max(odometer) dos anteriores, ou initialOdometer
      //    se não houver anteriores.
      final previousOdometer = previousEntries.isEmpty
          ? vehicle.initialOdometer
          : previousEntries
                .map((e) => e.odometer)
                .reduce((a, b) => a > b ? a : b);

      // 4. Lista lembretes ativos do veículo (repo já filtra soft-deleted).
      final allReminders = await _reminders.listByVehicle(vehicle.id);

      // 5. Para cada lembrete porKm ativo, verifica cruzamento.
      for (final reminder in allReminders) {
        if (reminder.type != ReminderType.porKm) continue;
        if (reminder.isDone) continue;
        if (reminder.dueKm == null) continue;

        final dueKm = reminder.dueKm!;
        if (previousOdometer < dueKm && dueKm <= newEntry.odometer) {
          // Cruzamento detectado — dispara notificação imediata.
          try {
            await _scheduler.showNow(
              id: reminder.id,
              title: reminder.title,
              body:
                  'Veículo atingiu ${newEntry.odometer} km '
                  '(alvo: $dueKm km).',
            );
          } catch (_) {
            // Falha individual não impede processar os demais lembretes.
          }
        }
      }
    } catch (_) {
      // Erro silencioso — não propaga para o caller.
    }
  }
}

/// Provider Riverpod que expõe o [ReminderTriggerService] configurado para produção.
final reminderTriggerServiceProvider = Provider<ReminderTriggerService>((ref) {
  final reminders = ref.watch(reminderRepositoryProvider);
  final fuelEntries = ref.watch(fuelEntryRepositoryProvider);
  final scheduler = ref.watch(notificationSchedulerProvider);
  return ReminderTriggerService(
    reminders: reminders,
    fuelEntries: fuelEntries,
    scheduler: scheduler,
  );
});

// reminder_calendar_bridge.dart — Bridge entre ReminderRepository e Google Calendar.
//
// Evita acoplamento direto do repositório de dados ao serviço de Calendar.
// Uso: chamar syncReminder/unsyncReminder nos forms de salvar/deletar reminder.
//
// TODO: ligar nos saves dos forms quando OAuth real estiver ativo (Sprint 6.EE+).

import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/calendar/calendar_event_link_repository.dart';
import 'package:autolog/features/calendar/google_calendar_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReminderCalendarBridge {
  const ReminderCalendarBridge({
    required this.calendarService,
    required this.linkRepository,
  });

  final GoogleCalendarService calendarService;
  final CalendarEventLinkRepository linkRepository;

  /// Sincroniza um reminder com o Google Calendar.
  /// Se o serviço não estiver conectado, é no-op silencioso.
  /// Fire-and-forget: não bloqueia a UI.
  Future<void> syncReminder(Reminder reminder) async {
    try {
      if (!await calendarService.isConnected()) return;

      final eventId = await calendarService.upsertEvent(reminder);
      if (eventId != null) {
        await linkRepository.save(reminder.id, eventId);
      }
    } catch (_) {
      // Falha silenciosa — Calendar é feature adicional, não bloqueia o app.
    }
  }

  /// Remove o evento do Calendar e o link local para um reminder deletado.
  /// Se não houver link, é no-op silencioso.
  Future<void> unsyncReminder(String reminderId) async {
    try {
      final eventId = await linkRepository.getEventIdFor(reminderId);
      if (eventId == null) return;

      if (await calendarService.isConnected()) {
        await calendarService.deleteEvent(eventId);
      }

      await linkRepository.remove(reminderId);
    } catch (_) {
      // Falha silenciosa — não impede o soft-delete local.
    }
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

final reminderCalendarBridgeProvider = Provider<ReminderCalendarBridge>((ref) {
  return ReminderCalendarBridge(
    calendarService: ref.watch(googleCalendarServiceProvider),
    linkRepository: ref.watch(calendarEventLinkRepositoryProvider),
  );
});

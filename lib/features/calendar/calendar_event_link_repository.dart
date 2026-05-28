// calendar_event_link_repository.dart — mapeamento local reminder → Google Calendar event.
//
// Armazena o ID do evento do Calendar criado para um reminder, pra suportar
// upsert e delete sem precisar consultar o Calendar.

import 'package:autolog/data/local/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Abstração
// ---------------------------------------------------------------------------

abstract class CalendarEventLinkRepository {
  /// Retorna o calendarEventId associado ao [reminderId], ou null se não há link.
  Future<String?> getEventIdFor(String reminderId);

  /// Salva (ou atualiza) o link reminder → calendarEventId.
  Future<void> save(String reminderId, String calendarEventId);

  /// Remove o link do [reminderId] (ex.: ao soft-deletar o reminder).
  Future<void> remove(String reminderId);

  /// Lista todos os links existentes.
  Future<List<CalendarEventLinkRow>> listAll();
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

class DriftCalendarEventLinkRepository implements CalendarEventLinkRepository {
  DriftCalendarEventLinkRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String?> getEventIdFor(String reminderId) async {
    final row = await (_db.select(_db.calendarEventLinks)
          ..where((t) => t.reminderId.equals(reminderId)))
        .getSingleOrNull();
    return row?.calendarEventId;
  }

  @override
  Future<void> save(String reminderId, String calendarEventId) async {
    await _db.into(_db.calendarEventLinks).insertOnConflictUpdate(
          CalendarEventLinksCompanion.insert(
            reminderId: reminderId,
            calendarEventId: calendarEventId,
            syncedAt: DateTime.now().toUtc(),
          ),
        );
  }

  @override
  Future<void> remove(String reminderId) async {
    await (_db.delete(_db.calendarEventLinks)
          ..where((t) => t.reminderId.equals(reminderId)))
        .go();
  }

  @override
  Future<List<CalendarEventLinkRow>> listAll() async {
    return _db.select(_db.calendarEventLinks).get();
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

final calendarEventLinkRepositoryProvider =
    Provider<CalendarEventLinkRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftCalendarEventLinkRepository(db);
});

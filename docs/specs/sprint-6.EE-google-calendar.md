# Sprint 6.EE — Google Calendar sync (one-way)

> Lembretes do AutoLog viram eventos do Google Calendar do user.
> Sync one-way (app → Calendar). MVP: criar evento ao salvar reminder;
> deletar evento ao soft-delete reminder.

## Decisões
- Pacotes `google_sign_in: ^7` + `googleapis: ^14` + `googleapis_auth: ^2`.
- Scope `calendar.events` (escrita restrita a eventos criados pelo app).
- Setup OAuth precisa de **Client IDs no Google Cloud Console** + config
  iOS (Info.plist URL scheme) + Android (SHA1). Como isso requer ação
  externa do Diretor, vai como README detalhado em
  `docs/google-calendar-setup.md`.
- Sem setup OAuth no momento → service usa `MockCalendarService` por
  default (provider retorna mock se as credentials não estão configuradas).
- Tabela local `calendar_event_links(reminder_id, calendar_event_id)`
  pra suportar update/delete sem buscar no Calendar.

## Mudanças

### 1. Pacotes
`pubspec.yaml`:
```yaml
google_sign_in: ^7.0.0
googleapis: ^14.0.0
googleapis_auth: ^2.0.0
```

### 2. Schema v16 — `calendar_event_links` (local)
```dart
@DataClassName('CalendarEventLinkRow')
class CalendarEventLinks extends Table {
  TextColumn get reminderId => text()();
  TextColumn get calendarEventId => text()();
  DateTimeColumn get syncedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {reminderId};
}
```

Bump schemaVersion 15 → 16. `if (from < 16) createTable(calendarEventLinks)`.

### 3. Service
`lib/features/calendar/google_calendar_service.dart`:
```dart
abstract class GoogleCalendarService {
  Future<bool> isConnected();
  Future<void> connect();      // dispara OAuth
  Future<void> disconnect();   // signOut + limpa links
  /// Cria/atualiza evento pra um reminder.
  Future<String?> upsertEvent(Reminder reminder);
  /// Remove evento.
  Future<void> deleteEvent(String calendarEventId);
}

class RealGoogleCalendarService implements GoogleCalendarService { ... }
class MockGoogleCalendarService implements GoogleCalendarService {
  bool connected = false;
  int upsertCallCount = 0;
  int deleteCallCount = 0;
}

final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  // Por enquanto retorna mock (até OAuth ser configurado).
  return MockGoogleCalendarService();
});
```

### 4. Repository de links
`lib/features/calendar/calendar_event_link_repository.dart`:
- `Future<String?> getEventIdFor(String reminderId)`
- `Future<void> save(reminderId, eventId)`
- `Future<void> remove(reminderId)`

### 5. Trigger automático
`lib/data/repositories/reminder_repository.dart` (Drift impl):
- Após `create`/`update`: se `calendarService.isConnected()`, dispara
  `upsertEvent(reminder)` fire-and-forget e salva o eventId no link table.
- Após `softDelete`: lookup eventId, delete no Calendar, remove link.

Pra não acoplar repo a service (clean arch), criar `ReminderCalendarBridge`
que escuta watch do repo e atualiza Calendar. Provider executa em background
via `ref.listen`.

Pragmático: chamar diretamente do saver/repository por ora.

### 6. UI Settings
`SettingsScreen` ganha 3º card `_GoogleCalendarCard`:
- Se desconectado: botão "Conectar Google Calendar".
- Se conectado: mostra "Conectado como [email]" + "Desconectar".
- Aviso PT-BR: "Lembretes criados aqui aparecem no seu Google Calendar."

### 7. Setup README
`docs/google-calendar-setup.md`:
- Google Cloud Console: criar projeto + ativar Calendar API
- OAuth consent screen + scope `calendar.events`
- Criar 2 OAuth client IDs (iOS + Android)
- iOS: adicionar `REVERSED_CLIENT_ID` em Info.plist (URL Scheme)
- Android: adicionar SHA1 do debug keystore + bundle id
- Drop client IDs no `dart_define.json` (já gitignored)
- Trocar provider mock → real

## Testes
- `test/data/local/calendar_event_links_v16_test.dart` — schema + CRUD.
- `test/features/calendar/calendar_event_link_repository_test.dart` — get/save/remove.
- `test/features/calendar/mock_google_calendar_service_test.dart` — counts.

## Critérios
- Suite verde + ~15 novos
- analyze 0, iOS sim builds (sem OAuth real ativado)
- README de setup detalhado

## Não-objetivos
- Sync 2-way (Calendar → app).
- Multi-calendário (user escolher).
- Cor customizada do evento.

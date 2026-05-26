# Spec — Sprint 4.3: Notificações locais para lembretes por data

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 4.2 (`Reminder` + `ReminderSaver`). Usa `flutter_local_notifications ^18.0.1` (já no pubspec).

## Escopo
- `NotificationScheduler` (interface) + `LocalNotificationScheduler` (impl real wrapping `flutter_local_notifications`) + `FakeNotificationScheduler` (test).
- Integração no `ReminderSaver`: side-effects (schedule/cancel) após CRUD, via parâmetro opcional.
- Init no boot do app (`main.dart`): canais, timezone, request de permissão iOS.
- **Apenas reminders `type == porData`** geram notificação. `porKm` é no-op aqui (4.4 cuida).

Fora de escopo: lógica km-trigger (4.4); ações na notificação (tap → abre lembrete); rich notifications.

## Decisões técnicas

### 1. Interface
`lib/features/reminders/notification_scheduler.dart`:
```dart
abstract class NotificationScheduler {
  /// Inicializa o plugin (canais, timezone, permissões). Chamado uma vez no
  /// boot do app. Idempotente.
  Future<void> init();

  /// Agenda/atualiza a notificação do reminder. No-op se:
  /// - reminder.type != porData
  /// - reminder.isDone == true
  /// - reminder.dueDate == null
  /// - reminder.dueDate.isBefore(now()) (data já passada)
  /// - reminder.deletedAt != null
  /// Substitui silenciosamente qualquer notificação anterior com o mesmo id.
  Future<void> scheduleReminder(Reminder reminder);

  /// Cancela a notificação pendente do reminder, se existir. Idempotente.
  Future<void> cancelReminder(String reminderId);
}

class FakeNotificationScheduler implements NotificationScheduler {
  final Map<String, Reminder> scheduled = {};
  final List<String> cancelled = [];
  int initCalls = 0;
  @override Future<void> init() async => initCalls++;
  @override Future<void> scheduleReminder(Reminder r) async {
    // Aplica as mesmas regras de no-op (testáveis).
    if (r.type != ReminderType.porData) return;
    if (r.isDone) return;
    if (r.dueDate == null) return;
    if (r.deletedAt != null) return;
    scheduled[r.id] = r;
  }
  @override Future<void> cancelReminder(String id) async {
    scheduled.remove(id);
    cancelled.add(id);
  }
}
```

### 2. Impl real
`lib/features/reminders/local_notification_scheduler.dart`:
- `class LocalNotificationScheduler implements NotificationScheduler`.
- Usa `FlutterLocalNotificationsPlugin` singleton interno.
- `init()`: inicializa o plugin (Android channel "reminders", iOS settings), chama `tz.initializeTimeZones()` + `tz.setLocalLocation(tz.getLocation(_localTimezone()))` (usa `timezone` package — transitive de flutter_local_notifications). Faz `requestPermissions()` no iOS na primeira chamada.
- `scheduleReminder(r)`:
  - Aplica todos os no-ops da interface.
  - Agenda usando `zonedSchedule` no horário `(r.dueDate em local timezone, 09:00)` — manhã, hora razoável pra ver.
  - ID inteiro derivado de `r.id.hashCode.abs()` (mapeia String → int estável).
  - Title = `r.title`. Body = "Lembrete vencendo hoje". Channel "reminders".
- `cancelReminder(id)`: `plugin.cancel(id.hashCode.abs())`.

### 3. Integração no `ReminderSaver` (parâmetro opcional)
Atualiza `ReminderSaver`:
- Construtor: `ReminderSaver(this._repo, {required generateId, NotificationScheduler? scheduler})`. Default null = sem side-effect (mantém tests 4.2b passando).
- Após cada `create`/`update` bem-sucedido: `_scheduler?.scheduleReminder(saved)`.
- Após cada `toggleDone` bem-sucedido: idem (regra da interface decide schedule/cancel).
- Após cada `delete`: `_scheduler?.cancelReminder(id)`.
- Provider `reminderSaverProvider` agora injeta o scheduler real (em testes, override com fake).

### 4. main.dart init
- Após `Supabase.initialize(...)`, chamar `await scheduler.init()` (instância criada na main, antes do `runApp`). Como `LocalNotificationScheduler` é stateful, criar via container que vai pro Riverpod com `overrideWithValue` se necessário.
- Pra simplificar: provider `notificationSchedulerProvider` com factory que cria `LocalNotificationScheduler`. Init fica em `main.dart` antes do runApp lendo `ProviderContainer().read(notificationSchedulerProvider).init()`.

## Critérios de aceite

**`test/features/reminders/notification_scheduling_test.dart`** (com `FakeNotificationScheduler` + `_FakeReminderRepository`):

1. `create` com `porData` futuro: scheduler.scheduled[id] tem o reminder.
2. `create` com `porKm`: scheduler.scheduled vazio (no-op).
3. `create` com `porData` mas `dueDate` no passado: scheduler.scheduled vazio.
4. `update` mudando `dueDate`: scheduler.scheduled tem o reminder com nova data (substitui silenciosamente).
5. `update` marcando `isDone=true`: scheduler.scheduled NÃO tem o reminder (foi para no-op — mas precisa cancelar). Decisão: o `update` chama `scheduleReminder` que aplica no-op; o ID continua em `scheduled` da chamada anterior. **Pra garantir cancelamento ativo, o saver chama `cancelReminder` ANTES de `scheduleReminder` em updates** — assim qualquer mudança limpa o agendamento antigo. Teste valida: depois de marcar done, `scheduled[id]` é null E `cancelled` contém o id.
6. `toggleDone` (false→true): scheduled[id] null + cancelled contém id.
7. `toggleDone` (true→false) com porData futuro: re-agenda → scheduled[id] tem o reminder.
8. `delete`: scheduled[id] null + cancelled contém id.

**Deliverables (revisão Haiku + homologação visual):**
9. `init()` chamado em main antes do runApp.
10. Permissão iOS solicitada na primeira execução.
11. Notificação aparece no simulador na data alvo (homologação requer rodar com data mockada ou esperar até a data).

## Definition of Done
- 8 testes verdes; suíte completa verde (~232); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- ReminderSaver scheduler param é opcional — tests da 4.2b continuam passando sem alteração.
- Sem hardcoded creds.

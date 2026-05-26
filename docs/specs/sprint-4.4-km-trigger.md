# Spec — Sprint 4.4: Disparo de lembretes por km

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 4.2 (`Reminder`), 4.3 (`NotificationScheduler`), 2.1 (`FuelEntryRepository`).
> **Última tarefa do Sprint 4.**

## Escopo
Quando o usuário registra um abastecimento com odômetro `O_new`, percorrer os lembretes ativos do veículo do tipo `porKm` e **disparar notificação imediata** para cada um cujo `dueKm` foi **cruzado** por este registro (passou de "abaixo" pra "igual/acima").

Regra de "cruzamento" (evita re-disparar em entries futuros acima da mesma meta):
- `previous_odometer < reminder.dueKm <= O_new` → dispara.
- `previous_odometer` = odômetro do abastecimento imediatamente anterior em data (ou empate de data) do mesmo veículo. Se não houver, usa `vehicle.initialOdometer`.

Fora de escopo: marcar reminder como done automaticamente (usuário decide); cancelar notif agendada quando reminder vira porKm (a 4.3 já faz via `cancelReminder` antes de `scheduleReminder` no update).

## Decisões técnicas

### 1. `NotificationScheduler` ganha `showNow`
Em `lib/features/reminders/notification_scheduler.dart`:
```dart
abstract class NotificationScheduler {
  // ... existentes
  /// Dispara uma notificação imediata (não-agendada). [id] usado pra evitar
  /// duplicatas se chamado em rápida sucessão.
  Future<void> showNow({required String id, required String title, required String body});
}
```
- `FakeNotificationScheduler` adiciona `List<({String id, String title, String body})> fired = [];` (ou Map) preenchido por `showNow`.
- `LocalNotificationScheduler` implementa com `plugin.show(id.hashCode.abs(), title, body, NotificationDetails(...))`.

### 2. `ReminderTriggerService`
`lib/features/reminders/reminder_trigger_service.dart`:
```dart
class ReminderTriggerService {
  ReminderTriggerService({
    required ReminderRepository reminders,
    required FuelEntryRepository fuelEntries,
    required NotificationScheduler scheduler,
  });

  /// Chamado após um abastecimento ser criado. Encontra reminders porKm do
  /// veículo cujo dueKm foi cruzado por este registro e dispara notificação
  /// imediata. Nunca lança.
  Future<void> onFuelEntryRecorded(Vehicle vehicle, FuelEntry newEntry);
}
```
Algoritmo:
1. Lista os abastecimentos do veículo (`fuelEntries.listByVehicle`).
2. Filtra para os **anteriores** ao `newEntry` (`date < newEntry.date` OU `date == newEntry.date && id != newEntry.id` — empate de data: ignorar self).
3. `previous_odometer` = max(odometer) entre esses anteriores, ou `vehicle.initialOdometer` se vazio.
4. Lista reminders ativos do veículo: `reminders.listByVehicle(vehicle.id)` → filtra `type == porKm && !isDone && dueKm != null`.
5. Para cada reminder, se `previous_odometer < reminder.dueKm! <= newEntry.odometer`:
   - `scheduler.showNow(id: reminder.id, title: reminder.title, body: 'Veículo atingiu ${newEntry.odometer} km (alvo: ${reminder.dueKm} km).')`.
6. **NUNCA lança**: try/catch ao redor; erro é silencioso (não atrapalha o save do abastecimento que já foi).

Provider `reminderTriggerServiceProvider` injetando os três deps.

### 3. Integração no `FuelEntrySaver`
Em `lib/features/fuel/fuel_entry_saver.dart`:
- Adicionar parâmetro opcional ao construtor: `ReminderTriggerService? triggerService`. Default null = no-op (mantém os 4 testes existentes da 2.3 verdes).
- Adicionar parâmetro opcional ao `create`: `Vehicle? vehicle`. Quando passado E `triggerService != null`, após `repo.create(...)` chama `triggerService.onFuelEntryRecorded(vehicle, savedEntry)`.
- Update e delete: NÃO disparam (cruzamento é fenômeno de create — edit de odômetro pra cima também poderia gerar; deixar fora pra simplificar e evitar duplicatas).
- `fuelEntrySaverProvider` é atualizado pra injetar service. Form passa `vehicle` no `create`.

### 4. Atualização no form
`FuelEntryFormScreen._submit` passa `vehicle: widget.vehicle` no `saver.create(...)`. Já tem o vehicle no widget.

## Critérios de aceite (= testes em `test/features/reminders/reminder_trigger_test.dart`)

Com `FakeReminderRepository`, `FakeFuelEntryRepository` (in-memory), `FakeNotificationScheduler` (já existe), e `Vehicle` montado:

1. **Cruzamento**: vehicle initial=10000, reminder porKm dueKm=15000, nenhum fuel entry anterior, novo entry com odômetro=16000 → scheduler.fired contém 1 item com o reminder.id.
2. **Cruzamento com fuel anterior**: 1 fuel entry anterior em 14000, reminder dueKm=15000, novo entry em 16000 (cruza 14000 → 16000 passando 15000) → dispara 1x.
3. **Não cruza — alvo abaixo do anterior**: 1 fuel entry anterior em 16000, reminder dueKm=15000 (já passou antes), novo entry em 17000 → NÃO dispara.
4. **Não cruza — alvo acima do novo**: 1 fuel entry anterior em 10000, reminder dueKm=20000, novo entry em 16000 (não chega lá) → NÃO dispara.
5. **Reminder porData**: tipo porData com qualquer dueDate → NÃO dispara (não é o caso).
6. **Reminder done**: isDone=true mesmo cruzando → NÃO dispara.
7. **Reminder soft-deletado**: deletedAt != null → NÃO dispara (filtrado por `listByVehicle` do repo).
8. **Múltiplos reminders crossing**: 3 reminders porKm com dueKm=15000, 15500, 16000, novo entry de 14000→17000 → 3 firings.
9. **Vehicle initialOdometer como baseline**: sem fuel entries anteriores, initial=10000, reminder dueKm=10500, novo entry com 11000 → dispara.
10. **Sem reminders**: lista vazia → 0 firings, sem erro.
11. **NUNCA lança**: se scheduler.showNow lançar, o service captura e retorna normalmente (não propaga).

## Definition of Done
- 11 testes verdes; suíte completa verde (~243); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Existing 2.3 saver tests (4 deles) continuam verdes (parâmetros novos opcionais).
- Service nunca lança; erros são silenciosos (logs ok).

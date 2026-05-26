# Spec — Sprint 4.2b: UI de lembretes (form + lista)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 4.2a (`ReminderRepository`) + padrões UI das 1.3/2.3/4.1b.

## Escopo
- `ReminderSaver` (espelha `ExpenseSaver`) + método `toggleDone` pra um-tap na lista.
- Form criar/editar reminder com **seletor de tipo** (Por km / Por data) que troca o campo visível.
- Tela de lista de reminders do veículo (com toggle done embutido em cada item).
- Entry-point no detalhe do veículo (FuelHistoryScreen) pra `/vehicles/:id/reminders`.
- Rotas: `/vehicles/:vehicleId/reminders`, `/.../new`, `/.../:id/edit`.

Fora de escopo: notificações locais (4.3), lógica de disparo automático por km (4.4).

## Decisões técnicas

### 1. `ReminderSaver` (testável)
`lib/features/reminders/reminder_saver.dart`:
```dart
class ReminderSaver {
  ReminderSaver(this._repo, {required String Function() generateId});

  Future<Reminder> create({
    required String vehicleId,
    required ReminderType type,
    required String title,
    int? dueKm,
    DateTime? dueDate,
    bool isDone = false,
  });

  Future<Reminder> update(
    Reminder existing, {
    required ReminderType type,
    required String title,
    int? dueKm,
    DateTime? dueDate,
    required bool isDone,
  });

  /// Atalho pra toggle do checkbox de "feito" na lista.
  /// Equivale a `update(existing, ...mesmos campos..., isDone: !existing.isDone)`.
  Future<Reminder> toggleDone(Reminder existing);

  Future<void> delete(String id);
}
```
- `create`: gera id; repo cuida de timestamps/syncStatus.
- `update`: preserva `id`, `vehicleId`, `createdAt`.
- `toggleDone`: helper conveniente.
- Provider `reminderSaverProvider`.

### 2. Form `ReminderFormScreen`
`lib/features/reminders/reminder_form_screen.dart`:
- AppBar com `BackButton` + Tooltip "Voltar". Title "Novo lembrete" / "Editar lembrete".
- Campos:
  - **Título** (TextFormField, required via `_validateRequired`).
  - **Tipo** (`SegmentedButton` ou 2 `Radio`: "Por quilômetro" / "Por data") — controla qual campo aparece abaixo.
  - **Quando type=porKm**: campo "Quilometragem alvo (km)" (numérico inteiro, required, ≥ 0).
  - **Quando type=porData**: campo "Data alvo" (DatePicker, required, default = hoje + 30 dias no create).
  - **Concluído** (Switch, só visível no modo edit; create começa false).
- Botão Salvar com loading; SnackBar PT-BR em erro; save → `canPop ? pop : go('/vehicles/$id/reminders')`.
- Validação: se type=porKm e dueKm vazio/null → "Informe a quilometragem alvo"; se type=porData e dueDate null → "Informe a data alvo". (Tipo opposto é null automaticamente.)

### 3. Lista `RemindersListScreen`
`lib/features/reminders/reminders_list_screen.dart`:
- AppBar título "Lembretes" + pencil pra editar veículo.
- Body: `StreamProvider.family` ouvindo `repo.watchByVehicle(vehicle.id)`. AsyncValue padrão.
- Empty placeholder PT-BR: "Nenhum lembrete cadastrado. Toque em + pra começar."
- Card item:
  - **Leading**: `Checkbox` (controla `isDone`) — onChanged chama `saver.toggleDone(reminder)`.
  - **Título**: bold; se `isDone == true`, riscar (`TextDecoration.lineThrough`) e cor secundária.
  - **Sub**: tipo label + alvo formatado:
    - `porKm` → "Por km · Alvo: X km" (formatar com separador de milhar).
    - `porData` → "Por data · Alvo: DD/MM/YYYY".
  - **Trailing**: `IconButton` lixeira → AlertDialog confirm → `saver.delete`.
  - Tap no card → push `/.../$id/edit`.
- FAB "+" → push `/.../new`.

### 4. Entry-point no detalhe do veículo
`FuelHistoryScreen`: adicionar `IconButton(icon: const Icon(Icons.notifications_outlined), tooltip: 'Lembretes', onPressed: () => context.push('/vehicles/${vehicle.id}/reminders'))` na AppBar ANTES do ícone de Despesas (ordem: notif, $, pencil).

### 5. Roteamento
Em `lib/core/router.dart`, mesmo padrão dos loaders:
- `/vehicles/:vehicleId/reminders` → `_VehicleRemindersLoader` → `RemindersListScreen(vehicle: ...)`.
- `/vehicles/:vehicleId/reminders/new` → `_ReminderNewLoader` → `ReminderFormScreen(vehicle: ..., initial: null)`.
- `/vehicles/:vehicleId/reminders/:reminderId/edit` → `_ReminderEditLoader` → carrega vehicle E reminder → `ReminderFormScreen(vehicle: ..., initial: reminder)`.

## Critérios de aceite

**`test/features/reminders/reminder_saver_test.dart`** (com `_FakeReminderRepository`):

1. `create por_km`: chama `repo.create` com Reminder montado: id do generateId, type=porKm, dueKm preservado, dueDate=null.
2. `create por_data`: type=porData, dueDate preservado, dueKm=null. Default isDone=false.
3. `update`: preserva `id`, `vehicleId`, `createdAt` do existing; aplica campos novos.
4. `toggleDone`: flipa isDone (false→true e true→false) preservando outros campos; chama `repo.update`.
5. `delete`: chama `repo.softDelete(id)`.
6. Erro do repo propaga intacto.

**Deliverables (Haiku + homologação):**
7. Botão "Lembretes" na AppBar do detalhe → lista.
8. Criar/listar/editar/excluir lembrete; toggle done na lista; type-selector troca campos.
9. Lista ordena: não-feitos primeiro (do mais recente), feitos depois.

## Definition of Done
- 6 testes do saver verdes; suíte completa verde (~224); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Sem hard delete. PT-BR em tudo.

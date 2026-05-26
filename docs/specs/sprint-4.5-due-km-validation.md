# Spec — Sprint 4.5: Validação `dueKm > odômetro atual` no form de lembrete

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> **Classificação: B (spec gap)** — homologa do Sprint 4 mostrou que dá pra criar lembrete `porKm` com alvo abaixo do odômetro atual. Ele nunca dispara (regra de cruzamento da 4.4 exige `previous < due_km <= new`). Bug no spec do 4.2b.

## Regra
`dueKm` válido = **maior que** o odômetro atual do veículo.
- Odômetro atual = `max(vehicle.initialOdometer, max(odometer dos fuel_entries não-deletados do veículo))`.
- Se `dueKm <= odômetro atual` → bloqueia salvar com aviso PT-BR.

Aplica em **create** e **update** (mesma regra; user pode editar um lembrete por km antigo, deve seguir a regra).

## Implementação

### 1. Função pura
`lib/features/reminders/reminder_validators.dart` (novo):
```dart
/// Retorna null se [dueKm] é válido como alvo (maior que o odômetro atual
/// do veículo), ou uma mensagem PT-BR explicando.
String? validateDueKm({
  required int dueKm,
  required int vehicleInitialOdometer,
  required List<FuelEntry> entries,
}) {
  int currentMax = vehicleInitialOdometer;
  for (final e in entries) {
    if (e.deletedAt != null) continue;
    if (e.odometer > currentMax) currentMax = e.odometer;
  }
  if (dueKm <= currentMax) {
    return 'Quilometragem alvo deve ser maior que a atual ($currentMax km).';
  }
  return null;
}
```

### 2. Integração no `ReminderFormScreen`
- Adicionar estado `String? _dueKmError`.
- Quando type=porKm: ao mudar `dueKm` (debounce 600ms — mesmo padrão do fuel form), fetch `fuelEntryRepository.listByVehicle(vehicle.id)`, validar e setar `_dueKmError`.
- Quando type=porData: limpar `_dueKmError` (regra não se aplica).
- Mostrar erro inline em vermelho debaixo do campo "Quilometragem alvo".
- Save button: `onPressed = (_saving || _dueKmError != null) ? null : _submit`.

## Critérios de aceite (= testes em `test/features/reminders/due_km_validation_test.dart`)

`validateDueKm`:
1. Sem entries, `dueKm > initial` → null.
2. Sem entries, `dueKm == initial` → erro PT-BR contendo "atual" e o valor inicial.
3. Sem entries, `dueKm < initial` → erro.
4. Com entries, `dueKm > max(odômetros)` → null.
5. Com entries, `dueKm == max(odômetros)` → erro com o max.
6. Com entries, `dueKm < max(odômetros)` → erro.
7. Entries soft-deletados são ignorados.
8. Mistura: initial=10000, entries [(d1,15000), (d2,12000)] (deletada uma), dueKm=14000 → considerar max das não-deletadas (não importa data). Se a 15000 está deletada → max=12000 → dueKm=14000 → null. Se não-deletada → max=15000 → erro.

## Definition of Done
- 8 testes verdes; suíte completa verde (~251); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Save button bloqueado quando inválido.
- Existing 4.2b tests (6) + 4.3 tests (8) + 4.4 tests (11) continuam verdes.

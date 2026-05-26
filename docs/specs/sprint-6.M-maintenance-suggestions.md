# Sprint 6.M — Calendário de manutenção sugerido por modelo

> Onda 2, sprint 1/10. Primeiro a se beneficiar das specs técnicas da Onda 1.
> IA gera lista típica de manutenção pro modelo do veículo → user escolhe quais
> viram lembretes recorrentes.

## Decisões já tomadas
- Sob demanda (não auto no cadastro). Acessível a partir da tela `InsightsScreen` (6.G) com um botão novo, ou da tela de detalhe do veículo. Decisão: **InsightsScreen** — concentra todas as features de IA num só lugar.
- Cota: compartilha **`scan_count`** (mesmo balde dos outros scans/inferências).
- Output **típico**, não personalizado por histórico do veículo (essa é a 6.G). 6.M usa só `{type, make, model, year, engineCc?, tankL?}`.
- User pode aceitar/recusar cada item; aceitos viram Reminders com dedupe (reuso da lógica de 6.G).

## Mudanças

### 1. Modelo `MaintenanceSchedule` (`lib/features/insights/maintenance_schedule.dart`)

```dart
@freezed
abstract class MaintenanceSchedule with _$MaintenanceSchedule {
  const factory MaintenanceSchedule({
    required List<MaintenanceItem> items,
  }) = _MaintenanceSchedule;
  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceScheduleFromJson(json);
}

@freezed
abstract class MaintenanceItem with _$MaintenanceItem {
  const factory MaintenanceItem({
    required String task,           // "Troca de óleo"
    required String cadenceType,    // 'km' | 'months' | 'km_or_months'
    int? everyKm,                   // ex: 10000
    int? everyMonths,               // ex: 12
    String? notes,
  }) = _MaintenanceItem;
  factory MaintenanceItem.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceItemFromJson(json);
}
```

### 2. Service (`lib/features/insights/maintenance_suggestion_service.dart`)
Espelho exato do `VehicleSpecsInferenceService`:
```dart
abstract class MaintenanceSuggestionService {
  Future<MaintenanceSchedule> suggest({
    required VehicleType type,
    required String make,
    required String model,
    required int year,
    int? engineDisplacementCc,
    Decimal? tankCapacityL,
  });
}

class RealMaintenanceSuggestionService implements MaintenanceSuggestionService {
  // invoca 'suggest-maintenance' edge function
  // QuotaExhaustedException + ScanException patterns
}

class MockMaintenanceSuggestionService implements MaintenanceSuggestionService {
  // default: ~6 items típicos (troca óleo, filtro ar, freio, correia, etc)
}
```

### 3. Edge function `supabase/functions/suggest-maintenance/index.ts`
Espelho do `infer-vehicle-specs`:
- Cota `scan_count`.
- Body: `{ type, make, model, year, engine_displacement_cc?, tank_capacity_l? }`.
- Prompt PT-BR pedindo lista típica de manutenção brasileira:
  ```
  Lista 4 a 10 itens de manutenção típicos pro veículo informado.
  Para cada um, indique cadência (a cada N km, N meses, ou ambos — o que ocorrer primeiro).
  Schema: {
    "items": [
      {
        "task": string,
        "cadence_type": "km" | "months" | "km_or_months",
        "every_km": int|null,
        "every_months": int|null,
        "notes": string|null
      }
    ]
  }
  Foque em manutenções padrão (óleo, filtros, freios, correia, velas, etc).
  Use intervalos típicos brasileiros pra esse modelo/ano.
  Se algum item é específico de moto (corrente, kit relação), inclua só se type=moto.
  Pra carro, não inclua itens só de moto.
  ```
- Modelo: `claude-haiku-4-5`, `max_tokens: 1024`.
- Parse defensivo: array filtrado pra ter `task` non-empty e cadência válida.
- Incrementa cota só se `items.length > 0`.

### 4. UI — Nova tela ou seção em InsightsScreen?
Decisão: **botão na `InsightsScreen` (6.G)** chamado "Plano de manutenção sugerido" + tela dedicada `MaintenancePlanScreen`.

`lib/features/insights/maintenance_plan_screen.dart`:
- Header: "Manutenção sugerida pra {make} {model} {year}".
- Botão "Gerar plano" (loading state).
- Resultado: lista de cards (1 por item):
  - Title: task (ex: "Troca de óleo")
  - Subtitle: cadência formatada PT-BR ("A cada 10.000 km ou 12 meses, o que vier primeiro")
  - Notes em texto cinza menor.
  - Botão **Criar lembrete** (no item) + botão **Ignorar**.
- Botão flutuante: "Criar todos" (cria os que ainda não foram criados).

Criação de lembrete:
- Tipo do reminder: se `cadence_type == 'months'` → `ReminderType.porData` com `dueDate = today + everyMonths`.
- Se `cadence_type == 'km'` → `ReminderType.porKm` com `dueKm = currentOdometer + everyKm`.
- Se `cadence_type == 'km_or_months'` → cria 2 reminders ou 1 com a opção que vence primeiro? Pra MVP: cria 2 reminders separados ("Troca de óleo (km)" e "Troca de óleo (data)").
- Aplicar dedupe de 6.G (`dedupeProposed` adaptado: converter `MaintenanceItem` em `ProposedReminder` antes).

Estados: empty (antes de gerar), loading, success (lista), erro (quota / scan exception).

### 5. Roteamento
`lib/core/router.dart`: rota `/vehicles/:vehicleId/insights/maintenance` ou similar. Loader igual ao InsightsScreen.

## Testes

### `test/features/insights/maintenance_schedule_test.dart` (novo)
Parse defensivo do `MaintenanceSchedule` + `MaintenanceItem` (JSON completo, vazio, chaves extras, cadence_type desconhecido → cai pra default, roundtrip).

### `test/features/insights/maintenance_suggestion_service_test.dart` (novo)
- Invoca `'suggest-maintenance'` com body correto.
- Retorna `MaintenanceSchedule` parseado.
- 429 → QuotaExhaustedException.
- ScanException propaga sem wrap.
- Erro genérico → ScanException contendo "manutenção".
- Mock: callCount/fixedResult/throwOnCall/delay (default não-vazio).

## Critérios de aceite
- [ ] Todos os testes verdes (512+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Tela `MaintenancePlanScreen` navegável e funcional
- [ ] Dedupe aplicado antes de oferecer (não propor lembrete já criado)

## Não-objetivos
- Personalização por histórico (já tem em 6.G — analyze-history).
- Pricing estimado de cada manutenção (futuro).
- Notificações push proativas (futuro).
- Vincular a oficinas específicas (futuro — possível pós-MVP).

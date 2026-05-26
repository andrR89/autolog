# Spec — Sprint 0.3: Modelos de domínio (freezed + json_serializable)

> Papel: **Opus (especificação + TDD)**. Próximo: Sonnet implementa até verde; Haiku revisa.
> Fonte: `docs/ARCHITECTURE.md §3` + Regras de Ouro do `CLAUDE.md`. Depende de 0.2 (enums em `lib/domain/models/enums.dart`).

## Escopo

Modelos de domínio **puros** (freezed 3.x + json_serializable) para as 5 entidades: `Vehicle`, `FuelEntry`, `Expense`, `Reminder`, `UsageQuota`. São objetos imutáveis com `==`, `copyWith`, `toJson`/`fromJson`. **Independentes das row classes do Drift** (a conversão domínio↔Drift é da Sprint 1, nos repositórios — NÃO entra aqui).

Fora de escopo: repositórios, mapeamento Drift↔domínio, lógica de negócio (consumo é 2.2), sync.

## Decisões técnicas (não-negociáveis)

### 1. Dinheiro/volume = `Decimal`, e em JSON vai como **String**
Campos `liters`, `pricePerLiter`, `totalCost`, `amount` são `Decimal`. Em JSON serializam como **string** (`"43.219"`), nunca número — número JSON passaria por `double` e perderia precisão. Regra de Ouro.
→ `DecimalJsonConverter implements JsonConverter<Decimal, String>` (`toJson` = `Decimal.toString()`, `fromJson` = `Decimal.parse()`). Em `lib/domain/models/json_converters.dart`.
> Nota p/ sync (0.4/1.2): a coluna no Supabase é `numeric`; o mapeamento string↔numeric é resolvido na borda de sync, não aqui. Decisão de manter String no domínio para não tocar `double`.

### 2. Enums serializam pelo **wire value** (fonte única)
Reusar `wire`/`fromWire` já definidos na 0.2 — **não** duplicar strings com `@JsonValue`. Um `JsonConverter<E, String>` por enum, delegando a `E.fromWire`/`e.wire`:
`FuelTypeConverter`, `FuelSourceConverter`, `ExpenseCategoryConverter`, `ReminderTypeConverter`, `SyncStatusConverter`. Em `lib/domain/models/json_converters.dart`. Aplicados nos campos via anotação (`@FuelSourceConverter()` etc.).

### 3. Chaves JSON em **snake_case** (espelha Supabase)
Convenção do projeto: todo JSON de domínio usa snake_case para casar com as colunas do Postgres (`user_id`, `initial_odometer`, `price_per_liter`, `full_tank`, `vehicle_id`, `scan_count`, `is_premium`, `created_at`…).
→ Criar `build.yaml` com `json_serializable: field_rename: snake` (global). Não anotar campo a campo.

### 4. DateTime
`DateTime` serializa em ISO-8601 (comportamento padrão do json_serializable). Armazenar/comparar em UTC.

### 5. freezed 3.x
Sintaxe freezed 3.x: `@freezed abstract class X with _$X { const factory X({...}) = _X; factory X.fromJson(...) => _$XFromJson(...); }`. Codegen via `build_runner`.

## Campos por modelo (de `ARCHITECTURE §3`)

- **Vehicle**: id, userId, nickname, make?, model?, plate?, fuelType (`FuelType`), initialOdometer (int), createdAt, updatedAt, deletedAt?, syncStatus (`SyncStatus`).
- **FuelEntry**: id, vehicleId, date, odometer (int), liters (`Decimal`), pricePerLiter (`Decimal`), totalCost (`Decimal`), fullTank (bool), fuelType (`FuelType`), source (`FuelSource`), receiptImageUrl?, createdAt, updatedAt, deletedAt?, syncStatus.
- **Expense**: id, vehicleId, date, category (`ExpenseCategory`), description, amount (`Decimal`), odometer (int?), createdAt, updatedAt, deletedAt?, syncStatus.
- **Reminder**: id, vehicleId, type (`ReminderType`), title, dueKm (int?), dueDate (DateTime?), isDone (bool), createdAt, updatedAt, deletedAt?, syncStatus.
- **UsageQuota**: userId, month (String), scanCount (int), isPremium (bool). (Sem campos de sync — espelha `usage_quota`.)

Um arquivo por modelo em `lib/domain/models/` (substituindo os stubs `// TODO: implement`).

## Critérios de aceite (= testes em `test/domain/models/models_test.dart`)

1. **Vehicle**: `toJson`→`fromJson` roundtrip preserva tudo (incl. `deletedAt: null` e opcionais nulos). JSON usa snake_case: contém `user_id`, `initial_odometer`, `fuel_type`. `fuel_type` serializa como `"flex"`. `copyWith` e igualdade de valor funcionam (duas instâncias iguais são `==`).
2. **FuelEntry — precisão decimal (CRÍTICO)**: roundtrip JSON de `liters=43.219`, `pricePerLiter=5.799`, `totalCost=250.634781` exato. `json['liters']` é a **string** `"43.219"` (tipo `String`, não `num`). `json['full_tank'] == true`. `source` serializa `"ai_scan"`; `fromJson` reconstrói `FuelSource.aiScan`. Chave `price_per_liter` presente.
3. **DecimalJsonConverter**: valor além da precisão de `double` (`12345678901234.123456789`) faz roundtrip exato; `toJson` retorna `String`.
4. **Expense**: `amount` decimal exato no roundtrip; `category` serializa `"ipva"`; `odometer: null` sobrevive ao roundtrip.
5. **Reminder**: `type` serializa `"por_km"`; `due_km`/`due_date` nulos sobrevivem; `is_done` no JSON.
6. **UsageQuota**: roundtrip; chaves `user_id`, `scan_count`, `is_premium`, `month`.
7. **syncStatus**: default/serialização — `syncStatus` serializa como `"pending"`/`"synced"` (via wire).

## Definition of Done
- Testes acima verdes (`flutter test test/domain/models/`).
- Suíte completa verde; `dart format`; `flutter analyze` limpo.
- `build_runner` rodado (`*.freezed.dart`, `*.g.dart` gerados).
- Nenhum `double` no caminho de serialização de dinheiro/volume (testes 2 e 3 garantem).

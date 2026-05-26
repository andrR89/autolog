# Spec — Sprint 0.2: Schema Drift das 5 tabelas

> Papel: **Opus (especificação + TDD)**. Próximo: Sonnet implementa até os testes ficarem verdes; Haiku revisa.
> Fonte: `docs/ARCHITECTURE.md §3` (modelo de dados) + Regras de Ouro do `CLAUDE.md`.

## Escopo

Definir o schema local (Drift/SQLite) das 5 tabelas com seus campos de sync. **Só schema + roundtrip de persistência.** CRUD de repositório, soft-delete filtrado em queries e sync ficam para a Sprint 1 — **não** entram aqui.

Fora de escopo nesta tarefa: DAOs com lógica, repositórios, geração de UUID (o repositório fornece o `id` na 1.1), filtros de `deleted_at` em queries.

## Decisões técnicas (não-negociáveis para o Sonnet)

### 1. Dinheiro e volume = `Decimal`, nunca `double`
Regra de Ouro: dinheiro nunca é `double` na lógica. Colunas `liters`, `price_per_liter`, `total_cost`, `amount` são `Decimal` (package `decimal`, já no pubspec).
Drift não tem tipo decimal nativo → **`TypeConverter<Decimal, String>`** (`DecimalConverter`) que serializa via `Decimal.toString()` e desserializa via `Decimal.parse()`. Armazena como TEXT. **Proíbe roundtrip por `double`** (perda de precisão). Arquivo: `lib/data/local/converters.dart`.

### 2. Enums = fonte única, com valor de "wire" explícito
Enums em `lib/domain/models/enums.dart` (Dart puro, não freezed — compartilhados entre Drift agora e os modelos freezed na 0.3). Cada enum carrega o **valor canônico de string** que será gravado no banco e usado no espelho do Supabase (0.4), para não divergir do backend:

```dart
enum FuelType { gasolina, etanol, diesel, flex, gnv }            // wire == name
enum FuelSource { aiScan('ai_scan'), ocr('ocr'), manual('manual'); ... }
enum ExpenseCategory { manutencao('manutencao'), lavagem('lavagem'),
  estacionamento('estacionamento'), multa('multa'), seguro('seguro'),
  ipva('ipva'), outro('outro'); ... }
enum ReminderType { porKm('por_km'), porData('por_data'); ... }
enum SyncStatus { pending('pending'), synced('synced'); ... }
```
Cada enum expõe `String get wire` e um `static fromWire(String)`. Os `TypeConverter`s de cada enum usam `wire`/`fromWire`. Valores de wire seguem `ARCHITECTURE §3` (snake_case onde o doc mostra: `ai_scan`, `por_km`, `ipva`).

### 3. Campos de sync (4 tabelas sincronizáveis)
`vehicles`, `fuel_entries`, `expenses`, `reminders` têm:
- `id` TEXT PK (UUID; **fornecido pelo client** — sem auto-gen no schema).
- `updated_at` DATETIME (não-nulo).
- `created_at` DATETIME (não-nulo).
- `deleted_at` DATETIME **nullable** (soft delete; só a coluna aqui).
- `sync_status` enum `SyncStatus` com **default `pending`**.

### 4. `usage_quota` é diferente (segue `ARCHITECTURE §3`)
NÃO tem os campos de sync padrão. Estrutura:
- `user_id` TEXT **PK**
- `month` TEXT ("YYYY-MM")
- `scan_count` INT **default 0**
- `is_premium` BOOL **default false**

### 5. `AppDatabase`
- `lib/data/local/database.dart`: `class AppDatabase extends _$AppDatabase`.
- `schemaVersion => 1`.
- Construtor que **aceita um `QueryExecutor`** (injeção), para os testes usarem `NativeDatabase.memory()`. Um named constructor de produção pode usar `LazyDatabase`/`path_provider` (pode ficar para a 0.1/0.5 — aqui o foco é a injeção testável).
- Tabelas registradas em `@DriftDatabase(tables: [...])`.
- Código gerado via `build_runner` (`database.g.dart`).

## Mapa das tabelas (resumo de `ARCHITECTURE §3`)

| Tabela | Campos próprios (além dos de sync) |
|---|---|
| `vehicles` | user_id TEXT, nickname TEXT, make TEXT?, model TEXT?, plate TEXT?, fuel_type FuelType, initial_odometer INT |
| `fuel_entries` | vehicle_id TEXT, date DATETIME, odometer INT, liters Decimal, price_per_liter Decimal, total_cost Decimal, full_tank BOOL, fuel_type FuelType, source FuelSource, receipt_image_url TEXT? |
| `expenses` | vehicle_id TEXT, date DATETIME, category ExpenseCategory, description TEXT, amount Decimal, odometer INT? |
| `reminders` | vehicle_id TEXT, type ReminderType, title TEXT, due_km INT?, due_date DATETIME?, is_done BOOL (default false) |
| `usage_quota` | (ver §4 — sem campos de sync) |

## Critérios de aceite (= os testes em `test/data/local/database_test.dart`)

1. O banco abre com `schemaVersion == 1` e expõe exatamente as **5 tabelas**.
2. **vehicles**: insert→select roundtrip; `sync_status` default `pending`; `deleted_at` default `null`; `fuel_type` persiste e volta como enum.
3. **fuel_entries — precisão decimal (CRÍTICO)**: gravar `liters=43.219`, `price_per_liter=5.799`, `total_cost=250.634781` e ler de volta **exatamente iguais** (igualdade `Decimal`, sem drift). `full_tank` bool e `source` enum persistem.
4. **DecimalConverter**: um valor além da precisão de `double` (ex. `12345678901234.123456789`) faz roundtrip exato.
5. **expenses**: `amount` decimal exato; `category` enum; `odometer` nullable aceita `null`.
6. **reminders**: `type` enum; `due_km`/`due_date` nullable; `is_done` default `false`.
7. **usage_quota**: PK `user_id`; `scan_count` default `0`; `is_premium` default `false`; `month` TEXT roundtrip.
8. **Wire values**: `FuelSource.aiScan.wire == 'ai_scan'`, `ReminderType.porKm.wire == 'por_km'`, `ExpenseCategory.ipva.wire == 'ipva'` — e a coluna grava esse valor (verificável lendo a string crua).

## Definition of Done
- Todos os testes acima verdes (`flutter test test/data/local/`).
- `dart format` aplicado; `flutter analyze` sem warnings.
- `build_runner` rodado; `database.g.dart` presente.
- Nenhum `double` envolvido na ida/volta de valores monetários (verificado pelos testes 3 e 4).

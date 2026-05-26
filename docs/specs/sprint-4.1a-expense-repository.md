# Spec — Sprint 4.1a: Repositório de `expenses` (CRUD local + soft delete)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Espelha 1.1 (`VehicleRepository`) e 2.1 (`FuelEntryRepository`). Sem novidade arquitetural.

## Escopo
Repositório local de `Expense` sobre Drift, offline-first, soft delete, isolado por veículo. UI fica para 4.1b.

Fora de escopo: sync remoto (dívida técnica), UI (4.1b), lembretes (4.2).

## Decisões técnicas

### 1. Interface no domínio
`lib/domain/repositories/expense_repository.dart`:
```dart
abstract class ExpenseRepository {
  Future<Expense> create(Expense expense);
  Future<Expense> update(Expense expense);
  Future<void> softDelete(String id);
  Future<Expense?> getById(String id);
  Future<List<Expense>> listByVehicle(String vehicleId);
  Stream<List<Expense>> watchByVehicle(String vehicleId);
}
```

### 2. Impl Drift
`lib/data/repositories/expense_repository.dart`: `DriftExpenseRepository implements ExpenseRepository`, com `DateTime Function() now` injetável. Provider `expenseRepositoryProvider` consumindo `appDatabaseProvider`.

### 3. Mapper privado
`lib/data/repositories/_expense_mapper.dart`: `Expense fuelEntryToDomain(ExpenseRow row)` e `ExpensesCompanion toCompanion(Expense e)`. `.toUtc()` em todos os DateTime lidos. Decimal `amount` flui sem tocar double.

### 4. Regras de mutação (não-negociáveis)
- Toda escrita marca `sync_status = pending`.
- `create`: `createdAt = updatedAt = now()`; sobrescreve qualquer valor do caller.
- `update`: preserva `createdAt`; bumpa `updatedAt`; falha (StateError) se id não existir OU estiver soft-deletado.
- `softDelete` idempotente (não sobrescreve `deletedAt` original).

### 5. Leitura
- `getById`/`listByVehicle`/`watchByVehicle` filtram `deleted_at IS NULL` E por `vehicleId`.
- Ordem: `date DESC, createdAt DESC` (secundário pra empate). Sem terciário por odômetro porque `odometer` em expense é opcional.

### 6. Sem `double` em `amount`
`amount` é `Decimal`. Mapper passa pelo `DecimalConverter` (já existe na 0.2). Nada de cast pra double.

## Critérios de aceite (= testes em `test/data/repositories/expense_repository_test.dart`)

Usar `AppDatabase(NativeDatabase.memory())` + `now` injetado (mesmo padrão das 1.1/2.1):

1. **create**: insere; `getById` retorna o mesmo; `sync_status = pending`; `createdAt = updatedAt = fakeNow`; `deletedAt = null`.
2. **create — precisão decimal SAGRADA**: `amount = Decimal.parse('1234.567')` → roundtrip exato via `getById`.
3. **create — caller mandando synced** é sobrescrito para pending.
4. **update**: bumpa `updated_at`, preserva `createdAt`, marca pending.
5. **update — id inexistente**: `StateError`.
6. **update — soft-deletado**: `StateError`.
7. **softDelete**: marca `deletedAt`, esconde dos reads.
8. **softDelete idempotente**: segunda chamada não sobrescreve `deletedAt` original (verificável via leitura raw).
9. **listByVehicle**: ordena por `date DESC`, exclui soft-deletados.
10. **listByVehicle — tiebreaker createdAt DESC**: datas iguais → mais recente cadastrado em cima.
11. **listByVehicle — isolamento por vehicleId**.
12. **watchByVehicle**: emite inicial e em cada mutação (create, update, softDelete).

## Definition of Done
- 12 testes verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- Sem hard delete; sem `double` no path do `amount`.
- Domínio sem leak de Drift.

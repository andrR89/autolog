# Sprint 6.D-expenses — Sync de Expenses

> Mirror direto de `sprint-6.D-fuel-sync.md` e da implementação 1.2 (vehicles).
> Pré-requisito: 6.D-fuel ✅ entregue.

## Objetivo
Habilitar push/pull de `expenses` entre Drift local e Supabase usando o mesmo
contrato `SyncResult` já estabelecido em `vehicle_sync_service.dart`.

## Por que JOIN com vehicles?
Igual ao fuel_entries: a tabela `expenses` **não tem coluna `user_id`** — a
posse do registro é derivada via `vehicle_id` → `vehicles.user_id`. RLS no
backend faz o mesmo filtro server-side; o client espelha local.

## Arquivos a criar (3)

### `lib/data/sync/remote_expense_source.dart`
```dart
abstract class RemoteExpenseSource {
  Future<void> upsert(Expense expense);
  Future<List<Expense>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}

class SupabaseRemoteExpenseSource implements RemoteExpenseSource { ... }
```
- Sem `.eq('user_id', ...)` no fetch — RLS filtra.
- Tabela remota: `expenses`. Mesmas colunas snake_case já mapeadas.

### `lib/data/sync/expense_sync_facade.dart`
```dart
abstract class ExpenseSyncFacade {
  Future<List<Expense>> listPending(String userId);
  Future<DateTime?> latestSyncedUpdatedAt(String userId);
  Future<void> markSynced(String id);
  Future<void> upsertFromRemote(Expense remote);
  Future<Expense?> getById(String id);
  Future<int> countPending(String userId);
}

class DriftExpenseSyncFacade implements ExpenseSyncFacade {
  // Todos métodos com filtro por user usam innerJoin(vehicles):
  //   select(expenses).join([
  //     innerJoin(vehicles, vehicles.id.equalsExp(expenses.vehicleId)),
  //   ])..where(vehicles.userId.equals(userId))
}
```
- `upsertFromRemote`: força `syncStatus = synced`. Guard LWW (só sobrescreve se
  `remote.updatedAt > local.updatedAt`).

### `lib/data/sync/expense_sync_service.dart`
Cópia literal de `FuelEntrySyncService` trocando tipos. Reusa
`SyncResult` de `vehicle_sync_service.dart`.

Ordem fixa: push → cursor capture → pull. Pull nunca lança (captura em
`pullError`).

## Testes (11) — já escritos em `test/data/sync/expense_sync_service_test.dart`
Mirror integral dos testes de fuel.

## Critérios de aceite
- [ ] 11 testes verdes
- [ ] Suite completa segue verde (304+11 = 315)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Padrão idêntico ao 6.D-fuel (revisão por diff é trivial)

## Não-objetivos
- Orquestrador global (6.D-orchestrator)
- UI de status agregado (vem no orchestrator)
- Migrations server (presume tabela `expenses` já existe e RLS já configurada)

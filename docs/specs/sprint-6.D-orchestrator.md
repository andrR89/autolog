# Sprint 6.D-orchestrator — GlobalSyncService + Notifier agregado

> Fecha a saga 6.D unificando os 4 services em um único ponto de entrada
> e elevando o indicador de sync da UI pra cobrir todas as entidades.

## Pré-requisitos
- 6.D-fuel ✅
- 6.D-expenses ✅
- 6.D-reminders ✅

## Objetivo
1. Criar `GlobalSyncService` que orquestra vehicle/fuel/expense/reminder.
2. Adicionar `watchPendingCount` em expense/reminder façades (já existe em vehicle/fuel).
3. Atualizar `SyncStatusNotifier` pra:
   - Somar `_pendingCount` dos 4 streams.
   - Disparar `GlobalSyncService.sync` no `triggerSync`.
   - Mapear `GlobalSyncResult` → `SyncDisplayStatus` reutilizando a lógica
     atual (tem failures → offline; pendentes > 0 → pending; else synced).

## Contrato `GlobalSyncService`

```dart
class GlobalSyncResult {
  const GlobalSyncResult({
    required this.totalPushed,
    required this.totalPulled,
    required this.totalPushFailures,
    required this.errors, // Map<String entidade, Object error>
  });

  final int totalPushed;
  final int totalPulled;
  final int totalPushFailures;
  final Map<String, Object> errors;

  bool get hasFailures => totalPushFailures > 0 || errors.isNotEmpty;
}

class GlobalSyncService {
  GlobalSyncService({
    required VehicleSyncService vehicle,
    required FuelEntrySyncService fuel,
    required ExpenseSyncService expense,
    required ReminderSyncService reminder,
  });

  /// Executa vehicles primeiro (FK), depois fuel/expenses/reminders.
  /// Exceção num service NÃO interrompe os outros — vira `errors[<entidade>]`.
  /// `SyncResult.pullError` também conta como erro agregado.
  Future<GlobalSyncResult> sync(String userId);
}
```

Chaves canônicas em `errors`: `'vehicles'`, `'fuel'`, `'expenses'`, `'reminders'`.

## Ordem de execução
Serial: **vehicles → fuel → expenses → reminders.**
Vehicles primeiro porque os outros 3 fazem `innerJoin(vehicles)` na façade
pra resolver o `user_id`; se um vehicle remoto novo não foi puxado, suas
entries filhas ficam invisíveis. Os 3 dependentes podem ser paralelos mas
fica serial pra simplicidade e logs determinísticos.

## Mudanças nas façades
Adicionar em `ExpenseSyncFacade` e `ReminderSyncFacade`:
```dart
Stream<int> watchPendingCount(String userId);
```
Implementação Drift via `watchSingle` + `count()` no `select(expenses).join([
  innerJoin(vehicles, vehicles.id.equalsExp(expenses.vehicleId)),
])..where(vehicles.userId.equals(userId) & syncStatus.equals('pending') & deletedAt.isNull())`.

Manter `countPending` (Future) também — não quebrar nada.

## `SyncStatusNotifier` — mudanças
- Substituir `_pendingSub` por 4 subscriptions (uma por entidade).
- Manter um array `_pendingCounts = [v, f, e, r]` e usar `sum` no derive.
- `triggerSync` chama `globalSyncServiceProvider`; mapeia `GlobalSyncResult`
  pra `SyncResult` sintético (manter API externa estável):
  ```
  SyncResult(
    pushed: g.totalPushed,
    pulled: g.totalPulled,
    pushFailures: g.totalPushFailures,
    pullError: g.errors.isNotEmpty ? AggregateError(g.errors) : null,
  )
  ```
- Testes existentes em `test/features/sync/sync_status_notifier_test.dart`
  precisam ser atualizados pra alimentar os 4 fakes (3 novos retornam
  pending=0 e SyncResult vazio por padrão). Manter cobertura semântica.

## Testes
- `test/data/sync/global_sync_service_test.dart` (RED, 7 testes — já escrito)
- `test/features/sync/sync_status_notifier_test.dart` (atualizar)

## Critérios de aceite
- [ ] 7 testes novos verdes
- [ ] Notifier tests atualizados, todos verdes
- [ ] Suite completa verde
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Indicador de sync na UI continua funcionando (smoke manual no Diretor)

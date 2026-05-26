# Sprint 6.D-reminders — Sync de Reminders

> Mirror direto de `sprint-6.D-expenses-sync.md` / `sprint-6.D-fuel-sync.md`.
> Pré-requisitos: 6.D-fuel ✅, 6.D-expenses ✅.

## Objetivo
Habilitar push/pull de `reminders` entre Drift local e Supabase usando o mesmo
contrato `SyncResult` reusado de `vehicle_sync_service.dart`.

## Por que JOIN com vehicles?
Igual ao fuel/expenses: `reminders` **não tem coluna `user_id`** — posse derivada
via `vehicle_id`. RLS no backend faz o filtro server-side; client espelha local.

## Arquivos a criar (3)
- `lib/data/sync/remote_reminder_source.dart` — abstract + Supabase impl
- `lib/data/sync/reminder_sync_facade.dart` — Drift façade com innerJoin(vehicles)
- `lib/data/sync/reminder_sync_service.dart` — service reusa SyncResult

Mesma assinatura/contratos do 6.D-expenses, trocando `Expense` por `Reminder`.

## Modelo (`lib/domain/models/reminder.dart`)
```
id, vehicleId, type (ReminderType porKm|porData), title,
dueKm?, dueDate?, isDone, createdAt, updatedAt, deletedAt?, syncStatus
```
Sem `Decimal`; `type` serializa via `ReminderTypeConverter` (wire `por_km`/`por_data`).

## Testes (11) — já escritos em `test/data/sync/reminder_sync_service_test.dart`
Mirror integral dos testes de expense (push/pull/conflito/isolamento/erros).

## Critérios de aceite
- [ ] 11 testes verdes
- [ ] Suite completa segue verde (315+11 = 326)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds

# Spec — Sprint 4.2a: Repositório de `reminders` (CRUD local + soft delete)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Espelha 4.1a / 2.1 / 1.1. Mesmo padrão; sem novidade arquitetural.

## Escopo
Repositório local de `Reminder` sobre Drift, offline-first, soft delete, isolado por veículo. UI na 4.2b.

Fora de escopo: notificações locais (4.3), lógica de disparo por km (4.4), UI (4.2b).

## Decisões técnicas

### 1. Interface no domínio
`lib/domain/repositories/reminder_repository.dart`:
```dart
abstract class ReminderRepository {
  Future<Reminder> create(Reminder reminder);
  Future<Reminder> update(Reminder reminder);
  Future<void> softDelete(String id);
  Future<Reminder?> getById(String id);
  Future<List<Reminder>> listByVehicle(String vehicleId);
  Stream<List<Reminder>> watchByVehicle(String vehicleId);
}
```

### 2. Impl Drift
`lib/data/repositories/reminder_repository.dart`: `DriftReminderRepository` com `DateTime Function() now` injetável. Mapper privado `_reminder_mapper.dart`. Provider `reminderRepositoryProvider`.

### 3. Regras de mutação (idênticas aos outros repos)
- Toda escrita marca `sync_status = pending`.
- `create`: `createdAt = updatedAt = now()`.
- `update`: preserva `createdAt`; bumpa `updatedAt`; StateError se id não existe OU soft-deletado.
- `softDelete` idempotente.

### 4. Leitura
- Filtros padrão: `deleted_at IS NULL` AND `vehicle_id = ?`.
- Ordem: `is_done ASC` (false=0 antes de true=1 — não-concluídos em cima), depois `created_at DESC` (tiebreaker). Simples e útil pra UX.

### 5. Mapper preserva tudo
`isDone` bool, `type` enum (`porKm`/`porData`), `dueKm` int?, `dueDate` DateTime? (com `.toUtc()` se não-null).

## Critérios de aceite (= testes em `test/data/repositories/reminder_repository_test.dart`)

Usar `AppDatabase(NativeDatabase.memory())` + `now` injetado:

1. **create**: insere; `getById` retorna; `sync_status = pending`; `createdAt = updatedAt = fakeNow`; `deletedAt = null`.
2. **create por_km com dueKm**: roundtrip preserva `type=porKm`, `dueKm=50000`, `dueDate=null`.
3. **create por_data com dueDate**: roundtrip preserva `type=porData`, `dueDate=DateTime.utc(2026,12,31)`, `dueKm=null`.
4. **create — caller mandando synced** é sobrescrito para pending.
5. **update** (ex: marcar `isDone=true`): bumpa updated_at, preserva createdAt, marca pending.
6. **update — id inexistente**: StateError.
7. **update — soft-deletado**: StateError.
8. **softDelete**: marca deletedAt, esconde dos reads.
9. **softDelete idempotente**: segunda chamada preserva deletedAt original.
10. **listByVehicle**: ordem `is_done ASC, created_at DESC` (não-feitos primeiro, mais recentes em cima).
11. **listByVehicle isolamento por vehicleId**.
12. **watchByVehicle**: emite inicial + cada mutação.

## Definition of Done
- 12 testes verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- Sem hard delete; domínio sem leak de Drift.

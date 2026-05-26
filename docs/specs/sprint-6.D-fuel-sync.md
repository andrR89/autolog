# Spec — 6.D-fuel: Sync de `fuel_entries` (espelho do 1.2)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Dívida técnica pré-lançamento. Mirror direto de `lib/data/sync/{remote_vehicle_source,vehicle_sync_facade,vehicle_sync_service}.dart` aplicado a `fuel_entries`.

## Escopo
Engine de sync (push pending + pull incremental + last-write-wins) pra `fuel_entries`, com as mesmas garantias do 1.2:
- Push antes, pull depois.
- Cursor de pull = `max(updated_at)` dos `synced` locais (por veículo? não — por user. Veja decisão 1).
- Last-write-wins por `updated_at`.
- Soft delete propaga.
- `sync()` NUNCA lança.

Fora de escopo: orquestrador global (6.D-orchestrator depois).

## Decisões técnicas

### 1. Escopo da chamada: por user (não por veículo)
`fuel_entries` no Supabase tem RLS via `vehicle_id in (select id from vehicles where user_id = auth.uid())`. O cursor `max(updated_at)` é **global por user** (não por veículo) — uma chamada de sync cobre todos os abastecimentos do usuário.
- `listPending(userId)` → todos os pending do user, juntando com `vehicles` localmente pra filtrar por `vehicle.userId == userId`.
- `latestSyncedUpdatedAt(userId)` → max(updated_at) entre fuel_entries synced cujo vehicle pertence ao user.
- `fetchUpdatedSince(userId, since)` → mesmo (PostgREST filtra via RLS automático; o `eq('user_id', ...)` não funciona direto em fuel_entries porque não tem user_id; mas RLS resolve no servidor).

### 2. Arquivos novos
- `lib/data/sync/remote_fuel_entry_source.dart` — `abstract class RemoteFuelEntrySource` + `SupabaseRemoteFuelEntrySource` + `remoteFuelEntrySourceProvider`. Interface:
  ```dart
  Future<void> upsert(FuelEntry entry);
  Future<List<FuelEntry>> fetchUpdatedSince({required String userId, required DateTime? since});
  ```
- `lib/data/sync/fuel_entry_sync_facade.dart` — `abstract class FuelEntrySyncFacade` + `DriftFuelEntrySyncFacade` + `fuelEntrySyncFacadeProvider`. Métodos:
  ```dart
  Future<List<FuelEntry>> listPending(String userId);
  Future<void> markSynced(String id);
  Future<void> upsertFromRemote(FuelEntry remote);
  Future<DateTime?> latestSyncedUpdatedAt(String userId);
  Future<FuelEntry?> getRawById(String id);
  Stream<int> watchPendingCount(String userId);
  ```
  Pra filtrar por user: JOIN com `vehicles` (usar `Drift` query manual ou subquery).
- `lib/data/sync/fuel_entry_sync_service.dart` — `FuelEntrySyncService` (mirror exato de `VehicleSyncService`).

### 3. Filtragem por user via JOIN local
`fuel_entries` não tem `user_id`. Pra listPending de um user, precisa cruzar com `vehicles`. Drift query manual:
```dart
final query = _db.select(_db.fuelEntries).join([
  innerJoin(_db.vehicles, _db.vehicles.id.equalsExp(_db.fuelEntries.vehicleId)),
])..where(_db.vehicles.userId.equals(userId) & _db.fuelEntries.syncStatus.equalsValue(SyncStatus.pending));
```
Mesma técnica em `latestSyncedUpdatedAt`, `watchPendingCount`.

### 4. Cursor global por user
`latestSyncedUpdatedAt(userId)` = max(updated_at) dos fuel_entries synced join vehicles where user_id.

### 5. Supabase upsert: vehicle_id é o link
`SupabaseRemoteFuelEntrySource.upsert(entry)` → `_client.from('fuel_entries').upsert(entry.toJson())`. RLS no servidor garante isolamento.
`fetchUpdatedSince` → `_client.from('fuel_entries').select().gt('updated_at', sinceIso).order('updated_at')`. **Sem `eq('user_id', ...)`** — não existe a coluna; RLS faz o filtro.

## Critérios de aceite (= testes em `test/data/sync/fuel_entry_sync_service_test.dart`)

Espelha **11 testes** do `vehicle_sync_service_test.dart`, adaptados:

1. **push básico**: criar fuel pending → sync → fake recebe; local synced; pushed=1.
2. **push soft-deletado**: cria + softDelete → sync → fake recebe deletedAt; local synced.
3. **push falha parcial**: 3 pendings, 1 falha → 2 pushed, 1 pushFailure.
4. **pull novo do remoto**: fake tem entry novo → sync → local insere como synced; pulled=1.
5. **cursor incremental**: 2º sync recebe `since=primeiro_max_updated_at`.
6. **conflito remote-newer**: remoto T2 > local T1 → local atualiza.
7. **conflito local-newer (guard LWW)**: local T2 > remote T1 (com ignoreSince) → local preserva.
8. **empate updated_at** → local vence (não sobrescreve).
9. **cursor null inicial** quando nada synced.
10. **isolamento por user**: criar fuel pra vehicle de outro user → não aparece em listPending do user atual (via JOIN).
11. **pull falha** → pullError preenchido, push prévio preservado, sem exception.

## Definition of Done
- 11 testes verdes; suíte completa verde (~304); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Sync nunca lança.
- RLS no Supabase já cuida do isolamento remoto (validado no Sprint 0); local cuida via JOIN.

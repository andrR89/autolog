# Spec — Sprint 1.2: SyncService (push pending + pull incremental + last-write-wins)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Fonte: `docs/ARCHITECTURE.md §2` (sync) + Regras de Ouro. Depende de 0.4 (Supabase) e 1.1 (repo de vehicles).

## Escopo
Motor de sincronização para `vehicles` — **único entity wired nesta tarefa**. O design é reutilizável; outras entidades pluga-se à medida que seus features chegam. NÃO entram aqui: UI, indicador de status (1.4), sync das outras tabelas.

## Decisões técnicas

### 1. Cursor de pull = `max(updated_at)` dos `synced` locais
Sem nova tabela, sem `shared_preferences`. O cursor se deriva do próprio banco: o último `updated_at` entre as linhas `synced`. Primeiro sync: cursor = `null` → puxa tudo. Cursor avança só após pull bem-sucedido (automaticamente, porque o que veio do remoto entra como `synced`).

### 2. Camada `RemoteVehicleSource` (abstrai o Supabase, testável)
`lib/data/sync/remote_vehicle_source.dart`:
```dart
abstract class RemoteVehicleSource {
  /// Upsert no remoto (PostgREST upsert por id). Envia o Vehicle COMO ESTÁ
  /// (incluindo deleted_at), preservando updated_at do client.
  Future<void> upsert(Vehicle vehicle);

  /// Lê do remoto os rows do usuário com updated_at > [since].
  /// since == null → tudo. Ordenado por updated_at asc.
  Future<List<Vehicle>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  });
}
```
Impl real `SupabaseRemoteVehicleSource` usa `supabaseClientProvider`. Mapeia `Vehicle` ↔ JSON via `toJson`/`fromJson` (já snake_case, decimal-as-string — 0.3). **Revisada por Haiku, não unit-testada (rede).**

### 3. Fachada sync no repositório (separada da API user-facing)
`lib/data/sync/vehicle_sync_facade.dart` — interface + impl Drift que **bypassam a regra "toda escrita marca pending"**, exclusiva pro SyncService:
```dart
abstract class VehicleSyncFacade {
  /// Todos os pending do usuário (INCLUI soft-deletados — também precisam subir).
  Future<List<Vehicle>> listPending(String userId);

  /// Marca synced sem mexer em updated_at nem em mais nada.
  Future<void> markSynced(String id);

  /// Aplica o row vindo do remoto EXATAMENTE como veio (todos os campos,
  /// incluindo updated_at), e marca como synced. Cria se não existir.
  Future<void> upsertFromRemote(Vehicle remote);

  /// Cursor de pull: max(updated_at) entre os synced do usuário, ou null.
  Future<DateTime?> latestSyncedUpdatedAt(String userId);
}
```
`DriftVehicleSyncFacade` implementa em cima do mesmo `AppDatabase`. **NÃO** estender `VehicleRepository` — manter limpo: a UI (1.3) usa só o repo, sync usa só a fachada.

### 4. `VehicleSyncService`
`lib/data/sync/vehicle_sync_service.dart`:
```dart
class SyncResult {
  final int pushed;          // rows enviados com sucesso
  final int pulled;          // rows aplicados do remoto
  final int pushFailures;    // upserts que falharam
  final Object? pullError;   // null se pull deu ok
}

class VehicleSyncService {
  Future<SyncResult> sync(String userId); // push então pull
}
```
Ordem: **push primeiro** (envia o que é nosso e ainda não subiu), **pull depois** (recebe do servidor). Push e pull são independentes: falha em um não aborta o outro.

### 5. Algoritmo de push
Para cada `Vehicle` em `listPending(userId)`:
- `await remote.upsert(vehicle)` — em sucesso, `facade.markSynced(vehicle.id)` e `pushed++`.
- Em erro de upsert (rede, validação): conta `pushFailures++`, **mantém pending** (será reenviado no próximo sync). Logar/registrar erro mas seguir a próxima.

### 6. Algoritmo de pull com last-write-wins
1. `since = facade.latestSyncedUpdatedAt(userId)`.
2. `remoteRows = await remote.fetchUpdatedSince(userId: userId, since: since)`.
3. Para cada `remoteRow`:
   - Buscar local **incluindo deletados** (precisamos comparar mesmo com soft-deleted):
     - usar leitura crua via AppDatabase (NÃO `repo.getById`, que filtra `deleted_at`).
   - Se local não existe → `upsertFromRemote(remoteRow)` → `pulled++`.
   - Se local existe e `localRow.updated_at >= remoteRow.updated_at` → **mantém local** (não conta como pulled — não houve mudança).
   - Caso contrário (remoto mais novo) → `upsertFromRemote(remoteRow)` → `pulled++`.
4. Empate exato no `updated_at` → local vence (não sobrescreve à toa). Isso é seguro porque qualquer mudança real bumpa o timestamp.

### 7. Erros
- Pull falha (rede) → `pullError != null`, `pulled = 0`. Push pode ter sido ok.
- Push linha-a-linha: erros individuais não abortam; `pushFailures` reflete quantos não foram.
- Nada de exception vazar do `sync()`: sempre retorna `SyncResult`.

### 8. Riverpod providers
- `remoteVehicleSourceProvider` → `SupabaseRemoteVehicleSource(ref.watch(supabaseClientProvider))`.
- `vehicleSyncFacadeProvider` → `DriftVehicleSyncFacade(ref.watch(appDatabaseProvider))`.
- `vehicleSyncServiceProvider` → `VehicleSyncService(facade, remote)`.

## Critérios de aceite (= testes em `test/data/sync/vehicle_sync_service_test.dart`)

Usar `AppDatabase(NativeDatabase.memory())` + real `DriftVehicleRepository` + real `DriftVehicleSyncFacade` + um **`FakeRemoteVehicleSource`** (mapa em memória, configurável pra falhar). Tempo injetado no repo (mesmo padrão da 1.1).

1. **push básico**: criar local pending → `sync()` → fake recebe upsert; local fica `synced`; `pushed=1, pushFailures=0`.
2. **push de soft-deletado**: criar → softDelete → sync → fake recebe o row com `deletedAt != null`; local fica `synced` (e deletado).
3. **push com falha parcial**: 3 pending; fake configurado pra lançar no segundo. Sync → `pushed=2, pushFailures=1`; o que falhou continua pending; os outros viram synced.
4. **pull novo do remoto**: fake tem v1 (que local não conhece) com updated_at T1. Sync → local insere v1 como synced; `pulled=1`. `repo.listByUser` agora retorna v1.
5. **pull com cursor incremental**: T0 < T1 < T2. Primeiro sync: fake tem v1@T1. Local fica synced em T1. Segundo sync: fake agora tem v1@T1 e v2@T2 — chamada de fetch deve receber `since=T1` (verificável no fake). `pulled=1` (só v2).
6. **conflito — remoto mais novo vence**: local v1 synced em T1 (sem alteração local). Remoto v1 atualizado em T2 com nickname diferente. Sync → local v1 vira com nickname remoto e updated_at=T2; permanece synced. `pulled=1`.
7. **conflito — local mais novo vence**: local v1 pending em T2 (usuário editou). Remoto v1 em T1. Sync → push manda local; cursor avança; local fica synced em T2 (não é sobrescrito pelo T1 do remoto). `pushed=1, pulled=0`.
8. **empate de updated_at**: local synced em T1, remoto retorna mesmo updated_at T1. Sync → nada muda. `pulled=0`.
9. **pull com falha de rede**: fake.fetchUpdatedSince lança. Sync → `pullError != null`, `pulled=0`. Push (que veio antes) ainda contabilizado se houve. Nenhuma exception vaza.
10. **isolamento por userId no pull**: fake é chamado com `userId` correto (verificar argumento capturado). Não puxa de outro usuário.
11. **cursor inicial null**: primeiro sync sem nada synced local chama fetch com `since=null`.

## Definition of Done
- 11 testes acima verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- Nenhuma chamada real ao Supabase nos testes (só o fake).
- SyncService NÃO lança exceção — sempre retorna `SyncResult`.
- `VehicleRepository` (API user-facing) NÃO ganhou métodos de sync — fica na fachada separada.
- `SupabaseRemoteVehicleSource` implementado e revisado por Haiku (homologação real fica pro Sprint 1 inteiro, ou quando 1.3 expuser a UI).

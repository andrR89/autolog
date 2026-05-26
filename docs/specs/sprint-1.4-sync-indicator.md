# Spec — Sprint 1.4: Indicador de status de sync na UI

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa; André homologa visualmente.
> Depende de 1.2 (sync engine) + 1.3 (UI de vehicles).

## Escopo
Indicador na AppBar de `VehiclesListScreen` mostrando o estado de sync, e mecanismo mínimo de disparo (auto no boot da tela + manual ao tocar no indicador). **Apenas vehicles** — as outras entidades se ligam quando seus features chegarem.

Fora de escopo: sync periódico em background, detecção real de conectividade (sem `connectivity_plus`), sync das outras entidades.

## Decisões técnicas

### 1. Quatro estados (UI), derivados de fatos observáveis
```dart
enum SyncDisplayStatus { synced, pending, offline, syncing }
```
Derivação a partir de: `pendingCount` (quantos locais aguardam push, incluindo soft-deletados), `lastResult` (último `SyncResult` ou null), `isSyncing` (sync em curso). **Não usa `connectivity_plus`** — "offline" é inferido de falhas reais de sync (rede caiu = upsert/fetch falham).

Função pura `deriveSyncStatus({required int pendingCount, SyncResult? lastResult, required bool isSyncing}) → SyncDisplayStatus`:
- `isSyncing == true` → `syncing` (vence tudo).
- `lastResult != null && (lastResult.pullError != null || lastResult.pushFailures > 0)` → `offline`.
- `pendingCount > 0` → `pending`.
- Caso contrário → `synced`.

> Nota: "offline" aqui é "última tentativa falhou". Quando a rede volta e a próxima sync passa, vira `synced`/`pending` automaticamente.

### 2. Stream de pending count
Adicionar à `VehicleSyncFacade`:
```dart
/// Conta os pending do usuário (inclui soft-deletados). Reativo.
Stream<int> watchPendingCount(String userId);
```
Impl Drift: `selectOnly` com `count(id)` + `where(user_id = ? AND sync_status = 'pending')` + `.watchSingle()`. Sem filtro de `deleted_at`.

### 3. SyncStatusNotifier (Riverpod)
`lib/features/sync/sync_status_notifier.dart` — `class SyncStatusState { SyncDisplayStatus status; SyncResult? lastResult; }`. `class SyncStatusNotifier extends Notifier<SyncStatusState>` que:
- Escuta `watchPendingCount(userId)` e atualiza state.status via `deriveSyncStatus`.
- Expõe `Future<void> triggerSync()` que: marca `isSyncing=true` (recalcula status), chama `sync.sync(userId)`, guarda `lastResult`, `isSyncing=false`. Re-deriva status. Nunca lança.
- `userId` resolvido via `currentUserIdProvider` (já existe em 1.3).

Provider `syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatusState>(...)`.

### 4. Widget indicador
`lib/features/sync/sync_indicator.dart` — `class SyncIndicator extends ConsumerWidget`. Mostra na AppBar:
- `synced` → ícone `Icons.cloud_done` (cor success), tooltip "Sincronizado".
- `pending` → ícone `Icons.cloud_upload`, tooltip "Aguardando sincronizar".
- `offline` → ícone `Icons.cloud_off` (cor warning), tooltip "Sem conexão — toque pra tentar".
- `syncing` → `CircularProgressIndicator` pequeno, tooltip "Sincronizando…".
Tap em qualquer estado (exceto `syncing`) → chama `notifier.triggerSync()`. Durante `syncing`, tap é no-op.

### 5. Auto-trigger
`VehiclesListScreen` no `initState` chama `ref.read(syncStatusProvider.notifier).triggerSync()` uma vez. Ignora erros (são refletidos no estado). Não bloqueia a UI.

### 6. PT-BR sempre.

## Critérios de aceite

**Testes (`test/features/sync/sync_status_test.dart`) — verdes:**

1. `deriveSyncStatus`: `isSyncing=true` retorna `syncing` independente de qualquer coisa.
2. `deriveSyncStatus`: `lastResult.pullError != null` → `offline`.
3. `deriveSyncStatus`: `lastResult.pushFailures > 0` → `offline`.
4. `deriveSyncStatus`: pending=0, sem erro, não syncing → `synced`.
5. `deriveSyncStatus`: pending>0, sem erro, não syncing → `pending`.
6. `deriveSyncStatus`: `lastResult` com pulled/pushed > 0 e SEM erros → continua valendo a regra (pending count manda).

**Testes do notifier (`test/features/sync/sync_status_notifier_test.dart`) — verdes:**

Usar `ProviderContainer` com overrides:
- `currentUserIdProvider` overrideado com `'u1'`.
- `vehicleSyncFacadeProvider` overrideado com fake (`stream controller` pra pendingCount).
- `vehicleSyncServiceProvider` overrideado com fake (`triggerSync` retorna SyncResult configurável).

7. **Inicial**: pendingCount stream emite `0`, notifier resolve para `synced`.
8. **Pending detectado**: stream emite `2` → status vira `pending`.
9. **triggerSync sucesso**: status vai pra `syncing` enquanto roda; ao fim com SyncResult vazio (pushed=0,pulled=0), volta para `synced` (com pendingCount=0) ou `pending` (se ainda há pendentes).
10. **triggerSync com pullError**: status final fica `offline`.
11. **triggerSync com pushFailures**: status final fica `offline`.
12. **triggerSync nunca lança**: mesmo se o fake do sync lançar uma exception (não deveria, mas), o notifier captura e não vaza.

**Deliverables (Haiku + homologação):**
13. Indicador visível na AppBar de Meus veículos; reflete pending após criar/editar/excluir; vira `synced` após sync; cores e tooltips PT-BR.

## Definition of Done
- Testes acima verdes (12); suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Nenhuma nova dependência adicionada.
- Sync trigger nunca bloqueia UI nem lança exception.

# Handoff — Captura do log `[sync]` no web bloqueada (DWDS desconectado)

> Objetivo da rodada: capturar as linhas `[sync] <entidade>: <erro>` no console
> do navegador pra diagnosticar o `cloud_off` (JWT expirado? RLS? schema? config?).
> **Não foi possível capturar** — segue o porquê, com evidência.

## TL;DR
O sync **falha de verdade** no web (toquei no `cloud_off` → virou spinner
"Sincronizando" → voltou pra `cloud_off` vermelho). Mas **nenhuma linha
`[sync]` apareceu no console.** A única coisa logada na tentativa de sync foi,
repetidamente:

```
WebSocketConnectionClosed: Connection Closed
  at PersistentWebSocket._writeToWebSocket$1 (dwds/src/injected/client.js)
  Unhandled error detected in the injected client.js script.
```

Isso é o **DWDS** (canal de debug do `flutter run`) **desconectado**. No build
debug (DDC), os `print()`/`debugPrint()`/`developer.log()` do Dart são
encaminhados pro terminal via esse websocket. Com ele fechado, **os logs de
diagnóstico não chegam ao console do navegador** — a própria tentativa de
enviar o log é o que gera o "WebSocketConnectionClosed".

Conclusão: o JS que está rodando na aba é um **build em cache / sessão antiga**,
e o canal de log Dart→navegador está cortado. Não dá pra capturar `[sync]`
nesse estado.

## Evidência (console, em ordem)
1. Limpei o console (`console.clear()` → entrada `[CLEAR]` confirmada).
2. Toquei no indicador `cloud_off` (canto sup. direito da garagem).
3. UI: ícone virou spinner por ~2s e **voltou pra `cloud_off`** → sync tentou e falhou.
4. Console pós-clear continha **apenas**:
   - 3× `WebSocketConnectionClosed: Connection Closed` (dwds/injected/client.js)
   - 0× `[sync] ...`
   - 0× `PostgrestException` / `AuthException`
   - 0× qualquer `dart.developer.log` ou print do app
5. Observação adicional: ao longo da sessão apareceram `Exeption on identify:
   PlatformException(... 'Null' is not a subtype of 'Object' ...)` de hora em
   hora — é o **PostHog** (analytics no-op no web), **não** relacionado ao sync.

## Por que isso bloqueia o diagnóstico
- Se o log usa `print()`/`debugPrint()`: deveria ir pro console do navegador,
  mas com o DWDS caído o forwarding falha → não aparece.
- Se o log usa `developer.log()`: aparece no meu leitor como
  `dart.developer.log Object` (payload **opaco**, não expande o texto). Não vi
  nem isso nesta rodada — reforça que é build antigo + canal morto.

## Ação pedida (André + Code)
1. **Reiniciar o `flutter run` limpo** (não hot reload):
   - `Ctrl+C` no processo atual.
   - `flutter run -d chrome --dart-define-from-file=dart_define.json --web-port=8080`
   - Esperar compilar **green** no terminal.
2. Avisar o Cowork → eu **recarrego a aba** (devo ver boot novo:
   "Starting application from main method…") e confirmo que é o build com o log.
3. Aí eu: limpo o console → toco no `cloud_off` → capturo `[sync] <entidade>:
   <erro>` no topo, limpo, e colo aqui.

## Recomendações pro log de diagnóstico (pra garantir captura via MCP)
- Usar **`print('[sync] $entity: $error')`** (não `developer.log`) — `print`
  vira `console.log` e o leitor do Chrome MCP lê o texto cru. `developer.log`
  chega como `Object` opaco.
- Incluir no texto: nome da entidade, `error.runtimeType`, e a `message`
  completa (ex.: `PostgrestException(message, code, details, hint)`), pra dar
  pra distinguir JWT expirado vs RLS vs schema vs config numa olhada.
- Logar **antes** do mapeamento pro snackbar genérico (o
  `mapSyncErrorToUserMessage`), senão a causa-raiz some.

## Nota de contexto (não-bug)
O `cloud_off` pode ser esperado neste ambiente local se o `dart_define`/JWT do
`flutter run` estiver apontando pra um Supabase sem sessão válida. O log cru vai
confirmar: se vier `AuthException`/JWT expired, é sessão; se vier
`PostgrestException` 401/42501, é RLS; se 404/42P01, é schema; se erro de
socket/host, é config/URL.

---

## ✅ Atualização (rodada com aba fresca) — captura confirmada, mas SEM `[sync]`
Procedimento executado: fechei a aba de localhost, abri **aba nova** (bootstrap
fresco), app subiu **já logado** (sessão persistida), `cloud_off` presente.

1. **Capture pipeline validado:** emiti `console.log('__CAPTURE_TEST__ ...')` e
   ele **apareceu** no leitor do MCP. Então a captura de console funciona nesta aba.
2. **Sync rodou e falhou de verdade:** toquei no `cloud_off` → ícone virou
   spinner (~2s) → voltou pra `cloud_off` vermelho.
3. **Console após o disparo: ZERO entradas novas.** Nada depois do
   `__CAPTURE_TEST__`. Nenhum `[sync]`, nenhuma `PostgrestException`/`AuthException`,
   nenhum DWDS desta vez.

### Conclusão
Com a captura comprovadamente funcionando, a ausência total de log no caminho de
falha do sync significa que **o build atualmente servido em `localhost:8080` não
contém o print de diagnóstico `[sync]`** (ou o caminho que deveria logar não é
alcançado / não usa `print`).

### Checar (Code)
- O arquivo com o `print('[sync] ...')` foi **salvo** antes do restart?
- O `flutter run` foi **morto e reiniciado** (não hot reload) e compilou **green**?
  Sem isso, o Chrome serve o bundle antigo.
- O `print` está no **catch certo** do ciclo de sync (o mesmo ponto onde o estado
  vira `offline`/`cloud_off`), e **não** atrás de um `if (kDebugMode)` que possa
  estar sendo eliminado, nem com `developer.log` (que chega opaco).
- Alternativa robusta pra este teste: jogar o erro cru também num **elemento no
  DOM** ou em `window.__lastSyncError` (ex.: `window.__lastSyncError =
  '${e.runtimeType} — $e'`), que aí eu leio via JS direto, independente de
  console/DWDS.

---

## ✅ CAUSA-RAIZ ENCONTRADA — schema desatualizado (não é JWT/RLS)
Aba nova, build com o log de diagnóstico ativo. Limpei o console, toquei no
`cloud_off`, e capturei a linha crua:

```
[sync push fail] ReminderSyncService: PostgrestException —
PostgrestException(message: Could not find the 'interval_days' column of
'reminders' in the schema cache, code: PGRST204, details: , hint: null)
```

**Diagnóstico:** `PGRST204` = o PostgREST não acha a coluna **`interval_days`**
na tabela **`reminders`**. O client (web e mobile) já envia essa coluna (recorrência
de lembrete — ver `database.dart`: `interval_km`, `parent_reminder_id`, e o
`interval_days`), mas o **schema remoto do Supabase não tem a coluna** ou o
**schema cache do PostgREST não recarregou**.

Só o **ReminderSyncService** falha no push → derruba o indicador pra `cloud_off`.
As outras entidades (vehicles, fuel, expenses) sincronizam — por isso vimos
`cloud_done` no início da sessão.

### Fix (backend/Code)
1. Aplicar a migration que adiciona `interval_days` (conferir também `interval_km`
   e `parent_reminder_id`) em `reminders` no Supabase **remoto**.
2. Recarregar o cache do PostgREST: `NOTIFY pgrst, 'reload schema';` ou restart da
   API no painel Supabase.
3. Revalidar: tocar no `cloud_off` → deve ir pra `cloud_done` sem erro.

### Observação sobre o log de diagnóstico
O `print('[sync push fail] ...')` **funcionou** e foi capturado via console MCP
(formato `<Service>: <RuntimeType> — <mensagem>`). `window.__lastSyncError` não
foi setado (não precisa). Manter esse print é útil pra depurar sync no web.

---

## ✅ RESOLVIDO (reteste pós-migration)
Aba nova, app logado. Limpei o console e toquei no `cloud_off`:
- Indicador foi pra **`cloud_done`** (nuvem com check).
- Console: **nenhum** `[sync] push fail` (antes vinha o `PGRST204` de `interval_days`).
Migration de `interval_days` em `reminders` + reload do schema do PostgREST
**resolveram o cloud_off**. Sync 100% no web.

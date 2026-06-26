# Handoff — W1: Drift não abre no Web (garagem não carrega pós-login)

**Severidade:** 🔴 Crítico / bloqueante. Web é inutilizável depois do login —
toda a camada de persistência local (Drift WASM) nunca inicializa.
**Plataforma:** só Web (`flutter run -d chrome`, localhost:8080). Mobile não afetado.
**Descoberto:** reteste web 25/06, conta `web.teste.0625@autolog.test`.

## Sintoma observado
1. Login (Supabase auth) funciona → cai em `/#/vehicles`.
2. Banner vermelho do Flutter no topo:
   `Invalid argument(s): When compiling to the web, the` `web` `parameter needs to be set. See also: https://docs.flutter.dev/testing/errors`
3. Garagem mostra o estado de erro: **"Não foi possível carregar sua garagem.
   Verifique sua conexão e tente novamente."** + botão "Tentar novamente"
   (que só re-dispara o mesmo erro).
4. `SyncIndicator` quebra junto.

## Stack trace (console do Chrome)
```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞══
The following ArgumentError was thrown building SyncIndicator(...):
Invalid argument(s): When compiling to the web, the `web` parameter needs to be set.

The relevant error-causing widget was: SyncIndicator
  lib/features/vehicles/vehicles_list_screen.dart:86:17

#3  read   (package:riverpod/src/framework/provider_base.dart:181:28)
#4  watch  (package:flutter_riverpod/src/consumer.dart:565:15)
#5  build  (package:autolog/features/sync/sync_indicator.dart:19:22)
```
O `SyncIndicator` é só o **primeiro** widget a tocar o banco. A causa-raiz não
é o sync — é o `appDatabaseProvider`, lido por toda query de Drift. Qualquer
tela que consulta o banco (garagem inclusive) estoura o mesmo erro.

## Causa-raiz
`lib/data/local/database.dart:125`

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'autolog'));   // ⬅️ sem web:
  ref.onDispose(db.close);
  return db;
});
```

O `driftDatabase()` (do `drift_flutter ^0.2.4`) tem assinatura
`driftDatabase({required String name, DriftNativeOptions? native, DriftWebOptions? web})`.
Quando compilado pra web e chamado **sem** `web:`, ele lança exatamente
`ArgumentError: When compiling to the web, the` `web` `parameter needs to be set`.

O comentário do provider (linhas 119-121) **promete** o caminho web
("Web → WasmDatabase com IndexedDB, sqlite3.wasm do CDN do Drift"), mas o código
nunca foi implementado — o branch web não existe.

**Segundo problema, igualmente bloqueante:** os assets do Drift web **não
existem** no projeto. `web/` só tem `favicon.png`, `icons/`, `index.html`,
`manifest.json`. Faltam `web/sqlite3.wasm` e `web/drift_worker.js`. Mesmo
passando o `web:`, sem esses dois arquivos o banco não abre (404).

Por isso os Blocos 1.1-1.3 (pré-login) passaram: nenhuma query Drift roda antes
do login. O erro só aparece quando a primeira query toca o banco — pós-login.

## Correção sugerida (2 partes, ambas necessárias)

**1. Passar `web:` no `driftDatabase`** (`database.dart:125`):
```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(
    name: 'autolog',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ));
  ref.onDispose(db.close);
  return db;
});
```
(`DriftWebOptions` vem de `package:drift_flutter/drift_flutter.dart`.)

**2. Adicionar os assets web** em `web/`:
- `drift_worker.js`: gerar com `dart run drift_dev make-web-worker`
  (sai em `web/drift_worker.js`).
- `sqlite3.wasm`: baixar o release que casa com a versão do Drift instalada
  (`drift 2.27.0`) em https://github.com/simolus3/sqlite3.dart/releases
  → colocar em `web/sqlite3.wasm`.

Referência oficial: https://drift.simonbinder.eu/web/

## Critério de aceite (revalidação web)
- Login → garagem renderiza sem banner vermelho.
- Console **sem** o `ArgumentError ... web parameter`.
- DevTools → Application → IndexedDB mostra um banco do Drift (`autolog`/`drift_db`).
- Criar veículo → F5 → veículo persiste (Bloco 2.2/2.3).

## Teste de regressão
Não dá pra cobrir o caminho web real num teste de unidade de VM, mas vale:
- Um teste/smoke que garanta que `appDatabaseProvider` é construído com
  `DriftWebOptions` não-nulo quando `kIsWeb` (ou injetar o options e assertar).
- CI: um `flutter build web` que falhe se `web/sqlite3.wasm` /
  `web/drift_worker.js` não existirem.

## Impacto no roteiro web
Bloqueia **Blocos 2 (persistência), 3 (sync), 4 (features), 5 (limitações)** —
todos dependem do banco local. Assim que W1 cair, eu retomo do Bloco 2.

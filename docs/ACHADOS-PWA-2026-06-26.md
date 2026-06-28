# Achados — PWA + Service Worker, 26/06

**Tester:** Claude (Cowork) · **Ambiente:** Chrome (Claude in Chrome MCP), build
**release** servido em http://localhost:8080 · auditoria via JS (manifest, SW,
cache, meta). DevTools (Application/Lighthouse) e instalação nativa = André.

> Veredito: **Bloco 1 (manifest/meta) ✅ perfeito.** **Bloco 2 (Service Worker) ❌**
> — nenhum SW registrado / cache vazio. Causa: build feito com
> **`--pwa-strategy=none`** (SW stub de 784 bytes, sem registro). Blocos 3/4/5
> dependem do SW → bloqueados até rebuildar com a estratégia PWA padrão.

## 🔴 P1 — Service worker não registra (build com `--pwa-strategy=none`)
**Evidência (via JS na página):**
- `navigator.serviceWorker.getRegistrations()` → **0** (após reload normal, não só hard refresh).
- `navigator.serviceWorker.controller` → **null**.
- `caches.keys()` → **[]** (cache storage vazio).
- `fetch('/flutter_service_worker.js')` → 200, **784 bytes** (stub; o SW real de
  release tem RESOURCES e é bem maior).
- `fetch('/main.dart.js')` → 200, **6,77 MB** → confirmado **build release**
  (não é mais DDC debug; `window.$dartRunMain` não existe).

**Causa provável:** o build web foi gerado com **`--pwa-strategy=none`**. Nesse modo
o Flutter emite um `flutter_service_worker.js` vazio e o `flutter_bootstrap.js`
**não chama o registro do SW** — daí manifest OK mas zero SW/cache/offline.

**Fix (Code):**
1. Rebuildar com a estratégia padrão: **`flutter build web`** (default =
   `--pwa-strategy=offline-first`). NÃO passar `--pwa-strategy=none`.
2. Reservir o `build/web` em http://localhost:8080.
3. Avisar → eu revalido Blocos 2 e 3 (e o que der do 5).

**Impacto:** bloqueia Bloco 2 (SW), Bloco 3 (offline), e derruba o score PWA do
Lighthouse (Bloco 5). Instalação (Bloco 4) pode até funcionar só com manifest no
Chrome moderno, mas sem SW não há offline.

## Bloco 1 — Manifest + meta tags ✅
- **1.1 ✅** `document.title` = **"AutoLog"**.
- **1.3 ✅ Manifest** (`/manifest.json`):
  - `name`: "AutoLog — Carro sob controle"; `short_name`: "AutoLog"
  - `lang`: **pt-BR**; `display`: **standalone**; `orientation`: portrait-primary
  - `background_color` / `theme_color`: **#0E1F1A**
  - `categories`: productivity, utilities, lifestyle
  - **4 ícones**: 192 any, 512 any, 192 **maskable**, 512 **maskable** ✅
  - **2 shortcuts**: "Minha garagem" → `./#/vehicles`; "Configurações" → `./#/settings` ✅
- **1.5 meta/head:**
  - `theme-color` = #0E1F1A ✅; `description` PT-BR ✅
  - OG: `og:title` "AutoLog — Carro sob controle", `og:description` PT-BR, `og:image` icons/Icon-512.png ✅
  - `apple-touch-icon` → icons/Icon-192.png ✅
  - `link rel=manifest` presente ✅
  - 🟡 **`<html lang="pt">`** — o roteiro (1.5) esperava **`pt-BR`**. Cosmético
    (o manifest já está pt-BR), mas vale alinhar pra `pt-BR` no index.html.
- **1.2 / 1.4 ⏭️** favicon visual e painel "Installability" do DevTools → você
  confere (não inspecionável via JS). Ícones ainda são placeholder do Flutter
  (pendência conhecida do roteiro).

## Bloco 2 — Service Worker ❌
Ver **P1**. `activated and is running` esperado → **não há SW**. Cache Storage vazio.

## Bloco 3 — Offline ❌ (bloqueado pelo P1)
Sem SW, o reload offline não tem como servir do cache → cairia em tela do Chrome
"sem internet". As **escritas offline-first** (IndexedDB) continuam funcionando
(já validado em rodadas anteriores), mas o **shell do app não carrega offline**
sem service worker. Além disso, alternar "Offline" é no DevTools (não via MCP).
Revalido assim que o SW estiver ativo.

## Bloco 4 — Instalar como app ⏭️ (André)
UI nativa do Chrome (ícone "Instalar", janela standalone, Dock, shortcuts) — não
dirijo pelo MCP. Com o manifest atual o Chrome **pode** oferecer instalar mesmo
sem SW, mas o ideal é testar depois do rebuild com SW.

## Bloco 5 — Lighthouse ⏭️ (André)
Precisa do DevTools → Lighthouse. **Atenção:** sem SW, a categoria PWA vai
reprovar "installable / works offline / registers a service worker". Rodar
**depois** do rebuild com `--pwa-strategy=offline-first` pra ter número real.

## Resumo pro Diretor
1. Manifest/meta: **prontos e corretos** (1 ajuste cosmético: html lang pt → pt-BR).
2. **Bloqueante:** build saiu com `--pwa-strategy=none` → sem service worker.
   Rebuildar com a estratégia padrão e reservir.
3. Offline/install/Lighthouse: revalidar após o SW subir.

---

## ✅ P1 — RESOLVIDO (rebuild com service worker, reteste 27/06)
Após hard refresh no build novo:
- **Bloco 2 ✅ Service Worker:** `getRegistrations()` = **1**, state **activated**,
  script **`sw.js`** (SW custom do Code, não o do Flutter), **controller ativo**.
- **Bloco 2.3 ✅ Cache Storage:** 2 buckets —
  - `autolog-shell-v1-2026-06-27` (11 itens): `/`, `index.html`, `main.dart.js`,
    `flutter.js`, `flutter_bootstrap.js`, `manifest.json`, `favicon.png`,
    `Icon-192/512`, **`sqlite3.wasm`**, **`drift_worker.js`** → shell completo
    incluindo o engine do banco (Drift WASM), essencial pro offline no web.
  - `autolog-assets-v1-2026-06-27` (5 itens): version.json, AssetManifest.bin.json,
    drift_worker.js, sqlite3.wasm, flutter_service_worker.js.
- App **boota e renderiza sob controle do SW** (garagem OK, sync `cloud_done`).

### Bloco 3 — Offline: pré-requisitos ✅ (toggle final = André)
Tudo que o offline precisa está pronto: **SW controlando a página** + **shell e DB
(sqlite3.wasm/drift_worker.js) em cache**. O reload offline real depende de marcar
"Offline" no DevTools (não dá pra alternar via MCP) — mas os pré-requisitos estão
100%. Faz o teste de 1 clique: DevTools → Network → Offline → F5 (deve carregar do
cache, garagem com dados do IndexedDB).

### Ainda pra você
- **Bloco 4 (instalar como app)** e **Bloco 5 (Lighthouse)** — UI nativa/DevTools.
  Agora com SW ativo, o score PWA do Lighthouse deve passar (installable + offline).
- **Cosmético do Bloco 1:** `<html lang="pt">` → idealmente `pt-BR`.

**Veredito:** PWA core (manifest + service worker + cache do shell) **homologado**
do meu lado. Falta só o offline-toggle, install e Lighthouse, que são teus.

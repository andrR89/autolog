// AutoLog — Service Worker próprio (offline-first manual)
//
// Por quê: o `flutter_service_worker.js` gerado pelo Flutter virou apenas
// um stub que se desregistra (deprecated nos releases recentes). Sem um
// SW próprio, não temos cache offline nem instalação como PWA confiável.
//
// Estratégia:
//   1. PRE-CACHE no install: shell mínimo (index.html, manifest, ícones,
//      bootstrap.js, main.dart.js, assets do flutter).
//   2. Cache-first pra assets versionados (CSS, JS com hash, fontes,
//      assets/, canvaskit, drift_worker.js, sqlite3.wasm).
//   3. Network-first pra navegação HTML — pra updates pegarem.
//   4. Fallback ao cache em modo offline.
//
// Bump CACHE_VERSION quando assets mudarem (depois do build, mas antes do
// deploy). Em deploy automatizado, idealmente plugar no CI.

const CACHE_VERSION = 'v9-2026-06-29';
const SHELL_CACHE = `autolog-shell-${CACHE_VERSION}`;
const ASSET_CACHE = `autolog-assets-${CACHE_VERSION}`;

// Arquivos essenciais pra app abrir offline (shell mínimo).
const SHELL_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './favicon.png',
  './flutter_bootstrap.js',
  './main.dart.js',
  './flutter.js',
  './sqlite3.wasm',
  './drift_worker.js',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
];

// --- install: pre-cache do shell ---
self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(SHELL_CACHE);
      // addAll falha se QUALQUER url der erro; usar add individual em loop
      // pra ser resiliente (asset opcional como drift_worker.js pode faltar
      // em dev sem quebrar tudo).
      await Promise.all(
        SHELL_ASSETS.map((url) =>
          cache.add(url).catch((e) => {
            console.warn('[sw] skip cache miss:', url, e?.message ?? e);
          })
        )
      );
      await self.skipWaiting();
    })()
  );
});

// --- activate: limpar caches antigos ---
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();
      await Promise.all(
        names
          .filter(
            (n) =>
              n.startsWith('autolog-') &&
              n !== SHELL_CACHE &&
              n !== ASSET_CACHE
          )
          .map((n) => caches.delete(n))
      );
      await self.clients.claim();
    })()
  );
});

// --- fetch: roteamento ---
self.addEventListener('fetch', (event) => {
  const req = event.request;

  // Pula tudo que não é GET ou que não é mesmo origin
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  // Navegação (HTML) → network-first, cai pro cache se offline
  if (req.mode === 'navigate') {
    event.respondWith(
      (async () => {
        try {
          const fresh = await fetch(req);
          const cache = await caches.open(SHELL_CACHE);
          cache.put(req, fresh.clone());
          return fresh;
        } catch (_) {
          const cached = await caches.match('./index.html');
          return (
            cached ??
            new Response('offline', { status: 503, statusText: 'Offline' })
          );
        }
      })()
    );
    return;
  }

  // Assets → cache-first com revalidação em background (stale-while-revalidate)
  event.respondWith(
    (async () => {
      const cache = await caches.open(ASSET_CACHE);
      const cached = await cache.match(req);
      const fetchAndUpdate = fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            cache.put(req, res.clone());
          }
          return res;
        })
        .catch(() => cached); // se falhar, devolve o cached existente
      return cached ?? fetchAndUpdate;
    })()
  );
});

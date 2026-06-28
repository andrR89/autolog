# Roteiro de Teste — PWA + Service Worker

> Valida o app web como PWA instalável + service worker. Build release
> (não debug) servido em http://localhost:8080. **Diferenças relevantes do
> ambiente DDC anterior:** sem hot reload, build minificado/tree-shaken,
> service worker ativo.
>
> Tempo estimado: **15 min**.

## Setup (1 min)

1. Chrome (idealmente em **aba anônima** pra não brigar com cache da sessão DDC anterior).
2. Abre http://localhost:8080.
3. DevTools (F12) → aba **Application** aberta.

### Como reportar
- **Bloco/passo** + **print** + **comportamento esperado vs observado**.

---

## Bloco 1 — Manifest + meta tags (3 min)

| # | Onde | Esperado |
|---|------|----------|
| 1.1 | Title da aba do navegador | **"AutoLog"** (antes era "autolog" minúsculo) |
| 1.2 | Aba do Chrome | Favicon do app (não é o ícone genérico do Flutter — pode estar genérico ainda até ter asset final, marca como pendente se sim) |
| 1.3 | DevTools → Application → **Manifest** | `name: AutoLog — Carro sob controle`, `lang: pt-BR`, `background_color: #0E1F1A`, `theme_color: #0E1F1A`, `display: standalone`, **4 ícones** (192/512/192-mask/512-mask), **2 shortcuts** (Minha garagem, Configurações) |
| 1.4 | DevTools → Application → **Manifest** → "Installability" | Sem erros vermelhos. Pode ter aviso laranja sobre ícone se for placeholder |
| 1.5 | View source da página (Ctrl+U) | `<html lang="pt-BR">`, meta `description` em PT-BR, `theme-color: #0E1F1A`, OG tags (og:title, og:description, og:image) |

---

## Bloco 2 — Service Worker (3 min)

| # | Onde | Esperado |
|---|------|----------|
| 2.1 | DevTools → Application → **Service Workers** | Status **activated and is running**, source `flutter_service_worker.js` |
| 2.2 | Network tab (com **Disable cache desligado**) → F5 | 2ª e seguintes loads servem JS/CSS do `(ServiceWorker)`, não da rede. Carregamento bem mais rápido |
| 2.3 | DevTools → Application → **Storage** → Cache Storage | Tem entradas tipo `flutter-temp-cache`/`flutter-app-cache` com assets do app |

---

## Bloco 3 — Modo offline (3 min)

| # | Ação | Esperado |
|---|------|----------|
| 3.1 | Carrega o app online uma vez (até a garagem) | OK |
| 3.2 | DevTools → Network → marca "Offline" | Toda rede bloqueada |
| 3.3 | F5 (reload) | App **carrega normalmente** do cache do service worker. Garagem aparece com os dados do IndexedDB |
| 3.4 | Tenta criar um novo veículo offline | Salva instantâneo (offline-first) |
| 3.5 | Toca no `cloud_off` (vai estar vermelho — sem rede) | Snackbar PT-BR amigável ("Sem conexão. Verifique sua internet e tente novamente.") |
| 3.6 | Desliga o "Offline" do DevTools | Sync pode voltar OK (toca no indicador, vira `cloud_done`) |

> ⚠️ Tela branca, "no internet" do Chrome, erro 404 = service worker não está cacheando direito.

---

## Bloco 4 — Instalar como app (PWA install) (3 min)

| # | Ação | Esperado |
|---|------|----------|
| 4.1 | Barra de endereço do Chrome (à direita do ★) | Aparece **ícone "Instalar"** (monitor com seta). Se não aparecer, pode estar no menu ⋮ → "Instalar AutoLog" |
| 4.2 | Clica → confirma "Instalar" | Abre uma **janela standalone** (sem barra de URL, sem favicon do Chrome) com o app |
| 4.3 | Verifica no Dock/Taskbar do sistema | Ícone do AutoLog aparece como aplicativo |
| 4.4 | Botão direito no ícone do Dock/Taskbar | Lista os **2 shortcuts** do manifest (Minha garagem, Configurações). Clicar em algum abre direto no caminho |
| 4.5 | Fecha a janela do PWA + reabre pelo ícone do Dock | Reabre standalone, login persistido |

> Em macOS o ícone de "Instalar" pode ser mais escondido. Procura em chrome://apps depois.

---

## Bloco 5 — Lighthouse audit (5 min)

| # | Ação | Esperado |
|---|------|----------|
| 5.1 | DevTools → aba **Lighthouse** → Mobile → marca apenas "Progressive Web App" → "Analyze page load" | Roda em ~30s |
| 5.2 | Scores PWA | Pelo menos **acima de 70**. Categorias ideais: Installable ✅, PWA Optimized ✅ |
| 5.3 | Avisos vermelhos | Anota TUDO que aparecer (não tenta corrigir, manda na lista) |

Pontos comuns que podem cair:
- **Maskable icons** — se já tem (verifique no manifest) ✓
- **HTTPS** — `localhost` é OK, em prod precisa de HTTPS real
- **Apple touch icon** — apontamos pra Icon-192 ✓
- **Theme color** — definido como `#0E1F1A` ✓

---

## ✅ Encerramento

Manda pro Diretor:
1. Bloco 1.4 (Installability): erros/avisos do Manifest.
2. Bloco 2: service worker ativou? Cache rolling OK?
3. Bloco 3: offline reload funcionou? Lista o que quebrou se quebrou.
4. Bloco 4: instalação como app funcionou? Standalone window OK?
5. Bloco 5: score PWA + lista de avisos do Lighthouse.

### Pendências conhecidas
- **Ícones placeholder do Flutter** (boneco azul). Vão ser trocados pelo brand final junto com splash screen — não bloqueia o PWA mas o Lighthouse pode reclamar de "ícone não condizente com nome".
- **Sem deploy** ainda. URL pública (Vercel/Cloudflare Pages) é o próximo passo depois do PWA homologado.

Bom teste! 📲

# Roteiro de Teste — Responsividade Camadas 1.5 + 2

> Valida 2 mudanças na mesma rodada:
> - **C1.5 (hero + content)**: 5 telas com **hero brand-dark**: hero continua
>   full-width; o conteúdo abaixo agora centraliza em 720px no desktop.
> - **C2 (grid em listas)**: a **Garagem** vira grid 1/2/3 colunas conforme a
>   viewport.
>
> Pré-requisito: Camada 1 já homologada (forms + Settings + chat + paywall).
> Tempo estimado: **20 min**.
>
> Como rodar: `flutter run -d chrome --dart-define-from-file=dart_define.json --web-port=8080`.

## Setup (1 min)

1. Chrome em http://localhost:8080.
2. DevTools (F12) → device toolbar desligado, usa resize da janela.
3. Conta `web.teste.0625@autolog.test` (já logada via IndexedDB).
4. Tem pelo menos **3 veículos cadastrados** pra ver o grid 3 colunas. Se não tiver, cria.

### Como reportar
- **Bloco/passo** + **viewport (px)** + **print** + **comportamento esperado vs observado**.

---

## Bloco 1 — Garagem grid (C2) (5 min)

A Garagem agora muda layout conforme largura: `<600` 1 col, `600-959` 2 col, `≥960` 3 col.

| # | Viewport | Esperado |
|---|---|---|
| 1.1 | Maximizada (~1440px+) | **3 cards de veículo lado a lado**, com espaçamento entre eles. Header "MINHA GARAGEM" no topo, FAB no canto inferior direito |
| 1.2 | Resize pra ~800px | **2 cards lado a lado** |
| 1.3 | Resize pra ~500px | **1 card por linha** (igual ao mobile) |
| 1.4 | Resize muito largo (≥1400px) | Continua 3 colunas centralizadas — sem virar 4+ (limite intencional). Background lateral livre porque `maxWidth=1000px` |
| 1.5 | Cria um 4º veículo | Grid de 3 colunas + 1 carro abaixo na segunda linha. Espaçamento consistente |
| 1.6 | Apaga até sobrar 1 veículo (swipe ou menu) | 1 card só, ocupando largura de **1 coluna** (não estica pra 3 colunas vazias) |
| 1.7 | Empty state (apaga tudo) | "Sua garagem está esperando..." centralizado em ~1000px max |
| 1.8 | Swipe-to-delete (touch ou drag horizontal com mouse) | Continua funcionando em todas as colunas |

> ⚠️ Card esticando até a borda da viewport em ≥1440px = grid não pegou.
> ⚠️ Em < 600px aparece grid 2 colunas em vez de 1 = breakpoint quebrado.

---

## Bloco 2 — Hero brand-dark + conteúdo centralizado (C1.5) (10 min)

Em **cada uma das 5 telas**, em viewport desktop (≥1440px), o hero brand-dark deve continuar full-width e o conteúdo abaixo dele centralizar em ~720px.

| # | Tela | Esperado |
|---|---|---|
| 2.1 | **Detalhe do veículo** (toca num veículo) | Hero brand-dark (nome + km + última métrica) **full-width** (cobre as bordas laterais). Abaixo: cards (Custo/km, Tendência, CO₂, Posto favorito, Viagens) e lista de abastecimentos **centralizados em 720px** com espaço lateral à direita e esquerda |
| 2.2 | Veículo sem abastecimentos | Hero ainda full-width. Empty state "Nenhum abastecimento aqui ainda." centralizado em ~720px |
| 2.3 | **Despesas (lista)** | Hero brand-dark com "GASTO ÚLTIMOS 30 DIAS" full-width. Cards de despesa abaixo centralizados em 720px |
| 2.4 | Despesas empty state | Hero full + "ExpensesEmptyState" centralizado |
| 2.5 | **Lembretes (lista)** | Hero "X pendentes" full-width. Lista de lembretes centralizada em 720px |
| 2.6 | Lembretes empty | Hero full + empty state centralizado |
| 2.7 | **Relatórios** | Hero "Gasto este mês" full-width. RecapBanner (se aparecer) também full-width. Card "Meus postos" + 3 gráficos centralizados em 720px |
| 2.8 | **Documentos** | Sem hero brand-dark nessa (Scaffold simples) — TUDO centralizado em 720px (CNH, Apólices, Multas) |

> ⚠️ Hero apertado a 720px (não full-width) = regressão crítica do design.
> ⚠️ Card de Custo/km esticando até a borda = C1.5 não pegou nessa tela.

---

## Bloco 3 — Mobile estreito (regressão) (2 min)

Em viewport <600 todas as telas devem se comportar como mobile real (largura total).

| # | Tela | Esperado |
|---|---|---|
| 3.1 | Garagem em ~400px | 1 card por linha (mobile, sem margem lateral notável) |
| 3.2 | Detalhe do veículo em ~400px | Hero + cards em coluna única, full-width como antes |
| 3.3 | Lista de despesas em ~400px | Idem |
| 3.4 | Lembretes em ~400px | Idem |
| 3.5 | Relatórios em ~400px | Idem |
| 3.6 | Documentos em ~400px | Idem |

> Se algo ganhou margem lateral em viewport pequeno, é regressão.

---

## Bloco 4 — Telas da Camada 1 (regressão) (3 min)

A Camada 1 (forms + settings + paywall + chat) **não deve ter mudado**.

| # | Tela | Esperado |
|---|---|---|
| 4.1 | Settings | Igual ao da homologação anterior (720px centro) |
| 4.2 | Form de veículo / abastecimento / despesa | 560px centro, save bar full-width |
| 4.3 | Paywall | Conteúdo 720px + footer CTA full-width |
| 4.4 | Login | 560px no AuthScaffold |

---

## ✅ Encerramento

Pro Diretor:
1. Lista de regressões (bloco/passo, viewport, print).
2. Sensação visual em 2-3 linhas (Garagem em 3 colunas dá vontade de ter mais carros? Cards do detalhe respiram melhor agora?).
3. Algum hero que deveria ter ficado constrained (em vez de full-width)?

### Pendências planejadas
- **Camada 3** (master/detail desktop) — refactor profundo, fica pra rodada futura.
- **Grid em Documentos/Lembretes** — extender Camada 2 quando fizer sentido (poucos itens hoje, grid talvez não pague o custo visual).
- **Deploy** público (Vercel/Cloudflare) — depois da homologação responsividade.

Bom teste! 📱💻🖥️

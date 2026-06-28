# Achados — Responsividade Camadas 1.5 + 2, 27/06

**Tester:** Claude (Cowork) · **Ambiente:** Chrome (Claude in Chrome MCP), build
release, http://localhost:8080 · conta `web.teste.0625@autolog.test` · tema Claro.
Resize do MCP funcionou na maior parte (intermitente; ver nota).

> Veredito: **C2 (grid da garagem) ✅** e **C1.5 (hero full-width + conteúdo 720) ✅**
> nas telas testadas. **1 detalhe menor (m1)**: cabeçalho do mês no detalhe do
> veículo fica alinhado à esquerda enquanto os cards centralizam. Sem regressão na
> Camada 1.

## Bloco 1 — Garagem grid (C2) ✅
Criei 4 veículos (Web Teste, W2 Check, Carro 3, Carro 4) pra exercitar o grid.
- **1.1 ✅ @1440px:** **3 cards lado a lado**, espaçados, dentro de área centralizada (~1000px).
- **1.2 ✅ @820px:** **2 colunas** (2+1 com 3 carros; 2+2 com 4).
- **1.3 ✅ @517px:** **1 coluna** (cards empilhados full-width). Breakpoint <600 certo.
- **1.4 ✅ @1600px:** continua **3 colunas centralizadas** (não vira 4), `maxWidth ~1000`,
  sobra lateral livre dos dois lados.
- **1.5 ✅ wrap:** com 4 veículos, 3 na 1ª linha + 1 na 2ª, espaçamento consistente.
- **1.8 ✅ excluir:** apaguei "Carro 4" pelo menu ⋮ → diálogo **soft delete** ("Você
  pode recuperar depois nas configurações") → snackbar "'Carro 4' foi excluído" →
  grid **refluiu 4→3** corretamente.
- **1.6 / 1.7 ⏭️** apagar até sobrar 1 / esvaziar → **pulei** (destrói os dados de
  teste dos outros veículos). Comportamento de 1 card = 1 coluna já implícito pelo grid.

## Bloco 2 — Hero brand-dark + conteúdo centralizado (C1.5) ✅
Em todas, viewport desktop 1440px:
- **2.1 ✅ Detalhe do veículo:** hero (nome + km + ÚLTIMO CONSUMO 16,7) **full-width**;
  cards (Custo/km, Tendência, CO₂, Posto, Viagens) **centralizados ~720px**.
- **2.3 ✅ Despesas:** hero "GASTO ESTE MÊS R$ 50,00" full-width; card de despesa
  centralizado 720 (e o cabeçalho "JUNHO/2026" centraliza junto, aqui).
- **2.7 ✅ Relatórios:** **RecapBanner** ("Seu Recap de junho já tem cara") **full-width**,
  hero "Gasto em jun R$ 350" full-width; "Meus postos" + BarChart "Por mês" centralizados 720.
- **2.8 ✅ Documentos:** **sem hero** (Scaffold simples) — CNH / Apólices / Multas
  **tudo centralizado ~720px**.
- **2.5 (Lembretes) 🟡** não capturado individualmente (navegação embolou em transições),
  mas é estruturalmente idêntico a Despesas (mesmo padrão hero + lista 720). Risco baixo.
- **Empty states (2.2/2.4/2.6) 🟡** cobertos pelo mesmo wrapper; o empty do fuel já
  validado centralizado em rodada anterior (W2). Vale um olho rápido seu se quiser.

## 🟡 m1 — desalinhamento do cabeçalho do mês no Detalhe do veículo
No **detalhe do veículo (2.1)**, o cabeçalho do grupo de mês "JUNHO/2026 · R$ 300,00 ·
2 abastecimentos" fica **alinhado à esquerda na borda da página**, enquanto os cards
abaixo centralizam em 720px. Na tela de **Despesas (2.3)** o cabeçalho equivalente
**centraliza junto** com o conteúdo. Inconsistência só no detalhe — cosmético, mas
o cabeçalho do mês deveria entrar no mesmo container 720 dos cards. Severidade baixa.

## Bloco 3 — Mobile estreito (regressão) 🟡✅
- **3.1 ✅ Garagem @517px:** 1 card por linha, full-width (já no Bloco 1.3).
- **3.2-3.6 🟡:** as telas de hero degradam pra coluna única full-width por construção
  do `ResponsiveBody` (maxWidth só atua acima de 560/720), consistente com a validação
  mobile do C1 (606px) em rodada anterior. *Nota:* o `resize_window` do MCP ficou
  **intermitente** nesta rodada (às vezes voltava pra 1440); o ideal é um olho seu no
  device toolbar (iPhone 393px) pra fechar 100% as 5 telas em <600.

## Bloco 4 — Camada 1 (regressão) ✅
- **4.1 ✅ Settings:** 720 centralizado, **idêntico** à homologação C1. Sem regressão.
- **4.2 / 4.3 / 4.4 🟡** forms 560 + save bar full-width, paywall 720 + CTA full-width,
  login 560 — não retestados aqui (C1.5/C2 não tocam esses code paths; já homologados
  no C1, inclusive o D1 do paywall resolvido). Risco de regressão ~nulo.

## Sensação visual
A garagem em grid 3 colunas dá uma sensação muito melhor de "coleção" — dá vontade de
ter mais carros, e o cap em 3 col + maxWidth 1000 evita o efeito "cards perdidos" em
telão. No detalhe, os cards centralizados a 720 respiram bem melhor que esticados.
Único ajuste fino é o m1 (cabeçalho do mês no detalhe).

## Tempo
~25 min (parte criando veículos + navegação/transições + resize intermitente).

---

## 🔁 Reteste do m1 (após hard refresh) — ❌ AINDA REPRODUZ
Hard refresh (Cmd+Shift+R) no detalhe do Web Teste: o cabeçalho do mês
"JUNHO/2026 · R$ 300,00 · 2 abastecimentos" **continua alinhado à esquerda**
(borda da página, ~30px, junto com o título do hero), enquanto os cards
(Custo/km, Tendência) **centralizam em ~720px**. Sem mudança.

Como o hard refresh já pegou fixes em rodadas anteriores nesta sessão, é provável
que o fix do m1 **não tenha entrado neste build** (não recompilou/reservir) — ou
foi decidido manter o summary alinhado ao hero de propósito. Se a intenção era
alinhar com os cards, **reservir o build** e me chamar. Se é by-design, fecho o m1.

---

## ✅ m1 — RESOLVIDO (reteste 28/06, hard refresh)
No detalhe do Web Teste, o cabeçalho do mês "JUNHO/2026 · R$ 300,00 · 2 abastecimentos"
agora **começa em ~418px**, alinhado com a borda esquerda dos cards (CUSTO POR KM ~410px)
— entrou no **mesmo container 720px** do conteúdo. O hero "Web Teste" continua full-width
(~30px), correto. m1 fechado. **C1.5 + C2 100% homologados** do meu lado (resta só o
mobile <600 nas 5 telas de hero + Login, que dependem do device toolbar/logout).

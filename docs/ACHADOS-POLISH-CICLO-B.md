# Achados — Polish UX Ciclo B (skeletons), 29/06

**Tester:** Claude (Cowork) · **Ambiente:** Chrome (Claude in Chrome MCP), build
release, http://localhost:8080 · conta `web.teste2.0628@autolog.test` · janela 1568px.
Hard refresh confirmou **SW `v9-2026-06-29` ativo** (cache v8 → v9).

> **Veredito:** o fix 🔴 5.1 (skeletons no lugar de `CircularProgressIndicator` solto)
> **passa.** Os 5 skeletons de lista existem e reusam **um único primitivo** do DS
> (`SkeletonListCard`); os 7 loaders inline foram padronizados em **24×24 + strokeWidth 2**.
> **Zero regressão** (Garage/Insights/fuel skeletons + Ciclo A + C1–C3). Skeleton de
> lista **capturado em runtime** (Despesas, tema claro).

> **Nota de método:** o Drift web resolve as listas em ~50ms, então o skeleton "pisca".
> Capturei o primeiro frame por navegação + screenshot imediato. O backbone é **code-verify**
> (estrutura + cores + reuso do primitivo), reforçado pelos frames que consegui pegar.

---

## Bloco 1 — Skeletons dedicados nas listas ✅

As 5 classes dedicadas existem e **todas** delegam ao primitivo `SkeletonListCard`:

| Lista | Classe | Uso do primitivo |
|---|---|---|
| Despesas | `_ExpensesSkeleton` (expenses_list_screen.dart:368) | `SkeletonListCard(showTrailing: true)` ×4 |
| Lembretes | `_RemindersSkeleton` (reminders_list_screen.dart:377) | `SkeletonListCard(showLeadingBox: false)` ×3 |
| Postos | `_StationsSkeleton` (my_stations_screen.dart:111) | `SkeletonListCard(showTrailing: true)` ×3 |
| Viagens | `_TripsSkeleton` (trips_list_screen.dart:196) | `SkeletonListCard()` ×3 |
| Docs pessoais | `_DocsSectionSkeleton` (personal_documents_screen.dart:358) | `SkeletonListCard()` |

**Runtime:** entrei em **Despesas** e peguei o primeiro frame — **cards skeleton**
(box leading + 2 SkeletonLines + linha de trailing de valor) + **eyebrows de mês** em
skeleton. Sem **spinner gigante deslocado**. Confirmado em tema **claro**.

## Bloco 2 — Loaders inline 24×24 + strokeWidth 2 ✅ (code)

Os 7 alvos do roteiro confirmados como `SizedBox(width: 24, height: 24, child:
CircularProgressIndicator(strokeWidth: 2))`:

| # | Tela | Local |
|---|---|---|
| 2.1 | Chat | `chat_screen.dart:240-242` |
| 2.2 | Detalhe de viagem | `trip_detail_screen.dart:101-103` e `111-113` (fuels + expenses) |
| 2.3 | Plano fiscal | `fiscal_plan_screen.dart:307-309` e `335-337` (IPVA + criar lembretes) |
| 2.4 | Plano de manutenção | `maintenance_plan_screen.dart:439-441` |
| 2.5 | Compartilhar veículo | `share_vehicle_screen.dart:314-317` (lista de membros) |
| 2.6 | FIPE search | `fipe_search_sheet.dart:322-324` |
| 2.7 | Sheet de export | `export_card.dart:367-369` |

(Bônus: `generate_pdf_button.dart:122` e `trip_form_screen.dart:287` também já em
strokeWidth 2; o botão "Adicionar" do share usa 18×18 inline — proposital, contexto de botão.)

## Bloco 3 — `SkeletonListCard` é o primitivo único ✅

`lib/core/design/widgets/skeleton.dart:221` define `SkeletonListCard` parametrizado por
`showLeadingBox` (padrão true) e `showTrailing` (padrão false). Estrutura:
- `Container` com `color: context.surfaceRaised` + `border: context.hairline`, radius md;
- leading `SkeletonBox 44×44` (quando `showLeadingBox`);
- `Expanded` com 2 `SkeletonLine` (título h15 + subtítulo w140/h12);
- trailing opcional: `SkeletonLine` w64/h14 + w40/h11 (valor + data).

As 4 listas estruturalmente idênticas (Despesas/Lembretes/Viagens/Postos) **consomem o
mesmo primitivo** — não há reimplementação por arquivo. Lembretes omite o leading box
(`showLeadingBox: false`), Despesas/Postos ligam o trailing — exatamente o previsto.

## Bloco 4 — Light + dark (surfaceRaised + hairline) ✅

**Código:** todos os primitivos de skeleton usam **`context.surfaceRaised` + `context.hairline`**
(dark-aware via `DynamicColors`): `SkeletonBox` (hairline), `SkeletonLine` (hairline),
`SkeletonListCard`/`SkeletonFuelCard`/`SkeletonInsightCard`/`SkeletonKpiCard`
(surfaceRaised + hairline). Não há cor fixa — adapta sozinho aos 2 temas.

**Runtime:** skeleton de Despesas capturado em **claro** (cards num off-white levemente
distinto do surface, linhas sutis). Troquei o tema pra **escuro** (Settings → Aparência →
Escuro) e confirmei que as listas/empty states renderizam corretamente em dark; o primeiro
frame de skeleton que peguei na primeira navegação estava sobre o AppBar dark. Como as
cores vêm das extensions dark-aware, o skeleton acompanha o tema por construção.

## Bloco 5 — Regressão ✅

- **5.1 `_GarageSkeleton`** (vehicles_list_screen.dart:405) — intacto, usado no loading da Garagem.
- **5.2 Insights `_LoadingState`** (insights_screen.dart:366) com `SkeletonInsightCard` ×5;
  `maintenance_plan` também tem `_LoadingState`. Preservados.
- **5.3 `SkeletonFuelCard`** (skeleton.dart:130) usado ×5 no fuel_history — **capturei o
  skeleton do histórico em runtime** ao entrar no detalhe. Preservado.
- **5.4 Ciclo A intacto:** `Semantics(` no chip = 1; `Colors.red` no lib = **0**; snackbars
  `floating` em auth = **5**; `systemUiStyle` dinâmico = 1. Nada regrediu.
- **5.5 C1–C3:** rail desktop + bloco contextual, hero brand-dark full-width, grid garagem,
  forms 560/720 + save bar — tudo intacto ao longo do teste.

> `flutter analyze`/`dart format` não rodam no meu sandbox (sem Flutter no PATH) — fica
> com o Code antes de fechar a tarefa, conforme o fluxo.

---

## Sensação visual
Onde antes piscava um spinner solto, agora aparece a **silhueta da lista** (cards com a
mesma geometria do conteúdo real) — dá impressão de "já está quase lá", mais polido e
rápido, sem o pulo de layout do spinner centralizado. O loader de 24px do chat ficou
discreto sem parecer travado.

## Pendências (próximos ciclos, do roteiro)
- **Ciclo C** — paleta semântica (`Colors.green`/`Colors.amber`), hairline em AppBars
  brand no dark.
- **Ciclo D** — copy ("Settings" → "Configurações" no rail) + a11y; badge "0" em seções.
- 🟢 nice-to-haves → backlog.

> Obs.: deixei o app em **tema escuro** ao fim (troquei pra exercitar o Bloco 4).
> Sessão segue logada em `web.teste2.0628@autolog.test`, SW v9.

---

## 🔁 Reteste runtime (29/06) — mais frames capturados

Segundo passe focado em **pegar os skeletons ao vivo** (a 1ª rodada tinha só o de
Despesas). Truque que funcionou: navegar para uma lista **ainda não visitada na sessão**
e screenshot imediato — o provider passa pelo loading e o skeleton aparece no 1º frame.

Capturei **4 skeletons de lista distintos**, reforçando Bloco 1 e Bloco 4:

| Lista | Tema | O que apareceu |
|---|---|---|
| **Despesas** | claro | 3-4 `SkeletonListCard` (box + 2 linhas + trailing) + eyebrows de mês |
| **Postos** (`/stations`) | **escuro** | 3 cards `_StationsSkeleton` (box + 2 linhas + trailing), cinza dark sutil sobre o fundo quase-preto |
| **Documentos** (`/personal-documents`) | **escuro** | seções Apólices + Multas com `_DocsSectionSkeleton` (2 cards cada); CNH já carregada |
| **Fuel history** (detalhe) | escuro | `SkeletonFuelCard` (regressão 5.3, preservado) |

**Bloco 4 reforçado:** em **dark** os cards skeleton ficam num cinza levemente **mais
claro** que o fundo e as linhas um tom acima — **visíveis, não somem** (confirma
`context.surfaceRaised`/`context.hairline` dark-aware). Em **claro**, cinza levemente mais
escuro que o off-white. Sem cor fixa vazando em nenhum tema.

**Lembretes** (`_RemindersSkeleton`, sem leading box) e **Viagens** (`_TripsSkeleton`) não
foram capturados ao vivo (lista do Civic já cacheada / rota de viagens não exercitada),
mas usam o **mesmo primitivo** `SkeletonListCard` já confirmado por código — Lembretes com
`showLeadingBox: false`, exatamente como o roteiro descreve.

**Veredito mantido:** fix dos skeletons **aprovado**, agora com evidência visual em 4 listas
nos 2 temas. Zero regressão.

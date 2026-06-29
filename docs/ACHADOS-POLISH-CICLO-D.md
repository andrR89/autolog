# Achados — Polish UX Ciclo D (copy + a11y + estados), 29/06

**Tester:** Claude (Cowork) · **Ambiente:** Chrome (Claude in Chrome MCP), build
release, http://localhost:8080 · janela 1568px. Hard refresh confirmou **SW
`v11-2026-06-29`** (shell v11 ativo).

> **Veredito:** os 7 achados 🟡 de copy + a11y + estados **passam por code-verify.**
> **Zero regressão** (Ciclos A+B+C + C1–C3). Como o Ciclo D é majoritariamente copy,
> lógica de badge, error-state e Semantics, o **code-verify é o método correto** —
> reforçado pela impossibilidade de inspecionar ARIA via JS no Flutter Web (CanvasKit só
> popula o DOM de a11y com leitor de tela real).
>
> ⚠️ **Runtime visual pendente:** a sessão está **deslogada** (fim do Ciclo C) e eu não
> digito senha. Paywall/Insights/rail/fuel são todos gated por auth (o /paywall redireciona
> pra /login deslogado). Posso rodar os visuais assim que você re-logar
> (`web.teste2.0628@autolog.test`, senha em CREDENCIAIS-TESTE-WEB.md).

---

## Bloco 1 — Rail "Configurações" + Expanded/ellipsis ✅ (code)

`adaptive_shell.dart:154` — `_RailNavItem(label: 'Configurações', icon: settings_outlined,
route: '/settings', ...)`. Era "Settings". O label vai dentro de
`Expanded(child: Text(label, overflow: TextOverflow.ellipsis))` (`:220-224`) — não estoura
os 240px do rail nem empurra layout; trunca com reticências se faltar espaço (em PT-BR
"Configurações" cabe numa linha no rail de 240px).

## Bloco 2 — Badge "0" sumiu nas seções navegacionais ✅ (code)

`_SectionHeader({required this.label, this.count})` com `final int? count;`
(`insights_screen.dart:657-661`). O badge só renderiza **`if (count != null)`** (`:682`).
- **MANUTENÇÃO** (`:606`), **FISCAL** (`:615`), **ASSISTENTE** (`:624`) →
  `_SectionHeader(label: '...')` **sem count** → null → **sem badge**.
- **PADRÕES DETECTADOS** (`:553-555`) → `count: result.patterns.length` (count real).
- **LEMBRETES SUGERIDOS** (`:578-580`) → `count: visibleProposed.length` (count real).

Ou seja: seções de navegação perdem o "0" falso; seções com contagem real mantêm o número.

## Bloco 3 — `_ErrorState` distinto do `_EmptyState` ✅ (code)

`insights_screen.dart`:
- Dispatch: `_ScreenState.genericError => _ErrorState(onRetry: _analyze)` (`:230`) — branch
  próprio, separado do empty/initial.
- `_ErrorState` (`:365`) renderiza `Icon(Icons.warning_amber_rounded)` (`:390`), título
  **"Algo deu errado na análise"** (`:397`), e `FilledButton.tonal` (`:414`) com
  **"Tentar novamente"** (`:416`) chamando `onRetry`.
- `_EmptyState` **continua existindo** (3 refs no arquivo) — só o branch de erro foi trocado,
  o estado inicial é preservado (Bloco 6.5).

## Bloco 4 — Copy ✅ (code)

- **Fuel triplet** (`fuel_entry_form_screen.dart:422`):
  *"Faltam pelo menos 2 dos 3 campos: litros, preço/litro e total."*
- **Paywall CTA** (`paywall_screen.dart:184`):
  `_kBillingEnabled ? 'Assinar' : 'Assinar (em breve)'` — com billing off, mostra
  **"Assinar (em breve)"**. O snackbar explicativo do tap segue preservado.

## Bloco 5 — A11Y: Semantics + ExcludeSemantics ✅ (code)

Flutter Web (CanvasKit) não expõe o ARIA via JS sem leitor de tela ativo, então valido por
código (mesmo método aceito no Ciclo A / task #49). Os 3 widgets:

- **`_PlanCard`** (`paywall_screen.dart:319-322`): `Semantics(button: true,
  label: 'Plano $label, $price', selected: selected)`. O check interno (`_RadioMark`,
  `:426-429`) é `ExcludeSemantics(Icon(Icons.check))` → o pai anuncia "selecionado", o check
  **não duplica** a leitura.
- **`_ToggleChip`** (`co2/widgets/co2_card.dart:263-282`): `Semantics(button: true,
  selected: selected, label: '$label, selecionado/não selecionado')` + `ExcludeSemantics`
  no Text interno.
- **`_Tab`** (Comparar período, `period_compare_screen.dart:226-249`): mesmo padrão —
  `Semantics(button, selected, label)` + `ExcludeSemantics` no Text.

Resultado esperado no leitor: cada um anuncia "botão, selecionado/não selecionado" + label,
sem leitura duplicada do texto/ícone interno.

## Bloco 6 — Regressão ✅ (code)

- **Ciclo A:** `Colors.red`=0; `floating` auth=5.
- **Ciclo B:** `SkeletonListCard` em uso=14; `strokeWidth: 2`=28.
- **Ciclo C:** `Colors.green`=0; AppBar hairline `PreferredSize`=4 (Insights/Chat/Reports/Paywall).
- **Ciclo D:** `_EmptyState` do Insights preservado (3 refs) — só o branch de erro trocado.
- **C1–C3:** rail/hero/grid/forms — sem alteração estrutural.

---

## Pendências (próximos ciclos, do roteiro)
- **Ciclo E — Forms + AppBars:** validation triplet do fuel, `_TechnicalSpecsSection`
  eyebrow, `autovalidate` prematuro, AppBars 18px vs `titleLarge`, `maxLength` em stationName.
- **Ciclo F — Cards/tokens finos:** `_ActionLinkCard`, `BorderRadius.circular(6)` fora do
  token, micro-spacing sem token (🟢).
- **Runtime visual deste ciclo** (rail "Configurações", `_ErrorState` via Network Offline,
  paywall "Assinar (em breve)", chips/abas) — **roda assim que você re-logar**; me avisa.

> Obs.: app **deslogado**, tema **escuro**, SW **v11**.

---

## 🔁 Reteste runtime (logado, 29/06) — visuais confirmados

Depois que o André re-logou, rodei os visuais que faltavam (janela 1470px, tema escuro):

- **Bloco 1 ✅** — o rail mostra **"Configurações"** no rodapé, sem truncar nem estourar os 240px.
- **Bloco 3 ✅** — forcei o erro interceptando o `fetch` da análise (= Network Offline) e
  cliquei "Analisar agora": apareceu o **`_ErrorState`** com ícone **⚠️ warning_amber_rounded**,
  título **"Algo deu errado na análise"**, sub-texto "Tente novamente em alguns segundos." e
  botão **"Tentar novamente"** — visualmente distinto do empty state inicial. **3.2:** restaurei
  o fetch, cliquei "Tentar novamente" → re-disparou a análise e foi pro resultado (recuperou).
- **Bloco 4.1 ✅** — no fuel form, com só **Litros** (e odômetro preenchido pra passar do
  required), o Salvar mostrou o snackbar exato: **"Faltam pelo menos 2 dos 3 campos: litros,
  preço/litro e total."**
- **Bloco 4.2 ✅** — paywall com CTA **"Assinar (em breve)"**.
- **Bloco 2 ✅ (parcial) + 🟡 observação** — na tela de resultado, **MANUTENÇÃO / FISCAL /
  ASSISTENTE** aparecem **sem badge** (só o label) — o fix das seções de navegação pegou.

### 🟡 Observação (Bloco 2) — badge "0" em seções de *contagem* quando count = 0
Com a conta de teste sem dados, as seções de **contagem** (PADRÕES DETECTADOS e
**LEMBRETES SUGERIDOS**) renderizam **"0"** ao lado do label (ex.: "LEMBRETES SUGERIDOS  0"),
porque o `_SectionHeader` mostra o badge em `if (count != null)` — e `count = 0` não é null.
As 3 seções de navegação foram corrigidas (badge nunca aparece), mas as de contagem ainda
exibem "0" no caso vazio. O roteiro (2.4/2.5) só testou o caso `count > 0`, então é um edge
case não coberto. **Decisão sua:** ou é by-design (é uma contagem real = 0), ou trocar a
condição pra `count != null && count > 0` pra também sumir o "0" nessas seções. Não é
regressão — é um polimento opcional.

**Veredito Ciclo D:** todos os 6 blocos **aprovados** (code + runtime). Uma observação 🟡
menor no Bloco 2 (badge "0" em seções de contagem vazias) pra sua decisão.

---

## ✅ Reteste da observação 🟡 do Bloco 2 — badge "0" RESOLVIDO (build v12)

O Code aplicou o ajuste: `_SectionHeader` agora renderiza o badge em
**`if (count != null && count! > 0)`** (`insights_screen.dart:685`), com comentário
"Esconde o badge também quando o count é zero — '0 itens' gera ruído".

**Runtime (SW `v12-2026-06-29`, logado, dark):** rodei "Analisar agora" de novo —
**LEMBRETES SUGERIDOS** agora aparece **só com o label, sem o "0"** (antes mostrava
"LEMBRETES SUGERIDOS  0"). PADRÕES DETECTADOS usa o mesmo `_SectionHeader`/condição, então
com 0 padrões também não exibe badge. As 3 seções de navegação (MANUTENÇÃO/FISCAL/ASSISTENTE)
seguem sem badge. **Todos os headers limpos do "0".** Observação fechada.

**Ciclo D 100% homologado** do meu lado — 6 blocos + a observação do badge resolvida.

# Roteiro de Teste — Polish UX Ciclo D (29/06)

> Valida **7 achados 🟡 de copy + a11y + estados** da auditoria UX
> (`docs/AUDITORIA-UX-2026-06-28.md`). Foco: PT-BR consistente, error
> states diferenciados, Semantics em mais chips.
>
> Tempo estimado: **8-10 min**. Build em `http://localhost:8080`, SW
> `v11-2026-06-29`. Hard refresh + esperar SW ativar.

## Setup (1 min)

1. Janela normal do Chrome em http://localhost:8080.
2. DevTools (F12) → Application → Service Workers → confirmar
   **`v11-2026-06-29`** ativo.
3. Conta `web.teste2.0628@autolog.test` (senha em
   `docs/CREDENCIAIS-TESTE-WEB.md`). Logar se estiver deslogado.
4. Civic cadastrado (qualquer veículo com 0+ abastecimentos vale).
5. Tema **claro** pra começar; em alguns blocos troca.

### Como reportar
- **Bloco/passo** + **viewport (px)** + **tema** + **print** + **comportamento
  esperado vs observado**.

---

## Bloco 1 — Rail desktop: "Configurações" + ajuste do item (1 min)

| # | Onde | Esperado |
|---|---|---|
| 1.1 | Em viewport ≥1024px, NavigationRail à esquerda → item do rodapé | Label **"Configurações"** (não mais "Settings") |
| 1.2 | Hover/tap no item "Configurações" | Navega pra `/settings`; rail destaca o item |
| 1.3 | Largura do rail | Rail continua **240px** — sem overflow visual. O texto "Configurações" (mais longo que "Settings") ganhou `Expanded + ellipsis`; não deve cortar nem empurrar layout |
| 1.4 | Em viewport <1024px | Nenhuma mudança no comportamento mobile — rail some, AppBar mantém ícones globais |

> ⚠️ Texto cortado no meio = ellipsis pegou mas o item ficou apertado.
> Reportar. ⚠️ Layout do rail "estourando" 240px = ajuste de Expanded
> não pegou.

---

## Bloco 2 — Insights: badge "0" sumiu nas seções navegacionais (2 min)

Antes: 3 seções (MANUTENÇÃO, FISCAL, ASSISTENTE) sempre exibiam badge "0"
ao lado do título — comunicava "0 itens" quando na verdade são links de
navegação, sem contagem.

| # | Onde | Esperado |
|---|---|---|
| 2.1 | Civic → menu ⋮ → Insights (se conta tem cota e há dados) → role até **MANUTENÇÃO** | Apenas o label "MANUTENÇÃO" — **sem badge** "0" ao lado |
| 2.2 | Mesma tela, role até **FISCAL** | Apenas label, sem badge |
| 2.3 | Mesma tela, role até **ASSISTENTE** | Apenas label, sem badge |
| 2.4 | Mesma tela, role até **PADRÕES DETECTADOS** (ou similar com contagem real) | Badge **com número real** (ex.: "3") — não some quando há contagem |
| 2.5 | Mesma tela, **LEMBRETES SUGERIDOS** (se aparecer) | Idem — badge mantido quando count > 0 |

> ⚠️ Badge "0" ainda visível = `count:` não foi trocado pra `null`.
> ⚠️ Badge real (com número > 0) sumiu = `int?` quebrou a lógica.

---

## Bloco 3 — Insights: estado de erro com personalidade (2 min)

Antes: erro genérico de análise renderizava o mesmo `_EmptyState` que o
estado inicial — sem feedback claro de que algo falhou. Agora tem
`_ErrorState` próprio (ícone warning + headline + CTA "Tentar novamente").

| # | Como forçar | Esperado |
|---|---|---|
| 3.1 | DevTools → Network → **Offline** → vá pra Insights → toca "Analisar agora" | Após falha, tela mostra `_ErrorState`: ícone **warning_amber_rounded**, título **"Algo deu errado na análise"**, sub-texto "Tente novamente em alguns segundos.", botão **FilledButton.tonal "Tentar novamente"** |
| 3.2 | Voltar Network pra **Online** → toca "Tentar novamente" | Re-dispara análise; se cota disponível, segue fluxo normal de loading + resultado |
| 3.3 | Inspecionar HTML do `_ErrorState` | Estrutura distinta do `_EmptyState` (mensagem diferente, ícone diferente, CTA `FilledButton.tonal`) |

> ⚠️ Tela após erro mostra a mesma copy de "Analisar agora" do empty
> state inicial = `_ErrorState` não substituiu o branch. ⚠️ Ícone errado
> ou copy "Sem dados ainda" = veio do empty state, não do error.

---

## Bloco 4 — Copy: "Faltam" no fuel form + "Assinar (em breve)" no paywall (2 min)

| # | Onde | Esperado |
|---|---|---|
| 4.1 | Civic → FAB "Novo abastecimento" → preencher **apenas 1 dos 3 campos** (só litros, ou só preço, ou só total) → tocar Salvar | Snackbar: **"Faltam pelo menos 2 dos 3 campos: litros, preço/litro e total."** (não mais "Preencha ao menos 2 dos 3 campos...") |
| 4.2 | Settings → CTA "Virar Premium" → tela Paywall (com `BILLING_ENABLED=false`) | Botão CTA do plano com label **"Assinar (em breve)"** (não mais só "Em breve") |
| 4.3 | Tocar no botão "Assinar (em breve)" | Snackbar explicativo: "Pagamentos chegam na próxima atualização..." (preservado) |

> ⚠️ Copy antiga em qualquer um = fix de string não pegou.

---

## Bloco 5 — A11Y: Semantics em chips e RadioMark (2 min)

Validar via **inspeção HTML** (Flutter Web traduz Semantics em ARIA).
Cobre 3 widgets do Ciclo D.

| # | Onde | Como testar | Esperado |
|---|---|---|---|
| 5.1 | Paywall → cards de plano (`_PlanCard`) com `_RadioMark` (check ✓) | DevTools → Elements → procurar o `<flt-semantics>` do check interno | `aria-hidden="true"` ou ausência de role/label — o `Icon(Icons.check)` agora está em `ExcludeSemantics` (`_PlanCard` pai já anuncia `selected`) |
| 5.2 | Civic → menu ⋮ → Insights → seção CO₂ → toggles de filtro de categoria (`_ToggleChip`) | Inspecionar um chip de filtro | Elemento tem `role="button"` + `aria-selected` (true/false) + `aria-label="<categoria>, selecionado/não selecionado"` |
| 5.3 | Civic → Relatórios → "Comparar período" → abas Mês/Ano (`_Tab`) | Inspecionar cada aba | `role="button"` + `aria-selected` + label correto |
| 5.4 | Com VoiceOver (macOS Cmd+F5), navegar pelos 3 widgets acima | Leitor anuncia cada um como botão selecionável | Leitura sem duplicação (`ExcludeSemantics` no texto interno) |

> ⚠️ Se o screen reader ler "check check" 2x em `_PlanCard` = `ExcludeSemantics` não cobriu. ⚠️ Chips/abas sem `aria-selected` = Semantics novo não pegou.

---

## Bloco 6 — Regressão (1 min)

| # | Onde | Esperado |
|---|---|---|
| 6.1 | Ciclo A (status bar, danger, snackbars, chip Semantics) | Intacto |
| 6.2 | Ciclo B (SkeletonListCard + sizing 24px) | Intacto |
| 6.3 | Ciclo C (paleta dark-aware, hairline nas AppBars brand) | Intacto |
| 6.4 | C1/C1.5/C2/C3 (responsividade) | Intacto |
| 6.5 | Insights — estado vazio inicial (`_EmptyState`) | Continua funcionando como antes; só o branch de erro foi trocado |

---

## ✅ Encerramento

Pro Diretor:
1. Lista de regressões (bloco/passo, viewport, tema, print).
2. Sensação visual em 1-2 linhas: "Configurações" no rail ficou natural?
   `_ErrorState` ficou suficientemente distinto do empty state?
3. Algum chip que ainda parece "morto" pra screen reader (escapou do
   varredor)?

### Pendências planejadas (próximos ciclos)
- **Ciclo E — Forms + AppBars**: validation triplet do fuel form,
  `_TechnicalSpecsSection` sem eyebrow consistente, `autovalidate`
  prematuro, AppBars 18px vs `titleLarge` (Insights/Chat/Reports),
  `maxLength` em stationName — ~5-6 achados 🟡.
- **Ciclo F — Cards e tokens finos**: refactor `_ActionLinkCard` do
  Insights, `BorderRadius.circular(6)` fora do token, `SizedBox(height:
  2)` micro-spacing sem token — achados 🟢 do doc original.
- **Sprint 8.6** deploy público + **Sprint 7.4** ícone/splash — fora do
  polish.

Bom teste! 💬♿

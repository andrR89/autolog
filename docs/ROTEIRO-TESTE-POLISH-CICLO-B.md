# Roteiro de Teste — Polish UX Ciclo B (29/06)

> Valida o **fix 🔴 5.1 da auditoria UX** (`docs/AUDITORIA-UX-2026-06-28.md`):
> substituir `CircularProgressIndicator()` solto por skeletons em **18 pontos**.
>
> Estratégia em 2 níveis:
> - **A** — 5 telas de **lista** ganharam skeleton dedicado (Despesas, Lembretes,
>   Viagens, Postos, Docs pessoais), reutilizando um novo primitivo do DS:
>   **`SkeletonListCard`** em `lib/core/design/widgets/skeleton.dart`.
> - **B** — 7 telas/sheets com loaders **inline** ganharam sizing padronizado
>   `SizedBox 24×24 + strokeWidth 2` (chat, detalhe de viagem, planos fiscal/manutenção,
>   compartilhamento, FIPE search, sheet de export).
>
> Tempo estimado: **8-10 min**. Build servindo em `http://localhost:8080`,
> SW `v9-2026-06-29`. Hard refresh + esperar SW ativar antes de começar.

## Setup (1 min)

1. Janela normal do Chrome em http://localhost:8080.
2. DevTools (F12) → Application → Service Workers → confirmar **`v9-2026-06-29`** ativo.
   Se ainda em v8, hard refresh (Cmd+Shift+R) até trocar.
3. Conta `web.teste2.0628@autolog.test` (já logada).
4. **Truque pra observar loading**: como o Drift web é rápido, o skeleton some
   em ~50ms. Pra dar tempo de observar, ativa **Network throttling** em DevTools →
   Network → "Slow 3G" (não afeta o Drift mas atrasa fetches de avatar/FIPE/edge functions
   e dá ritmo de loading mais lento ao geral). Alternativa: **abrir a tela e olhar
   o primeiro frame** — o skeleton aparece, mesmo que rapidíssimo.
5. Tenha pelo menos **1 despesa**, **1 lembrete** e **1 abastecimento** no Civic
   pra exercitar as listas. (Se não tiver, cria.)

### Como reportar
- **Bloco/passo** + **viewport (px)** + **tema** + **print** + **comportamento
  esperado vs observado**.

---

## Bloco 1 — Skeletons dedicados nas listas (4 min)

Em vez do `CircularProgressIndicator()` solto (36px, deslocado), as listas agora
mostram **3-4 cards skeleton** alinhados com o conteúdo real que vai aparecer.

Pra observar: entra na tela, e na **primeira fração de segundo** antes do conteúdo
carregar, vê o skeleton. Se for muito rápido, ative Slow 3G e force `Cmd+R`.

| # | Tela | Como entrar | Esperado (loading state) |
|---|---|---|---|
| 1.1 | **Despesas** | Civic → bloco contextual → Despesas | 3-4 cards skeleton (`_ExpensesSkeleton`) com leading box + 2 SkeletonLines + trailing line de valor. Eyebrows de mês também em skeleton |
| 1.2 | **Lembretes** | Civic → bloco contextual → Lembretes | 3 cards skeleton (`_RemindersSkeleton`) — título + due, sem leading box (lembretes não têm ícone fixo nessa região) |
| 1.3 | **Postos** (Relatórios → "Meus postos") | Civic → Relatórios → card Meus postos | 3 cards skeleton (`_StationsSkeleton`) com logo skeleton + nome + estatística |
| 1.4 | **Viagens** (se houver acesso) | Civic → menu ⋮ ou rota direta `/vehicles/<id>/trips` | 3 cards skeleton (`_TripsSkeleton`) |
| 1.5 | **Documentos pessoais** (CNH/Apólices/Multas) | Rail → Documentos | Cada seção (CNH/Apólices/Multas) carrega com seu `_DocsSectionSkeleton` (1-2 cards conforme a seção) |

> ⚠️ **Spinner gigante deslocado** = skeleton não pegou (regressão crítica).
>
> ⚠️ Cores do skeleton devem usar **`context.surfaceRaised` / `context.hairline`** —
> testar em **dark** e **light** confirma. Em dark, o skeleton fica num cinza levemente
> mais claro que o fundo; em light, num cinza off-white levemente mais escuro que o surface.

---

## Bloco 2 — Loaders inline com sizing padronizado (2 min)

Onde criar skeleton seria over-engineering (loaders curtos, transientes, em sheets/
contextos parciais), o `CircularProgressIndicator()` ficou em `SizedBox 24×24 +
strokeWidth 2` — consistente, menor, sem ocupar espaço visual desproporcional.

| # | Onde | Como entrar | Esperado |
|---|---|---|---|
| 2.1 | **Chat com assistente IA** | Civic → menu ⋮ → Insights → Chat com assistente | Ao enviar pergunta, indicador "digitando" é spinner pequeno (24px) — não o gigante de antes |
| 2.2 | **Detalhe de viagem** | Civic → viagens → toca em uma viagem | Spinners de fuels + expenses são pequenos (24px) em vez de gigantes |
| 2.3 | **Plano fiscal** | Civic → menu ⋮ → Insights → Lembretes Fiscais | Loaders de "buscar IPVA" e "criar lembretes" usam o tamanho pequeno |
| 2.4 | **Plano de manutenção** | Civic → menu ⋮ → Insights → Plano de manutenção | Loader principal `_LoadingState` em 24px centralizado |
| 2.5 | **Compartilhar veículo** | Civic → menu ⋮ → Compartilhar | Loader de "lista de membros" em 24px |
| 2.6 | **FIPE search** | Form de veículo → "Marca" → busca | Loader do bottom sheet em 24px |
| 2.7 | **Sheet de export** | Settings → Exportar dados → escolhe veículo + período → Gerar | Loader do bottom sheet enquanto gera em 24px |

> ⚠️ Spinner cobrindo metade da tela = sizing não pegou. Esperado: indicador
> sutil, menor.

---

## Bloco 3 — DS coerente: `SkeletonListCard` (1 min)

Verificação de **arquitetura** — não visual: que o novo primitivo
`SkeletonListCard` em `lib/core/design/widgets/skeleton.dart` é usado pelas 4
listas estruturalmente idênticas (Despesas, Lembretes, Viagens, Postos), e
**não** foi reinventado em cada arquivo.

| # | Como verificar | Esperado |
|---|---|---|
| 3.1 | Inspeção do skeleton em Despesas + Postos lado a lado (abrir as duas em abas/janelas) | Estrutura visual idêntica — leading box (40px), 2 SkeletonLines (~70%, ~40%), trailing line opcional. Mesmo ritmo, mesma cor. |
| 3.2 | Inspeção do skeleton em Lembretes vs Viagens | Mesma estrutura base; Lembretes pode omitir o leading box (não tem ícone fixo na região) e Viagens pode ter pequenas variações de proporção — aceitável |

> O objetivo: skeleton fica visualmente **consistente** entre as listas, dando
> impressão de um único sistema (e não 4 implementações diferentes).

---

## Bloco 4 — Light + dark (1 min)

Os skeletons usam `context.surfaceRaised` + `context.hairline`. Tem que funcionar
nos 2 temas sem ajuste.

| # | Tema | Esperado |
|---|---|---|
| 4.1 | **Claro** | Cards skeleton com fundo levemente mais escuro que o surface off-white. SkeletonLines em cinza muito sutil, animação pulse visível. |
| 4.2 | **Escuro** | Cards skeleton com fundo levemente mais claro que o surface escuro. SkeletonLines em cinza sutil. Pulse visível. |
| 4.3 | Loaders inline (Bloco 2) nos 2 temas | Spinner 24px com cor do tema (`onSurface`), legível em ambos |

> ⚠️ Skeleton invisível em algum tema = cor fixa (vazou DS). Reportar.

---

## Bloco 5 — Regressão (1 min)

| # | Onde | Esperado |
|---|---|---|
| 5.1 | Garagem (`_GarageSkeleton` existente — Ciclo 0) | Continua funcionando como antes — não foi tocado |
| 5.2 | Insights (`_LoadingState` existente) | Idem — skeletons de KpiCard/InsightCard preservados |
| 5.3 | Fuel history skeleton (existente do polish-3) | Preservado |
| 5.4 | Polish UX Ciclo A (status bar dinâmica, AppColors.danger, snackbars floating, Semantics chip) | Tudo intacto — Ciclo B só toca em loading states |
| 5.5 | C1/C1.5/C2/C3 (responsividade) | Tudo intacto |

---

## ✅ Encerramento

Pro Diretor:
1. Lista de regressões (bloco/passo, viewport, tema, print).
2. Sensação visual em 1-2 linhas: o app passou a parecer "mais rápido" / "mais polido"
   por ter skeleton onde antes era spinner gigante? Algum skeleton ficou meio fraco
   (poucas linhas, não comunica estrutura)?
3. Algum loader que ficou pequeno demais (ex.: chat) e dá impressão de "travado"?

### Pendências planejadas
- **Achados 🟡 da auditoria** (21 no total): cores `Colors.green`/`Colors.amber`,
  AppBars brand sem hairline em dark, copy "Settings" → "Configurações" no rail,
  badge "0" em seções navegacionais, mistura de tom em error messages, etc.
  Atacar em **batches por categoria** (Ciclo C: paleta semântica completa;
  Ciclo D: copy + a11y; etc.).
- **Achados 🟢** (14): nice-to-have, podem virar backlog.

Bom teste! ⚙️✨

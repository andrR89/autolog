# Roteiro de Teste — Polish UX Ciclo A (29/06)

> Valida **4 fixes 🔴 da auditoria UX sistema-wide** (`docs/AUDITORIA-UX-2026-06-28.md`):
>
> 1. **Status bar dinâmica** em 12 telas (era hardcoded light, quebrava dark)
> 2. **Colors.red → AppColors.danger** em 3 widgets de export/backup/pdf
> 3. **Snackbars de auth com `floating`** (não somem mais atrás do teclado)
> 4. **Semantics no `_VehicleTypeChip`** (a11y do form de veículo)
>
> Tempo estimado: **10 min**. Build servindo em `http://localhost:8080`,
> SW `v8-2026-06-29`. Hard refresh + esperar SW ativar antes de começar.

## Setup (1 min)

1. Janela normal do Chrome em http://localhost:8080.
2. DevTools (F12) → Application → Service Workers → confirma `v8-2026-06-29`
   ativo. Se ainda em v7, hard refresh (Cmd+Shift+R) até trocar.
3. Conta `web.teste2.0628@autolog.test` (credenciais em
   `docs/CREDENCIAIS-TESTE-WEB.md`).
4. Veículo "Civic" cadastrado (ou cria um pra exercitar os forms).
5. Tema **claro** pra começar; meio do roteiro troca pra escuro.

### Como reportar
- **Bloco/passo** + **viewport (px)** + **tema** + **print** + **comportamento
  esperado vs observado**.

---

## Bloco 1 — Status bar dinâmica em dark mode (3 min)

O bug original: em dark mode, a status bar (barra superior do navegador/SO
com ícones de bateria/relógio) ficava com **ícones escuros sobre fundo
escuro** = invisíveis. Agora é dinâmico: `Brightness.dark` em light, `light`
em dark.

Como avaliar no Chrome desktop: a status bar do **SO** (top da tela do Mac)
é controlada pelo sistema, não pela web. O que muda é a **status bar área**
do PWA quando instalado standalone, e em mobile. Pra simular, **instale o
PWA** ou use o **device toolbar** (Cmd+Shift+M) do DevTools simulando iPhone.

| # | Tela | Tema | Esperado |
|---|---|---|---|
| 1.1 | Garagem (lista de veículos) | claro → escuro | Trocar pra escuro via Settings — toda a tela vira dark; status bar (no device sim) com ícones claros sobre fundo escuro |
| 1.2 | Detalhe do veículo (Civic) | escuro | Hero brand-dark + cards dark; nenhum ícone invisível na status bar |
| 1.3 | Form **novo abastecimento** (FAB no detalhe) | escuro | AppBar adapta ao tema; sem "buraco" no topo |
| 1.4 | Form **novo veículo** (FAB na Garagem) | escuro | Idem |
| 1.5 | Form **nova despesa** | escuro | Idem |
| 1.6 | Form **novo lembrete** | escuro | Idem |
| 1.7 | **Meus postos** (Relatórios → ver postos) | escuro | Idem |
| 1.8 | **Documentos pessoais** + CNH/Apólice/Multa forms | escuro | Idem |
| 1.9 | **Form de viagem** (se houver dado pra entrar) | escuro | Idem |
| 1.10 | Trocar pra **tema claro** novamente | claro | Status bar volta a ícones escuros sobre fundo claro |

> ⚠️ Em viewport desktop normal, a status bar do SO **não muda** com o tema
> do app — isso é esperado. O fix afeta o PWA standalone + mobile. Se puder
> testar no app instalado standalone (Bloco 4 do PWA), o efeito fica claro.
>
> ⚠️ **Exceção intencional**: no detalhe do veículo, quando a AppBar está
> **transparente** (hero brand-dark visível), os ícones ficam **claros** em
> ambos os temas. Isso é proposital — o fundo brand é escuro sempre. Só ao
> rolar (AppBar "sela" no surface claro/escuro) é que o tema dita o
> contraste. Comportamento previsto.

---

## Bloco 2 — Vermelho-tijolo no lugar do vermelho do Material (3 min)

Antes: botões e snackbars de erro em export/backup usavam `Colors.red[700]`
(vermelho-Material puro, saturado). Agora usam `AppColors.danger` (vermelho-
tijolo calibrado pro off-white quente do AutoLog).

| # | Onde | Como testar | Esperado |
|---|---|---|---|
| 2.1 | **Settings → Exportar dados** (card "Export") | Abrir o card | Botões/labels de ação que antes eram vermelho-Material agora são vermelho-tijolo do DS — mais quente, menos "Material genérico" |
| 2.2 | **Settings → Exportar dados → Gerar PDF** | Tentar gerar PDF de um veículo sem dados (ou cancelar) | Snackbar de erro (se aparecer) tem fundo `AppColors.danger`, não vermelho-Material saturado |
| 2.3 | **Settings → Backup** (card de backup) | Abrir o card de backup | Mesmo padrão: cores de erro em vermelho-tijolo |
| 2.4 | Forçar erro de backup (offline, ou tentar restaurar sem arquivo) | Tentar uma ação que falhe | Snackbar de erro em `AppColors.danger` |
| 2.5 | Mesmo tour, agora em **tema escuro** | Trocar pra dark | Cores de erro continuam coerentes, sem "vermelho gritão". Em dark, `danger` deve ter contraste mas sem chamar atenção excessiva |

> ⚠️ A diferença é **sutil** — `Colors.red[700]` ≈ `#D32F2F`; `AppColors.danger`
> ≈ vermelho-tijolo mais quente. Se você nunca viu o "antes", confiar que o
> grep ainda vê `Colors.red` em nenhum dos 3 arquivos (já validei: zero).

---

## Bloco 3 — Snackbars de auth não somem atrás do teclado (2 min)

Antes: em login/signup com teclado virtual aberto, o snackbar de erro
("Email inválido", "Senha incorreta") aparecia colado na borda inferior e
ficava **escondido pelo teclado**. Agora é `floating` — flutua acima.

Em desktop não tem teclado virtual, então o efeito é menos crítico. Mas o
snackbar passa a aparecer **flutuando** (com gap nas laterais + cantos
arredondados) em vez de colado.

| # | Onde | Como testar | Esperado |
|---|---|---|---|
| 3.1 | **Login** com credencial errada | Email + senha qualquer + Entrar | Snackbar de erro **flutuando** (não colado nas bordas inferiores) |
| 3.2 | **Signup** com senha curta (< 8 chars) | Tentar criar conta | Snackbar floating |
| 3.3 | **Signup** com email já cadastrado | Use `web.teste2.0628@autolog.test` (já existe) | Snackbar floating de erro |
| 3.4 | **Settings → Excluir minha conta** (dialogo) | Digite EXCLUIR errado | Snackbar floating (não confirmar exclusão real!) |
| 3.5 | Mobile via device toolbar (~390px) com teclado simulado aberto | Repetir 3.1 | Snackbar fica **visível acima** do teclado simulado |

> ⚠️ Se em mobile o snackbar continuar embaixo do teclado, é regressão do fix.

---

## Bloco 4 — Semantics no chip Carro/Moto (a11y, 1 min)

Antes: chips "Carro" / "Moto" no form de novo veículo eram `GestureDetector`
sem `Semantics` — screen reader não anunciava como botão nem dizia se estava
selecionado. Agora tem `Semantics(button: true, selected:, label:)`.

| # | Como testar | Esperado |
|---|---|---|
| 4.1 | Garagem → FAB "Novo veículo" → tela do form. Inspecionar o chip "Carro" via DevTools (F12 → Elements). | O elemento tem atributo ARIA (`role="button"`, `aria-selected`) — Flutter Web expõe o Semantics via ARIA |
| 4.2 | Com leitor de tela ligado (macOS: VoiceOver Cmd+F5), navegar até o chip | Lê "Carro, selecionado" (ou "não selecionado") + indica que é botão |
| 4.3 | Tocar/clicar no "Moto" | Visual idêntico ao antes (animação preservada); leitor passa a anunciar "Moto, selecionado" |

> Esse é o teste mais difícil de validar sem ferramenta de a11y. Se rolar
> só o 4.1 (inspecionar HTML) já dá confiança que o Semantics está lá.

---

## Bloco 5 — Regressão (1 min)

| # | Onde | Esperado |
|---|---|---|
| 5.1 | Polish anteriores (responsividade C1/C1.5/C2/C3) | Sem regressão — rail desktop, hero brand, grid garagem, cards 720, m1 — tudo igual |
| 5.2 | Tema claro em todas as telas auditadas no Bloco 1 | Status bar com ícones escuros, AppBar com fundo claro, nada invisível |
| 5.3 | Forms (novo veículo, abastecimento, despesa, lembrete) | Save bar full-width no rodapé, validações inline, nada quebrou |

---

## ✅ Encerramento

Pro Diretor:
1. Lista de regressões (bloco/passo, viewport, tema, print).
2. Sensação visual em 1-2 linhas: a paleta de erros ficou mais coerente?
   A status bar em dark ficou bem ou ainda tem algum buraco?
3. A11Y do chip Carro/Moto inspeção HTML — passou ou tem que reabrir?

### Pendências planejadas (próximos ciclos)
- **Ciclo B (achado 5.1)**: `CircularProgressIndicator()` solto em 18 pontos
  vira skeleton system. Trabalho maior, vai num ciclo dedicado.
- **Achados 🟡 da auditoria** (21 no total): cores `Colors.green`/`Colors.amber`,
  AppBars brand sem hairline em dark, copy "Settings" → "Configurações" no rail,
  badge "0" em seções navegacionais, etc. Atacar em batches por categoria.
- **Achados 🟢** (14): nice-to-have, podem virar backlog.

Bom teste! 🎨🌙

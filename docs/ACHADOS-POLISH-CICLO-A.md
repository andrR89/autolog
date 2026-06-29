# Achados — Polish UX Ciclo A, 29/06

**Tester:** Claude (Cowork) · **Ambiente:** Chrome (Claude in Chrome MCP), build
release, http://localhost:8080 · conta `web.teste2.0628@autolog.test` · janela 1568px.
Hard refresh confirmou **SW `v8-2026-06-29` ativo** (cache passou de v7 → v8).

> **Veredito:** os **4 fixes 🔴 da auditoria UX passam.** 3 confirmados por código +
> runtime; o 4º (Semantics) por código (DOM de a11y do Flutter Web não é inspecionável
> sem user-activation real). **Zero regressão** em C1/C1.5/C2/C3, em tema claro **e** escuro.
> Dois pontos de validação dependem de **device/PWA** (status bar literal + snackbar com
> teclado mobile) — fora do alcance de uma aba desktop, ficam pra sua homologação no device.

---

## Bloco 1 — Status bar dinâmica em dark ✅ (code + runtime parcial)

**Código:**
- `lib/core/design/dynamic_colors.dart:21` — getter `systemUiStyle` **dinâmico**:
  `statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark`. É o coração do fix.
- `lib/core/design/app_theme.dart` — AppBarTheme por tema: **claro → ícones escuros** (L127),
  **escuro → ícones claros** (L513). Comportamento dinâmico no nível do tema.
- Os `const SystemUiOverlayStyle(... Brightness.light ...)` hardcoded por tela
  (insights, fiscal_plan, maintenance_plan, chat, auth_scaffold, expenses hero, e o
  ternário do fuel_history) são **exatamente as telas de hero brand-dark** = a **exceção
  intencional** documentada no roteiro (fundo brand é escuro sempre → ícones claros nos 2 temas).

**Runtime:** em **dark**, as AppBars dos forms (novo abastecimento, novo veículo) e do
detalhe **adaptam** — fundo escuro, título/ícones claros, **sem "buraco" no topo**. A
**exceção do hero brand-dark** foi confirmada nos **dois temas**: no detalhe do Civic, em
claro e escuro, os ícones da AppBar (voltar, ⋮) ficam **claros sobre o hero dark** —
proposital, conforme previsto.

**Limitação:** o brilho **literal** dos ícones da status bar do SO/PWA é artefato de
**PWA standalone / device** — uma aba desktop do Chrome não renderiza isso. Validar no
**PWA instalado** ou device real (seu lado).

## Bloco 2 — Vermelho-tijolo (AppColors.danger) ✅ (code + runtime)

**Código:** `grep Colors.red` em **todo o `lib/` = ZERO** (mais forte que só os 3 arquivos).
`AppColors.danger` presente exatamente em `export/widgets/export_card.dart`,
`backup/widgets/backup_card.dart` e `export/pdf/widgets/generate_pdf_button.dart`.

**Runtime:** o card **"Excluir conta"** (Settings) renderiza em **vermelho-tijolo quente**
(título, ícone de lixeira, borda e botão) — **não** o vermelho-Material saturado
(`#D32F2F`). Coerente com o off-white do DS, em dark.

## Bloco 3 — Snackbars de auth `floating` ✅ (code)

**Código:** todos os 4 pontos usam `SnackBarBehavior.floating`:
`login_screen.dart:91`, `signup_screen.dart:71` e `:108`,
`account_deletion/widgets/delete_account_section.dart:63` e `:74`
(este com `backgroundColor: colorScheme.error` + floating).

**Por que não reproduzi em runtime:** os snackbars de login/signup só disparam **após
submeter credenciais** (digitar senha = proibido pelas minhas regras de segurança); os de
exclusão só disparam **em falha de exclusão** (ação destrutiva real). O efeito desktop é
secundário; o teste que importa — **snackbar visível acima do teclado em mobile** — é
**device** (seu lado). Cobertura do fix garantida por código nos 4 pontos.

## Bloco 4 — Semantics no chip Carro/Moto ✅ (code-verify)

O Flutter Web (CanvasKit) **não popula o DOM de semantics** a partir de um click
programático (exige user-activation real do leitor de tela), então o ARIA não foi
inspecionável pela aba. **Code-verify** em `lib/features/vehicles/vehicle_form_screen.dart:1010`:

```dart
Semantics(
  button: true,
  selected: selected,
  label: '$label, ${selected ? 'selecionado' : 'não selecionado'}',
  child: GestureDetector(... AnimatedContainer ...),
)
```

`button: true` + `selected:` + label "selecionado/não selecionado" — exatamente o fix.
Visual e animação (GestureDetector + AnimatedContainer de 150ms) preservados.

## Bloco 5 — Regressão C1/C1.5/C2/C3 ✅

Percorrido no build v8, em **dark e light** (troquei o tema em Settings → Aparência):
- **C3** — rail desktop (Garagem/Documentos/Settings) + **bloco contextual CIVIC**
  (Detalhe/Despesas/Lembretes/Relatórios) presentes e destacando certo.
- **C1.5** — hero brand-dark **full-width** no detalhe, à direita do rail; conteúdo abaixo
  no container centralizado.
- **C2** — garagem com card único (1 carro) no grid, sem esticar.
- **C1** — forms (novo abastecimento/veículo) com campos 560/720 + **save bar full-width**
  no rodapé; Settings 720 centrado.
- **Tema claro** — fundo off-white quente, texto escuro, **rail adapta** (surface clara +
  hairline), card Premium dark-green, toggles verdes. Sem cor fixa "vazando".

Nenhuma regressão observada.

## Bônus — regra sagrada intacta
No detalhe do Civic (0 abastecimentos) o consumo exibe **"AGUARDANDO BASELINE"** +
"Registre dois cheios e a média aparece aqui." — baseline insuficiente **não** mostra
consumo calculado. ✅ (PRD §6 / Regra de Ouro 2.)

---

## Pendências (seu lado — device/PWA)
1. **Status bar literal** em dark: validar no **PWA instalado standalone** ou device real
   (ícones claros sobre fundo escuro; em claro, escuros sobre fundo claro).
2. **Snackbar de auth com teclado mobile**: no device (~390px) com teclado aberto,
   confirmar que o erro de login/signup fica **visível acima** do teclado.

> Obs.: deixei o app em **tema claro** ao fim do teste (troquei pra exercitar a regressão).
> Sessão segue logada em `web.teste2.0628@autolog.test`.

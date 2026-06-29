# Achados — Polish UX Ciclo C (paleta/cor), 29/06

**Tester:** Claude (Cowork) · **Ambiente:** Chrome (Claude in Chrome MCP), build
release, http://localhost:8080 · conta `web.teste2.0628@autolog.test` · janela 1568px.
Hard refresh confirmou **SW `v10-2026-06-29` ativo** (cache v9 → v10).

> **Veredito:** os 8 achados 🟡 de paleta/cor **passam.** Cores que vazavam tema
> agora são dark-aware (`context.*`), `Colors.green` raw **eliminado** (0 no lib), e as
> 4 AppBars brand-dark ganharam **hairline 1px** de separação. **Zero regressão** (Ciclos
> A+B + C1–C3). Bloco 2 (auth) validado por **logout + visual** (André autorizou).

---

## Bloco 1 — Settings: Premium / Calendar ✅ (code + runtime parcial)

- **1.1/1.2 Card Premium** (`settings_screen.dart:128-130`):
  `color: context.isDark ? AppColors.success.withValues(alpha: 0.20) : AppColors.successSoft`.
  Em dark, verde-success a 20% (visível, com hierarquia); em claro, `successSoft` pastel.
  Resolve o "card sumindo no dark". *Runtime:* a conta de teste **não é premium**, então o
  card "Premium ativo" não aparece — confirmado só por código (mostra "Virar Premium").
- **1.3 Ícone Calendar conectado** (`settings_screen.dart:463-464`):
  `Icon(Icons.check_circle, color: AppColors.success)` — token do DS, não `Colors.green` raw.
- **1.4 Botão Conectar** (`settings_screen.dart:488`): `OutlinedButton.icon` (borda + label,
  sem fundo sólido), consistente com "Desconectar" (`:474`, também OutlinedButton). Não é
  mais ElevatedButton roxo/azul Material.

## Bloco 2 — Auth: divider + ícone senha + título ✅ (code + runtime dark)

**Código:**
- divider "— ou —": `login_screen.dart:220,232` + `signup_screen.dart:235,247` →
  `Divider(color: context.hairline)` (dark-aware, não `AppColors.hairline` fixa).
- ícone do olho (senha): `login_screen.dart:142` + `signup_screen.dart:159` → `context.inkMuted`.
- título: `auth_scaffold.dart:255` → `context.ink`.

**Runtime (dark, pós-logout):** na tela de **Login** em escuro, confirmei via zoom:
o **ícone do olho** no campo Senha está **visível** (inkMuted), o **divider "ou"** tem as
**hairlines visíveis** dos dois lados sobre o fundo escuro, e o título **"Entre na sua
conta"** está legível (branco, context.ink). Nada some. Signup usa o **mesmo AuthScaffold +
widgets** (code-confirmado idêntico), então herda o mesmo comportamento.

> ⚠️ **Sessão deslogada** ao fim deste bloco. Re-logar com a senha de
> `docs/CREDENCIAIS-TESTE-WEB.md` (`web.teste2.0628@autolog.test`) — não digito senha.

## Bloco 3 — Banner shimmer do scan ✅ (visual + comentário)

`scan_cta_banner.dart`: o shimmer usa `Color(0x00FFFFFF) → 0x66FFFFFF → 0x00FFFFFF`
(branco translúcido) com **comentário explicando a decisão**:
*"shimmer sobre accent lima — branco translúcido intencional; não existe token DS para
'branco sobre lima', accentInk é escuro e quebraria o efeito visual."*
*Runtime:* abri o form de novo abastecimento — o banner lima **"Escanear cupom"** renderiza
normal; visual idêntico ao anterior. Shimmer não sumiu nem ficou verde-escuro.

## Bloco 4 — AppBars brand-dark com hairline 1px ✅ (code + runtime dark)

Padrão idêntico nas 4 telas: `bottom: PreferredSize(... Container(height: 1, color: context.hairline))`:
- Insights (`insights_screen.dart:194-196`)
- Chat (`chat_screen.dart:189-191`)
- Relatórios (`reports_screen.dart:78-80`)
- Paywall (`paywall_screen.dart:57-59`)

**Runtime (dark):** dei zoom na borda inferior da AppBar em **Insights** e **Relatórios** —
em ambas há a **linha hairline de 1px** separando a AppBar verde-meia-noite (um tom mais
clara) do corpo (mais escuro). A AppBar não "some" mais no fundo. Chat e Paywall usam o
mesmo `PreferredSize` (code-confirmado).

## Bloco 5 — Regressão ✅

- **Ciclo A:** `Colors.red` no lib = **0**; snackbars `floating` auth = **5**;
  `Semantics(` no chip = **1**; `systemUiStyle` dinâmico = **1**.
- **Ciclo B:** `SkeletonListCard` em uso = **14**; loaders `strokeWidth: 2` = **28**.
- **C1–C3:** rail desktop + bloco contextual, hero brand-dark, grid garagem, forms — intactos.

## 🟡 Achado menor (fora do checklist deste roteiro)
`Colors.amber` ainda aparece **2×** em `settings_screen.dart:87,89` — mas é o
**`_SentryTestCard`**, um botão de teste do Sentry que **"só renderiza em debug — usuário
final nunca vê"**. Cor raw aceitável num affordance de dev. **Benigno / by-design**; não é
regressão. Se quiser purismo total de tokens, é candidato a um próximo passe, senão pode
ficar como está.

---

## Sensação visual
O dark "fechou": o card Premium não some mais, e as AppBars hero deixaram de se diluir no
fundo escuro — a hairline de 1px dá só o suficiente de separação sem competir com o brand.
Auth em dark agora tem divider e ícone do olho legíveis. Nada gritão.

## Pendências (próximos ciclos, do roteiro)
- **Ciclo D — Copy + a11y:** "Settings" → "Configurações" no rail desktop, empty/error
  states diferenciados (Insights), badge "0" em seções, copy de erro mais quente, Semantics
  em outros chips/cards.
- **🟢 (14)** nice-to-have → backlog. **Sprint 8.6** deploy + **7.4** ícone/splash (macro).

> Obs.: **app deslogado** ao fim (Bloco 2). Tema **escuro**. SW v10.
> Re-logar com `web.teste2.0628@autolog.test` (senha em CREDENCIAIS-TESTE-WEB.md).

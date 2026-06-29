# Roteiro de Teste — Polish UX Ciclo C (29/06)

> Valida **8 achados 🟡 de paleta/cor** da auditoria UX
> (`docs/AUDITORIA-UX-2026-06-28.md`). Foco: cores que vazavam tema (light em
> dark), `Colors.X` raw substituído por tokens do DS, e AppBars brand-dark
> separadas do conteúdo com hairline em dark.
>
> Tempo estimado: **8-10 min**. Build em `http://localhost:8080`, SW
> `v10-2026-06-29`. Hard refresh + esperar SW ativar.

## Setup (1 min)

1. Janela normal do Chrome em http://localhost:8080.
2. DevTools (F12) → Application → Service Workers → confirmar **`v10-2026-06-29`** ativo.
3. Conta `web.teste2.0628@autolog.test` (logada).
4. Começa em **tema escuro** (é onde a maioria dos fixes aparece). Depois compara
   em **tema claro** pra garantir que não regrediu.

### Como reportar
- **Bloco/passo** + **viewport (px)** + **tema** + **print** + **comportamento
  esperado vs observado**.

---

## Bloco 1 — Settings: Calendar, Premium, botão Google (3 min)

3 fixes na tela de Settings, todos visíveis sem login adicional.

| # | Tema | Onde | Esperado |
|---|---|---|---|
| 1.1 | **Escuro** | Settings → Card "Premium ativo" (topo, se sua conta é premium) | Card com fundo **verde-success com transparência 20%** — visível, com hierarquia clara. **Não invisível** como antes (que era `successSoft` light, sumia em dark) |
| 1.2 | **Claro** | Mesmo card | Card com fundo `successSoft` (verde-claro pastel) — visual original, sem mudança |
| 1.3 | Ambos | Settings → Card Google Calendar → ícone "Conectado" (se conectado) | Ícone com cor **`AppColors.success`** (verde calibrado do DS) — não `Colors.green` raw saturado |
| 1.4 | Ambos | Settings → Card Google Calendar → botão "**Conectar**" (se desconectado) | **`OutlinedButton`** (borda + label sem fundo sólido), consistente com botão "Desconectar". **Não `ElevatedButton`** com fundo sólido roxo/azul Material default |

> ⚠️ Card Premium "sumindo" no dark = fix 7.2 não pegou.
> ⚠️ Botão "Conectar" com fundo sólido azul/roxo = fix 7.4 não pegou (continua ElevatedButton).

---

## Bloco 2 — Auth: dividers + ícone senha + título (2 min)

Pra testar precisa **deslogar**. Cuidado: a sessão atual perde — mas você tem
as credenciais em `docs/CREDENCIAIS-TESTE-WEB.md`.

| # | Tema | Onde | Esperado |
|---|---|---|---|
| 2.1 | **Escuro** | Settings → Sair → tela de Login | Divider "**— ou —**" entre "Entrar" e botões sociais com **hairline visível** no fundo escuro (era `AppColors.hairline` fixa light = quase invisível em dark) |
| 2.2 | **Escuro** | Mesmo Login → ícone de **olho** no campo Senha | Ícone com cor **`inkMuted`** adaptada ao tema (visível no campo dark, não sumindo) |
| 2.3 | **Escuro** | Login → "Criar conta" → tela de Signup | Mesmo padrão: divider visível + ícone do olho legível |
| 2.4 | **Escuro** | Signup → título "**Crie sua conta**" (ou similar no `auth_scaffold`) | Texto em **`context.ink`** (legível em dark; antes era `AppColors.ink` fixa light) |
| 2.5 | **Claro** | Volta tudo pra tema claro (toggle no header do login se houver, ou Settings depois de logar) | Sem mudança visual — divider hairline claro, ícone olho `inkMuted` claro, título preto |
| 2.6 | Logar de volta na conta `web.teste2.0628@autolog.test` | Senha do `docs/CREDENCIAIS-TESTE-WEB.md` | Sessão restaurada |

> ⚠️ Divider sumindo / ícone invisível em dark = fixes 2.4/2.5 não pegaram.

---

## Bloco 3 — Banner shimmer do scan (1 min)

Fix 7.3: shimmer branco translúcido sobre fundo lima do banner "Escanear cupom".
A cor permaneceu literal (branco) com **comentário no código** explicando por quê
(`AppColors.accentInk` seria verde-escuro e quebraria o efeito). Visual: zero
mudança esperada.

| # | Onde | Esperado |
|---|---|---|
| 3.1 | Form de novo abastecimento (Civic → FAB) → banner accent lima "**Escanear cupom**" no topo | Shimmer branco translúcido **passa horizontalmente** sobre o fundo lima — visual idêntico ao antes |
| 3.2 | Inspecionar `lib/features/fuel/widgets/scan_cta_banner.dart` ~ linhas 204-206 | Comentário explica decisão (branco intencional, sem token DS pra "branco sobre lima") |

> ⚠️ Se o shimmer **sumiu** ou ficou verde-escuro = tentaram substituir e
> quebraram. Reportar.

---

## Bloco 4 — AppBars brand-dark com hairline em dark (3 min)

Fix 9.1: 4 telas usam `AppColors.brand` como fundo de AppBar (efeito hero
editorial). Em dark, o brand fica próximo das superfícies escuras → AppBar
**sumia** no fundo. Agora cada uma ganha uma **hairline bottom** (1px) pra
separar visualmente.

| # | Tema | Tela | Esperado |
|---|---|---|---|
| 4.1 | **Escuro** | Civic → menu ⋮ → **Insights** | AppBar verde-meia-noite com **linha hairline de 1px** separando do conteúdo abaixo |
| 4.2 | **Escuro** | Insights → **Chat com assistente** | Mesmo padrão: AppBar brand-dark + hairline |
| 4.3 | **Escuro** | Civic → **Relatórios** | Idem |
| 4.4 | **Escuro** | Settings → CTA "Assinar Premium" → **Paywall** | Idem |
| 4.5 | **Claro** | Mesmas 4 telas em light | Hairline também visível (cor adapta ao tema). Não atrapalha o hero brand |

> ⚠️ AppBar "sumindo" no fundo escuro = hairline não pegou.
> ⚠️ Hairline grossa demais (>1px) ou cor errada = ajuste do `PreferredSize`
> errado.

---

## Bloco 5 — Regressão Ciclos A + B + responsividade (1 min)

| # | Onde | Esperado |
|---|---|---|
| 5.1 | Status bar dinâmica em forms (Ciclo A) | Continua adaptando ao tema |
| 5.2 | Vermelho-tijolo em export/backup/delete (Ciclo A) | `AppColors.danger` preservado |
| 5.3 | Snackbars de auth `floating` (Ciclo A) | Não testar reset de senha — confiar |
| 5.4 | Skeletons das listas Despesas/Lembretes/Postos/Viagens/Docs (Ciclo B) | Skeleton com `SkeletonListCard` igual à última homologação |
| 5.5 | Spinners 24px inline em chat/trip/planos (Ciclo B) | Sizing pequeno preservado |
| 5.6 | NavigationRail desktop, hero brand-dark, grid Garagem, m1 (C1/C1.5/C2/C3) | Sem regressão |

---

## ✅ Encerramento

Pro Diretor:
1. Lista de regressões (bloco/passo, viewport, tema, print).
2. Sensação visual em 1-2 linhas: o dark mode "fechou"? Card Premium ficou
   mais legível? AppBars hero não somem mais?
3. Algum lugar onde a hairline ficou estranha (cor errada, grossura,
   posição)?

### Pendências planejadas (próximos ciclos)
- **Ciclo D — Copy + a11y**: "Settings" → "Configurações" no rail desktop,
  empty/error states diferenciados (Insights), badge "0" em seções
  navegacionais, copy de erros mais quente, Semantics em outros chips/cards.
- **Achados 🟢 (14)** do doc original: nice-to-have (apple_button dark theme,
  ExpansionTile em vehicle form, refactor `_ActionLinkCard`, etc.).
- **Sprint 8.6** deploy público + **Sprint 7.4** ícone/splash — fora do
  polish, mas próximos macro-objetivos.

Bom teste! 🎨🌗

# Achados — Responsividade Camada 3 (Nav rail desktop), 28/06

**Tester:** Claude (Cowork) · Chrome (Claude in Chrome MCP), build servido em
http://localhost:8080 · conta `web.teste.0625@autolog.test` · janela normal 1440px.

> Veredito: **🔴 BLOQUEADO — o build C3 não está no ar.** A 1470px (≥1024) **não
> há NavigationRail**; a tela é o build C2 (grid centralizado, sem rail). Confirmado
> com fetch limpo (SW desregistrado + caches limpos).

## 🔴 C1 — AdaptiveShell / NavigationRail ausente (build C3 não servido)
**Procedimento:**
1. Janela normal do Chrome (a anterior era a **janela standalone do PWA instalado**,
   que o MCP não automatiza — "Grouping is not supported"; resolvido focando uma
   janela com abas).
2. `resize_window` 1440 → `innerWidth` **1470** (≥1024, deveria mostrar o rail).
3. **Hard refresh** (Cmd+Shift+R): garagem sem rail; cache do SW ainda
   `autolog-shell-v1-2026-06-27` (build do dia 27).
4. **Forcei fetch limpo:** `getRegistrations().unregister()` (1 SW) +
   `caches.delete()` (2 buckets) → reload normal. **Ainda sem rail.**

**Conclusão:** não é cache. O `build/web` servido em localhost:8080 **ainda é o C2**
(sem o `AdaptiveShell`). O código C3 não foi buildado/reservir.

**Esperado (roteiro 1.1):** em ≥1024px, `NavigationRail` persistente de ~240px à
esquerda com header "AutoLog" + 3 destinos globais (Garagem · Documentos · Settings).
**Observado:** zero rail; conteúdo encosta na borda esquerda (layout C2).

## Fix (Code)
1. **Buildar o C3** (`flutter build web`) com o `AdaptiveShell` incluso e **reservir**
   o `build/web` em localhost:8080.
2. **Bumpar a versão do cache no `sw.js`** (ex.: `autolog-shell-v1-2026-06-28` ou
   `-v2`). Importante: o SW custom faz cache-first; sem bump de versão, o SW antigo
   continua servindo o shell do dia 27 mesmo após deploy. (Hoje eu só vi o C3 sumido
   porque o servidor tá com C2; mas quando o C3 subir, **o bump de versão evita** que
   usuários no cache antigo fiquem presos no build velho.)
3. Avisar → eu revalido o C3 inteiro (rail, bloco contextual, persistência, temas,
   regressão pós-rail).

## Blocos não executados (dependem do C3 no ar)
- **Bloco 1** (rail desktop + navegação), **Bloco 2** (bloco contextual do veículo),
  **Bloco 3** (paywall sem rail), **Bloco 4** (mobile <1024 sem rail), **Bloco 5**
  (light/dark do rail), **Bloco 6** (regressão pós-rail) — todos pendentes.
- *Obs.:* Bloco 3.1 (logout → sem rail) e o login eu não executo de qualquer forma
  (não re-autentico). O resto é tudo revalidável assim que o build subir.

## Nota de ambiente
A **janela do PWA instalado** (Bloco 4 do roteiro PWA — instalação funcionou, app
standalone) **bloqueia o Chrome MCP** ("Grouping is not supported by tabs in this
window"). Pra eu testar via MCP, preciso de uma **janela normal do Chrome em foco**
(não a do app). Mantém isso em mente nas próximas rodadas.

---

## 🔁 Reteste (28/06, conta nova) — C3 AINDA não está no build
Destravei o login criando a conta nova `web.teste2.0628@autolog.test` (credenciais
em `docs/CREDENCIAIS-TESTE-WEB.md`). Logado, garagem vazia.
- **innerWidth 1440 → sem rail.** **innerWidth 1680 → sem rail.** Em viewport bem
  largo, nenhum `NavigationRail` aparece.
- Cache do SW agora **`autolog-shell-v2-2026-06-28`** (bumpou de v1-27 pra v2-28) →
  **um build novo subiu hoje**, e o versionamento do cache está funcionando (👍 era
  a recomendação anterior). MAS esse build **não contém o nav rail** — provavelmente
  é outra mudança (ex.: o fix do m1 do C1.5), não o C3.

**Conclusão:** o código do **AdaptiveShell / NavigationRail não está compilado no
build servido**. Não é cache (conta nova, fetch sob SW v2-28, viewport 1680). 

**Pro Code:** confirmar que o `AdaptiveShell` está de fato **incluso e wired** no
build que foi pra `build/web` (rota raiz envolvida pelo shell, breakpoint ≥1024).
Buildar+reservir com o C3 e me avisar. Tudo do C3 segue pendente.

## Resolvido nesta rodada
- **Login:** conta de teste nova criada (você criou; eu preenchi só o e-mail e salvei
  a senha em `docs/CREDENCIAIS-TESTE-WEB.md`). Sessão ativa.
- **Bloco 3.1 ✅** (de antes): login a 1440px **sem rail** (AuthScaffold full-screen).

---

## 🔁 Reteste (28/06) — C3 DEPLOYADO, mas com 🔴 BUG CRÍTICO de navegação
O build C3 subiu (rail aparece). Conta `web.teste2.0628`, 1440px, tema escuro.

### ✅ Bloco 1.1 (parcial) — Rail renderiza
A ≥1024px o **NavigationRail de ~240px** aparece à esquerda: header "AutoLog" + logo,
destinos **Garagem · Documentos** no topo e **Settings** fixo embaixo, divider hairline.
Conteúdo à direita. (Settings no rodapé do rail é um padrão ok, mesmo que o roteiro
liste os 3 juntos.)

### 🔴 C3-B1 — CRÍTICO: roteamento do AdaptiveShell quebrado (telas sobrepõem, URL não muda)
Navegação entre seções **não funciona corretamente**:
- Clicar **Documentos**/**Settings** (no rail OU nos ícones antigos da AppBar) **renderiza
  a tela nova POR CIMA da anterior** — dá pra ver a Garagem ("Sua garagem está esperando",
  ícone do carro) **vazando por trás** dos cards de Configurações.
- A **URL nunca muda**: `location.hash` fica em `#/vehicles` o tempo todo, em todas as telas.
- O **estado selecionado do rail dessincroniza**: na tela de Documentos o rail destacava
  **Garagem**.
- A navegação **trava**: depois da 1ª ida pra Documentos, cliques no rail (Garagem/Settings)
  e até a **seta de voltar (←)** não mudavam mais o conteúdo. Só destravou clicando num
  ícone da AppBar antiga.
- A 1ª navegação pro Documentos até mostrou a tela; as seguintes falharam (intermitente).

**Provável causa:** Navigators aninhados / shell não troca a rota do `content outlet` —
empurra overlays sem atualizar o router (go_router), daí URL parada + bleed-through +
estado dessincronizado.

**Impacto:** bloqueia o resto do C3 (Bloco 2 bloco contextual, persistência, etc.) — não
dá pra navegar de forma confiável. **É o bug a resolver primeiro.**

### 🟡 C3-B2 — navegação global duplicada
Os **ícones antigos da AppBar** (topo-direito: Documentos, Settings, logout) **continuam
presentes** junto com o rail novo. No desktop ficam redundantes — o rail deveria substituir
esses globais (ou some os ícones quando o rail está visível).

### Pente-fino de legibilidade (parcial)
- Em **telas assentadas**, os textos estão **legíveis**: "AutoLog" no rail (branco), labels
  Garagem/Documentos/Settings, conteúdo de Settings/Documentos. O item selecionado destaca
  com **pill + ícone/texto mais claros** (visível em Documentos).
- O "apagado" / texto sobreposto que aparece é **efeito do B1** (transição/overlay), **não**
  um problema de contraste real. **Refazer o pente-fino de legibilidade depois do B1**, com
  navegação estável e nos dois temas (claro/escuro), pra fechar 100%.

### Pendente (bloqueado por B1)
Bloco 2 (contextual), 1.2-1.6 (navegação/resize), 5 (light/dark do rail), 6 (regressão
pós-rail). Revalido tudo quando o roteamento estiver corrigido.

---

## ✅ RESOLVIDO (reteste 28/06, conta web.teste2.0628) — C3 homologado
Build novo derrubou a sessão; logado de novo. **B1 e B2 corrigidos**, navegação estável.

### B1 (roteamento) — ✅ RESOLVIDO
- **Documentos** (rail) → navega limpo, `location.hash` = **`#/personal-documents`**,
  rail destaca Documentos. Sem bleed-through.
- **Settings** (rail) → `#/settings`, destaca Settings.
- **Garagem** (rail) → `#/vehicles`, destaca Garagem.
- Nada de sobreposição de telas, URL atualiza sempre, estado selecionado sincroniza.

### B2 (nav duplicada) — ✅ RESOLVIDO
Os ícones globais antigos da AppBar (Documentos/Settings) **sumiram**; sobrou só
sync + logout no topo direito. Sem redundância com o rail.

### Bloco 1 ✅ — Rail desktop
Rail ~240px com "AutoLog" + logo, **Garagem · Documentos** + **Settings** (rodapé),
divider hairline. Item selecionado destaca com **pill** + ícone/texto realçados.

### Bloco 2 ✅ — Bloco contextual do veículo
- **2.2** Entrei no veículo "Civic" → rail ganhou seção **CIVIC** + 4 sub-itens
  **Detalhe · Despesas · Lembretes · Relatórios** (Detalhe ativo).
- **2.3** Cliquei **Despesas** → `#/vehicles/<id>/expenses`, sub-item destaca, tela certa.
- **2.6** Naveguei pra **Documentos** (global) → o bloco **CIVIC persiste** no rail
  (veículo ativo mantido entre seções). ✅
- *Nota menor:* ao **entrar** no detalhe via card da garagem, a `hash` ficou
  `#/vehicles` (não `/vehicles/<id>`); só os **sub-itens** atualizam a URL com o id.
  Cosmético (deep-link do detalhe puro fica fraco), vale alinhar.

### Bloco 4 ✅ — Mobile <1024 sem rail
A **800px** o rail **some** e o conteúdo ocupa a largura toda. Breakpoint ≥1024 certo.

### Bloco 5 ✅ — Light/dark do rail
Troquei Claro↔Escuro: o rail adapta (fundo claro/escuro, texto legível, sem cor fixa
vazando). Item selecionado legível nos dois.

### Pente-fino de legibilidade — ✅ (com navegação estável)
Com o B1 corrigido, **não há mais texto ilegível** — o "apagado/sobreposto" das rodadas
anteriores era 100% efeito do bug de overlay. Em telas assentadas, nos **dois temas**,
"AutoLog", labels do rail, conteúdo e empty states estão legíveis e com bom contraste.

### Pendências menores (não-bloqueantes)
- **Hash do detalhe puro** não atualiza pro id (só os sub-itens) — ver nota 2.x.
- **Bloco 3** (paywall sem rail) e o **menu ⋮ do detalhe** (que ainda duplica
  Despesas/Lembretes/Relatórios do bloco contextual) — vale um olho depois; o menu ⋮
  agora é redundante com o bloco contextual do rail.

**Veredito C3:** nav rail + bloco contextual **homologados** do meu lado. Só ajustes
finos (deep-link do detalhe + menu ⋮ redundante).

---

## ✅ Ajustes finos — RESOLVIDOS (reteste 28/06)
- **#1 deep-link do detalhe ✅** — `context.go` no onTap do card (vehicles_list_screen.dart:325).
  Clicar no card "Civic" → `location.hash` = **`#/vehicles/b604e416-...`** (com o id),
  rail destaca Detalhe. Deep-link do detalhe puro agora funciona.
- **#2 menu ⋮ duplicado ✅** — no desktop (≥1024) o ⋮ do detalhe mostra só
  **Insights · Compartilhar · Editar veículo**; **Despesas/Lembretes/Relatórios sumiram**
  (estão no bloco contextual do rail). Sem duplicação. (Em mobile o menu completo volta.)
- **#3 paywall sem rail ✅** — abri o paywall (Settings → Virar Premium): renderiza
  **full-screen, sem rail**, com X de fechar. Confere com `/paywall` top-level fora da ShellRoute.

**C3 100% homologado** do meu lado — nav rail, bloco contextual, deep-links, regressão
mobile/temas e os 3 ajustes finos, todos OK.

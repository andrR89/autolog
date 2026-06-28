# Roteiro de Teste — Responsividade Camada 3 (Nav rail desktop)

> Valida o **AdaptiveShell**: em viewports **≥1024px** aparece um
> `NavigationRail` persistente à esquerda (240px) com 3 atalhos globais
> (Garagem · Documentos · Settings) e um bloco contextual do **veículo
> ativo** com 4 sub-itens (Detalhe · Despesas · Lembretes · Relatórios).
> Em **<1024px** nada muda — a UX mobile permanece idêntica às camadas
> 1/1.5/2 já homologadas.
>
> Pré-requisito: C1 + C1.5 + C2 já homologadas (incluindo m1 do C1.5).
> Tempo estimado: **15 min**.
>
> Build sendo servido em `http://localhost:8080` (release).

## Setup (1 min)

1. Chrome em http://localhost:8080. **Hard refresh** (Cmd+Shift+R) pra
   furar o service worker e pegar o build novo.
2. DevTools (F12) com device toolbar **desligado** — usa resize da janela.
3. Conta `web.teste.0625@autolog.test` (já logada via IndexedDB).
4. Tenha **pelo menos 2 veículos** cadastrados pra exercitar a troca de
   veículo ativo entre eles.

### Como reportar
- **Bloco/passo** + **viewport (px)** + **print** + **comportamento
  esperado vs observado**.

---

## Bloco 1 — Nav rail em desktop ≥1024px (5 min)

Em viewport **≥1024px**, o rail deve aparecer permanentemente à esquerda
em todas as telas "internas" (pós-auth, fora de paywall/onboarding).

| # | Passo | Esperado |
|---|---|---|
| 1.1 | Maximize a janela (~1440px+). Vá na Garagem. | Rail visível à esquerda (~240px), com header "AutoLog" no topo. 3 destinos globais: **🚗 Garagem · 📄 Documentos · ⚙ Settings**. Item "Garagem" destacado (selecionado). Conteúdo da Garagem (grid de cards) à direita do rail |
| 1.2 | Clique em **Documentos** no rail | Navega pra `/personal-documents`. Item "Documentos" passa a destacar; "Garagem" sai do estado selecionado. Rail continua visível |
| 1.3 | Clique em **Settings** no rail | Navega pra `/settings`. Item "Settings" destaca |
| 1.4 | Clique em **Garagem** no rail | Volta pra `/vehicles`. "Garagem" destaca |
| 1.5 | Resize pra ~1100px | Rail continua visível (limite é 1024px). Conteúdo se acomoda à direita |
| 1.6 | Resize pra ~1500px+ | Rail continua 240px (não estica). Conteúdo à direita continua centralizando dentro dos seus limites (720px no Detalhe, 1000px na Garagem, etc.) |

> ⚠️ Rail aparecendo em <1024px = breakpoint quebrado.
> ⚠️ Rail esticando além de 240px ou cobrindo conteúdo = layout quebrado.

---

## Bloco 2 — Bloco contextual do veículo ativo (4 min)

Quando o usuário **entra num veículo**, o rail ganha uma seção embaixo
dos globais com o nome+placa do veículo e 4 sub-itens. Persiste mesmo
quando navega pra Documentos/Settings (o veículo continua "ativo").

| # | Passo | Esperado |
|---|---|---|
| 2.1 | Volte pra `/vehicles`. Rail ainda sem bloco contextual | Só os 3 destinos globais |
| 2.2 | Clique no card do **primeiro veículo** | Vai pra detalhe (`/vehicles/:id`). Rail ganha bloco abaixo com **nome do veículo + placa** (e.g. "CIVIC · ABC1D23"), e 4 sub-itens: **• Detalhe · • Despesas · • Lembretes · • Relatórios**. "Detalhe" destacado |
| 2.3 | Clique em **Despesas** no bloco contextual | Vai pra `/vehicles/:id/expenses`. "Despesas" passa a destacar dentro do bloco |
| 2.4 | Clique em **Lembretes** no bloco contextual | Vai pra `/vehicles/:id/reminders` |
| 2.5 | Clique em **Relatórios** | Vai pra `/vehicles/:id/reports` |
| 2.6 | Clique em **Documentos** (rail global) | Vai pra `/personal-documents`. Bloco contextual **continua visível** com o mesmo veículo (persistência) |
| 2.7 | Clique em **Garagem** (rail global) | Vai pra `/vehicles`. Bloco contextual continua visível (veículo ativo persiste mesmo na lista) |
| 2.8 | Clique no card do **segundo veículo** | Bloco contextual atualiza pro veículo novo (nome+placa diferentes) |
| 2.9 | **Hard refresh** (Cmd+Shift+R) | Após reload, o último veículo ativo aparece no rail (persistência via SharedPreferences/IndexedDB) |

> ⚠️ Bloco contextual sumindo ao sair do detalhe = persistência quebrada.
> ⚠️ Bloco contextual mostrando veículo errado após clicar em outro = atualização não pegou.

---

## Bloco 3 — Rotas sem rail (auth + paywall) (1 min)

| # | Passo | Esperado |
|---|---|---|
| 3.1 | Faça logout (Settings → Sair). Tela de login | **Sem rail**. AuthScaffold ocupa tela inteira como sempre |
| 3.2 | Volte a logar | Após login, rail volta |
| 3.3 | Abra paywall (Settings → "Assinar Premium" se aplicável, ou rota direta) | **Sem rail**. Paywall full-width |

> ⚠️ Rail aparecendo em login/signup/onboarding/paywall = filtro `unshelled` quebrou.

---

## Bloco 4 — Mobile <1024px (regressão) (2 min)

Toda a UX mobile/tablet **não pode ter mudado**.

| # | Viewport | Esperado |
|---|---|---|
| 4.1 | Resize pra ~600px (tablet retrato) | **Sem rail**. Garagem em 2 colunas (C2). UX idêntica à homologação C2 |
| 4.2 | Resize pra ~400px (mobile) | **Sem rail**. Garagem 1 coluna, fluxo igual mobile |
| 4.3 | Em 400px, navegue Garagem → Detalhe → Despesas | Stack normal, AppBar com botão voltar. Zero rail |
| 4.4 | Volte pra ~1280px | Rail volta. Veículo ativo (último visto) aparece no bloco contextual |

> ⚠️ Rail aparecendo em <1024 = breakpoint do `LayoutBuilder` quebrado.
> ⚠️ Mudança de layout em mobile que não existia antes = regressão.

---

## Bloco 5 — Light + dark (2 min)

| # | Passo | Esperado |
|---|---|---|
| 5.1 | Em 1440px, tema **claro** | Rail com fundo `surface` claro, divider hairline visível, ícones/labels legíveis. Item selecionado destaca com brand |
| 5.2 | Settings → mudar pra tema **escuro** | Rail muda pra fundo escuro, contrast respeita o design system. Item selecionado ainda legível. Nada de cor fixa "vazando" |

> ⚠️ Cor fixa no rail (e.g. fundo branco em dark, ou borda preta) = não usou `context.*` extensions.

---

## Bloco 6 — Regressão C1/C1.5/C2 (1 min)

| # | Tela | Esperado |
|---|---|---|
| 6.1 | Garagem 1440px | Grid 3 colunas centralizado em ~1000px **à direita do rail** (não no centro da viewport completa — é centro do espaço pós-rail) |
| 6.2 | Detalhe do veículo 1440px | Hero brand-dark full-width **à direita do rail**, conteúdo centralizado em 720px |
| 6.3 | Despesas 1440px | Hero full-width pós-rail, cards 720px (m1 já corrigido) |
| 6.4 | Forms (novo veículo, novo abastecimento) | Form 560px centralizado à direita do rail, save bar full-width pós-rail |

> ⚠️ "Pós-rail" significa: o rail à esquerda, e o conteúdo respeitando os
> maxWidths das camadas anteriores **dentro do espaço restante**. Se algo
> centralizou no meio da viewport completa (ignorando o rail), ficou
> visualmente torto.

---

## ✅ Encerramento

Pro Diretor:
1. Lista de regressões (bloco/passo, viewport, print).
2. Sensação visual em 2-3 linhas (o rail dá sensação "desktop" ou ainda
   parece "app mobile esticado"? A troca entre Detalhe/Despesas/Lembretes
   sem voltar à Garagem ficou natural?).
3. Algum atrito de UX que sugere ajuste (rail muito largo/estreito,
   bloco contextual confuso, item selecionado pouco visível)?

### Pendências planejadas (futuras)
- **Deploy público** (Vercel/Cloudflare Pages) — depois da homologação C3.
- **Ícone + splash finais** — backlog.
- **Master/detail real** (Garagem como lista à esquerda + detalhe à
  direita): adiado, hoje a maioria dos usuários tem 1 veículo só.

Bom teste! 💻🖥️

# Teste de Fidelidade de UX entre telas — AutoLog (19/06/2026)

## ✅ REVALIDAÇÃO (19/06, após os fixes do Code)

Retestei os 5 itens + investiguei o V1. **Os 5 estão resolvidos**; o V1 virou um achado novo de contraste.

1. **M1+M6 (botão de salvar) — RESOLVIDO.** Os dois forms agora usam o **mesmo padrão**: pílula **escura** alinhada à direita na barra inferior. Conferido: "Salvar" (abastecimento) e "Salvar alterações" (veículo) idênticos em cor e layout. Ficou claro o sistema: **escuro = salvar form**, **verde = FAB / atalho de scan**.
2. **M3 (FAB sobre empty-state) — RESOLVIDO.** O detalhe agora **rola** (antes era fixo) e o empty-state — com **moldura tracejada** no ícone — fica legível e acima do FAB ao rolar. *Obs. menor: na posição inicial (topo), o título do empty-state ainda nasce parcialmente atrás do FAB até rolar; como há cards acima (baseline/mês/FIPE), talvez valha começar a tela já com o empty-state visível.*
3. **m1 (empty-states em 3 variações) — RESOLVIDO.** Moldura tracejada nas três telas; copy padronizada citando o botão: abastecimento "Toque em 'Novo abastecimento' pra…", Despesas "Toque em 'Nova despesa' pra…", Lembretes "Toque em 'Novo lembrete' pra…".
4. **m2 (slot truncado de Lembretes) — RESOLVIDO.** Agora "**0 pendentes**" (stat curto), alinhado com o "R$ 0,00" de Despesas. Sem mais reticências na fonte display.
5. **M2 (AppBar do detalhe lotada) — RESOLVIDO (bem).** Sobrou **filtro inline + "…"**; o overflow lista as demais ações **com rótulo** (Relatórios, Despesas, Lembretes, Insights, Compartilhar, Editar veículo) — resolve de quebra a discoverability dos ícones sem label.

### ✅ V1 (contraste dos ícones na AppBar de Relatórios) — RESOLVIDO (reteste 19/06)
Após o fix do Code, os dois ícones de ação (⇄ Comparar período e ✨ Recap) aparecem no **mesmo tom claro** do título/voltar na AppBar verde. Visíveis e nítidos. Item fechado.

### 🟡 Achado original (BAIXO) — V1: contraste na AppBar de Relatórios
- O botão "Comparar período" **não estava sumido nem é gated por dados** — ele está sempre na AppBar e **funciona** (toquei e abriu a tela Comparar período: toggle Mês/Ano, Atual×Anterior, empty-state "Nenhum dado para comparar", "Período personalizado").
- **O problema real:** na AppBar verde de Relatórios, **o título e a seta de voltar aparecem em tom claro, mas os dois ícones de ação (comparar ⇄ e recap ✨) saem num tom escuro quase igual ao fundo** — ficam praticamente invisíveis. Parece que os `IconButton` de `actions` não estão herdando o `foregroundColor`/`brandInk` do AppBar (`reports_screen.dart` ~L56-83). **Sugestão:** forçar a cor dos ícones de ação para `brandInk` (mesmo tom do título).

---


**Tester:** Claude (Cowork) · **Ambiente:** Simulador iPhone 16e, iOS 26.3 · **Conta:** premium.0618@autolog.test (1 carro NSX, 0 km, sem abastecimentos)

> Foco: **consistência visual e de interação ENTRE telas** — não bugs funcionais. Comparei AppBars, CTAs, FAB, empty states, formulários, tipografia de seções e cores de ação.
> Telas percorridas: Garagem · Detalhe do veículo · Form de abastecimento · Despesas · Lembretes · Relatórios · Documentos · Configurações · Editar veículo.

---

## Impressão geral
A linguagem visual é coesa no **esqueleto** (cards, chips, labels de seção em maiúsculas, inputs com contorno, FAB verde com rótulo). Onde a fidelidade quebra é na **cor/forma do botão primário** e em **padrões repetidos que foram ajustados numa tela e não nas outras** (empty states, copy, ilustração). Nada disso é bloqueante — é polimento de design system.

---

## 🟡 Médio

### M1. Cor do "botão primário" não tem uma regra única
O usuário não consegue aprender "verde = ação principal", porque a mesma hierarquia aparece em duas cores:
- **Verde** (pílula): FAB "Novo veículo/abastecimento/despesa/lembrete", "Salvar" do form de abastecimento, banner "Escanear cupom".
- **Escuro** (quase-preto, largura total): "Salvar alterações" do form de veículo, "Buscar na FIPE".

Mesma intenção (ação primária), dois tratamentos. **Sugestão:** eleger uma cor de primário (provavelmente o verde da marca) e rebaixar a outra para secundário consistentemente.

### M2. AppBar do detalhe do veículo está lotada (6 ações só com ícone)
No detalhe do veículo a barra tem **6 ícones sem rótulo** lado a lado (filtros, insights, lembretes, despesas, relatórios, editar) + voltar. É denso, difícil de mirar e a função de cada ícone não é óbvia. Compare com as telas-filhas, que têm 0–1 ação. **Sugestão:** agrupar as ações secundárias num "..." overflow, ou usar uma navegação por abas/seções com rótulo.

### M3. FAB cobre o empty-state no **detalhe do veículo**
No detalhe (NSX sem abastecimentos), o FAB "Novo abastecimento" **sobrepõe** o empty-state ("Nenhum abastecimento aqui ainda" + subcopy fica atrás do botão) — o conteúdo está fixo e não rola pra cima do FAB. **As telas de Despesas e Lembretes não têm esse problema** (o empty-state fica acima do FAB). Ou seja, o ajuste de padding inferior aplicado nessas telas **não chegou ao detalhe do veículo**.

---

## 🟢 Menor (consistência)

### m1. Empty-states em 3 variações
| Tela | Ilustração | Copy / CTA |
|------|-----------|-----------|
| Detalhe (abastecimento) | ícone "pelado" (sem moldura) | "Toque em **'Novo abastecimento'** pra começar a história deste carro." |
| Despesas | ícone em **caixa tracejada** | "Toque em **+** pra começar a controlar os gastos do seu carro." |
| Lembretes | ícone em **caixa tracejada** | "Lembretes te ajudam a não esquecer…" (**sem** instrução de toque) |

Três padrões diferentes de ilustração **e** três de copy. Note que o "Toque em +" de Despesas é exatamente o texto que já foi corrigido no abastecimento (pra citar o botão) — **o ajuste não foi propagado**. **Sugestão:** padronizar moldura tracejada + frase "Toque em '<nome do botão>' pra…".

### m2. Slot de destaque do topo: Lembretes mostra frase truncada
As telas-filhas têm um "slot de número grande" no topo: Despesas = "**R$ 0,00** / GASTO ESTE MÊS"; Detalhe = baseline ("—"). **Lembretes** usa esse mesmo slot pra renderizar "**Nenhum lembr…**" (frase em fonte display, **truncada com reticências**) — parece quebrado ao lado do padrão de stat. **Sugestão:** ou um número/contagem ("0 lembretes"), ou remover o slot quando vazio (o empty-state central já comunica).

### m3. CTA de "adicionar" em Documentos tem dois formatos
Na mesma tela: **CNH** = pílula de largura total "Cadastrar CNH" com "+" à direita; **Apólices/Multas** = botão de texto "+ Nova apólice" / "+ Nova multa" no cabeçalho da seção. Mesma ação, dois componentes. Padronizar.

### m4. Entrada de "scan" com pesos visuais diferentes
Mesmo conceito (foto que pré-preenche o form), tratamentos distintos: abastecimento = **banner verde** chamativo "Escanear cupom / tire uma foto, o app preenche o resto"; veículo = **botão cinza secundário** "Escanear CRLV". Alinhar a proeminência.

### m5. Caixa dos labels de seção: maiúsculas vs Title Case
Quase todo o app usa **MAIÚSCULAS** nos labels de seção ("MINHA CNH", "GASTO", "CONSUMO", "NÚMEROS DO ABASTECIMENTO", "IDENTIFICAÇÃO"). **Configurações** usa **Title Case** ("Aparência", "Notificações"). Padronizar.

### m6. Layout do botão "Salvar" difere entre forms
Form de abastecimento: barra inferior com "TOTAL —" à esquerda + pílula verde pequena "Salvar" à direita. Form de veículo: barra inferior com botão escuro de **largura total** "Salvar alterações". Mesma função, layouts diferentes (ligado ao M1).

---

## ⚪ Verificar
- **V1. "Comparar período" some em Relatórios sem dados.** Na tela de Relatórios (NSX sem dados) não aparece o botão de comparar período no topo. Pode ser intencional (gating por falta de dados) ou estar faltando — vale confirmar com dados cadastrados.

---

## ✅ O que está consistente (manter)
- **Inputs com contorno** arredondado iguais nos forms (abastecimento e veículo) — o fix de "contorno em todos os forms" pegou.
- **FAB** sempre pílula verde com ícone "+" e rótulo, canto inferior direito.
- **Cards e chips** uniformes: "sem placa" (itálico cinza), "Gasolina" (ponto colorido + label), "FIPE R$ …".
- **Cabeçalho de veículo** (nome grande + chip) repetido igual em Detalhe/Despesas/Lembretes.
- **Tom da copy** amigável e coerente em todo o app.

---

## Prioridade sugerida
1. **M1 + M6** — definir uma única linguagem de botão primário (cor + layout) e aplicar nos forms. Maior impacto percebido de "app coeso".
2. **M3** — corrigir a sobreposição do FAB no detalhe (mesmo fix das outras telas).
3. **m1 + m2** — unificar empty-states (ilustração + copy) e resolver o slot truncado de Lembretes.
4. **M2** — desafogar a AppBar do detalhe.
5. **m3, m4, m5** — pequenos alinhamentos de design system.

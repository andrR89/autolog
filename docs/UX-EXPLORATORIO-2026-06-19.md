# Teste Exploratório de UX — AutoLog (19/06/2026)

## ✅ REVALIDAÇÃO (19/06, após os 6 fixes do Code)

Retestei os 6 itens que reportei — **todos resolvidos**:

1. **FAB cobrindo o empty-state — RESOLVIDO.** Agora há padding inferior; o empty-state ("Nenhum abastecimento aqui ainda" + subcopy) rola e fica **acima** do FAB, sem sobreposição.
2. **Validação do form de abastecimento — RESOLVIDO (de forma diferente).** Não marca Litros/Preço inline, mas: (a) odômetro continua com erro inline; (b) há **snackbar global** "Verifique os campos obrigatórios destacados."; (c) **regra do trio** — exige ao menos 2 de 3 (litros/preço/total), com snackbar "Preencha ao menos 2 dos 3 campos…". Testei: com só o odômetro preenchido, **o save é bloqueado** (não cria mais abastecimento de 0 L). *Obs. menor: o feedback é um snackbar transitório; um destaque inline em litros/preço seria ainda mais claro.*
3. **CNH "Editar" sem CNH — RESOLVIDO.** Sem CNH cadastrada, só aparece "Cadastrar CNH" (o link "Editar" sumiu).
4. **CNH salvar vazio — RESOLVIDO.** Salvar tudo vazio agora **bloqueia** e mostra snackbar "Preencha ao menos um campo (número, categoria ou validade)." (confirmado no código `cnh_form_screen.dart`).
5. **FIPE inconsistente — RESOLVIDO.** Card e detalhe agora mostram "R$ 39.978" (formato igual).
6. **Copy do empty-state — RESOLVIDO.** Agora "Toque em "Novo abastecimento" pra começar a história deste carro." (referencia o botão, não o "+").

### ✅ "Sugerir lembretes" sem feedback — RESOLVIDO (reteste 19/06)
- Era: em **Documentos**, "**Sugerir lembretes**" sem CNH/apólice/multa não dava feedback nenhum.
- **Corrigido.** Agora mostra snackbar flutuante "**Cadastre uma CNH, apólice ou multa pra eu sugerir lembretes.**" (confirmado em tela e no código `personal_documents_screen.dart` L264-281: ramo `deduped.isEmpty` com mensagem orientadora — e variante "Nenhum lembrete novo para sugerir no momento." quando já há docs mas nada novo). Item fechado.

---

## (Relatório original — 19/06)

# Teste Exploratório de UX — AutoLog (19/06/2026)

**Tester:** Claude (Cowork) · **Ambiente:** Simulador iPhone 16e, iOS 26.3 · **Conta:** premium.0618@autolog.test

> Passada livre depois dos fixes, focada em **atrito de UX, copy e coisas estranhas** — não em bugs funcionais (esses estão em `ACHADOS-TESTE-2026-06-18.md`). Explorei áreas pouco cobertas antes: **Documentos (CNH/apólices/multas)** e **estados vazios/sem-dados** (veículo NSX com 0 km e sem abastecimentos).

## 🟠 Médio

### 1. FAB "Novo abastecimento" cobre o empty-state do veículo
- **Onde:** detalhe do veículo sem abastecimentos (ex.: NSX recém-criado).
- **O quê:** o botão flutuante verde **"Novo abastecimento" sobrepõe o texto** do empty-state — "Nenhum abastecimento **aqui ainda**" fica com a última linha coberta, e a subcopy ("Toque em + pra começar… carro.") aparece **partida atrás do botão**.
- **Por que importa:** é exatamente o primeiro momento do veículo (onboarding), e a tela já abre visualmente quebrada.
- **Sugestão:** padding inferior no conteúdo do empty-state (ou subir o ilustração/copy) pra não colidir com o FAB.

### 2. Form de abastecimento valida só o Odômetro (reincidente)
- Ao salvar vazio, **só "Odômetro" é sinalizado** ("Informe o odômetro" + borda vermelha). **Litros** e **Preço por litro** não acusam nada.
- **Risco:** se Litros/Preço forem obrigatórios, falta marcá-los; se forem opcionais, dá pra salvar um "abastecimento" com **0 L**, o que fura o cálculo de consumo. Decidir e tornar consistente.

## 🟡 Baixo

### 3. CNH: "Editar" aparece mesmo sem CNH cadastrada
- Na tela **Documentos → MINHA CNH**, há o botão "Cadastrar CNH" **e** um link "**Editar**" no cabeçalho da seção — os dois abrem o mesmo form. Sem CNH ainda, "Editar" não faz sentido (não há o que editar). Mostrar "Editar" só depois de existir uma CNH.

### 4. Form de CNH: tudo opcional + "Salvar" silencioso
- Todos os campos (Número, Categoria, Vencimento) são **opcionais**. Tocar em **"Salvar CNH" com tudo vazio volta sem feedback** nenhum (sem confirmação, sem aviso) — e provavelmente grava um registro vazio. Faltaria exigir ao menos um campo ou dar feedback ("nada pra salvar").

### 5. FIPE com formatação inconsistente entre card e detalhe
- Card da garagem: "**FIPE R$ 39.978**" (sem casas decimais). Detalhe do veículo: "**R$ 39.978,00**". Mesmo dado, formatação diferente. Padronizar (provavelmente intencional pra encurtar no card, mas vale alinhar).

## ⚪ Trivial / cosmético

### 6. Empty-state cita "+" mas o CTA é uma pílula "Novo abastecimento"
- A subcopy diz "Toque em **+** pra começar…", mas o botão é uma pílula rotulada "Novo abastecimento" (com ícone +). Pequeno descompasso de copy.

## ✅ Pontos positivos de UX (vale manter)
- Empty-states com **copy amigável e claro**: "AGUARDANDO BASELINE — Registre dois cheios e a média aparece aqui.", "Sem multas — bom motorista!", "Cadastre abastecimentos e despesas pra ver o gasto aqui."
- Relatórios de veículo **sem dados** não quebra: mostra placeholders e mensagens claras em cada card (valida o caso "sem dados suficientes").
- Menu "…" do card do veículo com **Editar / Excluir** direto — rápido e óbvio.
- Toque limpo no card abre o detalhe corretamente (a navegação inesperada que vi antes era resíduo de pilha, **não é bug**).

## 📌 Itens de UX já catalogados antes (continuam de pé)
- **Logout** mora na AppBar da home (ícone de seta), não em Configurações (roteiro 1.12 espera "Settings → Sair").
- **CTAs redundantes** em empty-states (botão grande + pílula flutuante) na garagem/lembretes/despesas.
- **Permissão de notificação** pedida ao abrir o app (fora de contexto), antes do onboarding.
- **Banner do scan** é verde com ✓ (roteiro esperava amarelo de "revise").
- **Eixo X dos gráficos** de Relatórios repete "mai" várias vezes (labels poluídos).

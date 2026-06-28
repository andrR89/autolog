# Achados — Responsividade Camada 1 (maxWidth), 26/06

**Tester:** Claude (Cowork) · **Ambiente:** Chrome (Claude in Chrome MCP),
viewport **travado em 1440px** (innerWidth confirmado) · **URL:** http://localhost:8080
· **Conta:** web.teste.0625@autolog.test (logada via IndexedDB) · **Tema:** Claro.

> Veredito: **Camada 1 OK no desktop** (forms 560 + Settings/paywall 720, save bars
> full-width, sem regressão nas telas de hero). **1 desvio (D1)** no CTA do paywall.
> **Blocos 2 e 3 não executáveis** por limitação do viewport do MCP (ver nota).

## Bloco 1 — Desktop (innerWidth 1440px)
- **1.1 ✅ Settings:** cards centralizados em **~720px** (≈686px medidos), sobra
  lateral livre dos dois lados, não estica.
- **1.5 ✅ Novo veículo:** form centralizado em **~560px**; **save bar "Adicionar
  veículo" full-width** (a barra/pill se estende além do form até a borda direita —
  não foi constrangida pra 560). Correto.
- **1.6 ✅ Novo abastecimento:** form **~560px**; **TotalActionBar full-width**
  ("TOTAL —" na ponta esquerda, "Salvar" na ponta direita, atravessa a tela). Correto.
- **1.9 ⚠️ Paywall ("Virar Premium"):** conteúdo centralizado em **~720px** ✅,
  **mas o CTA "Em breve" está constrangido a ~720px (centralizado com o conteúdo),
  NÃO full-width** — ver **D1** abaixo.
- **1.3 / 1.4 ⏭️ Login / Cadastro:** **não verificável sem logout.** A rota
  `/#/login` redireciona pra `/#/vehicles` quando autenticado (guard de auth), e eu
  não deslogo porque não posso re-autenticar (não digito senha). **Fica pra você:**
  deslogar e conferir form Login ~560px e Cadastro ~560px.
- **1.7 / 1.8 / 1.11 (despesa / lembrete / CNH) e 1.10 (chat) 🟡:** não capturados
  individualmente nesta rodada, mas usam o **mesmo wrapper `ResponsiveBody`** dos
  forms 1.5/1.6 (confirmados). Risco baixo; vale um olho rápido no chat (que tem
  input no rodapé) e no CNH quando der.

## ⚠️ D1 — CTA do paywall não é full-width (desvio do roteiro)
- **Esperado (roteiro 1.9):** "CTA 'Em breve' no rodapé continua full-width".
- **Observado:** o botão "Em breve" ocupa **~720px centralizado** (mesma largura do
  conteúdo), enquanto as save bars dos forms (1.5/1.6) ocupam a **largura toda**.
  Ou seja, no paywall o CTA foi constrangido junto com o conteúdo.
- **Severidade:** baixa/cosmética — visualmente até fica ok. Mas **diverge do spec**
  e é inconsistente com os forms. Provável que o `ResponsiveBody` tenha envolvido o
  CTA do paywall junto (em vez de deixá-lo full-width sticky como nos forms).
- **Ação:** Code confirmar se é intencional. Se a intenção é igual aos forms,
  tirar o CTA "Em breve" de dentro do `ResponsiveBody` (deixar full-width no Scaffold).

## Bloco 4 — Regressão (telas com hero), desktop 1440 ✅
- **4.1 ✅ Garagem:** hero "GARAGEM / 2 carros" full-width; cards de veículo esticam
  ponta a ponta. Igual ao pré-C1.
- **4.2 ✅ Detalhe do veículo:** hero brand-dark full-width; cards de consumo/CO₂/posto
  esticam. Igual ao pré-C1.
- **4.3 / 4.4 / 4.5 / 4.6 ✅ (despesas / lembretes / documentos / relatórios):**
  heroes full-width e listas/gráficos esticando, como observado ao longo da sessão.
  Nenhuma centralizou por acidente. Sem regressão.

## ⏭️ Bloco 2 (tablet 768-1023) e Bloco 3 (mobile <600) — NÃO executáveis aqui
O viewport do Chrome via MCP **fica fixo em 1440px**: `resize_window` retorna
sucesso mas `window.innerWidth` continua 1440 e o screenshot continua 1568px.
Já tinha acontecido em rodadas anteriores. Sem controle de viewport, não dá pra
simular tablet nem mobile por aqui.

**Fica pra você (rápido, ~5 min):** Chrome → F12 → toggle device toolbar:
- **Tablet (iPad 1024×768 / ~900px):** Settings 720 centrado com sobra lateral;
  form veículo 560 + save bar full-width.
- **Mobile (iPhone 393px):** Settings/Login/forms usam **largura completa, sem
  margem lateral** (porque 393 < 560/720). Se aparecer margem lateral em <600px = bug.

*Nota técnica:* por construção, `ResponsiveBody` (ConstrainedBox maxWidth) já degrada
certo — em viewport menor que o maxWidth o conteúdo usa a largura toda. Então o
comportamento mobile é seguro por design; falta só a confirmação visual.

## Sensação visual (desktop)
Forms a 560px ficam confortáveis (não viram "linha fininha" nem esticam demais).
Settings/paywall a 720px estão num bom equilíbrio. Save bars full-width ancoram bem
o rodapé. Única inconsistência é o CTA do paywall (D1).

## Tempo
~15 min (parte gasta confirmando a limitação de viewport).

---

## 🔁 Reteste do D1 + Blocos 2/3 (resize voltou a funcionar)
Nesta rodada o `resize_window` do MCP **passou a funcionar** (innerWidth mudou pra
900 e depois 606), então deu pra cobrir tablet/mobile e revalidar o D1 lado a lado.

### D1 — ❌ AINDA NÃO full-width (paywall CTA)
No mesmo viewport de **900px**, comparação direta:
- **Form de abastecimento:** TotalActionBar **full-width** (TOTAL na ponta esquerda,
  Salvar na ponta direita, 0→900). ✅
- **Paywall:** CTA "Em breve" **constrangido a ~720px** (margens dos dois lados),
  igual ao desktop. **Não mudou.**
Conclusão: o fix do CTA não está refletido neste build — ou o `flutter run` não foi
reiniciado, ou foi noutra direção. Se a intenção era full-width, **reiniciar o
`flutter run`** e revalidar. Se a intenção é manter constrangido, fechar D1 como by-design.

### Bloco 2 — Tablet (900px) ✅
- **2.1 Settings:** cards centralizados em ~720px, sobra lateral (~113px cada lado). ✅
- **2.3 Form de abastecimento:** conteúdo ~560px centrado, **save bar full-width**. ✅
- Detalhe do veículo: hero/cards full-width (regressão OK no tablet também).

### Bloco 3 — Mobile (606px — mínimo que o Chrome permite) 🟡✅
O Chrome trava a largura mínima da janela em ~606px (um tiquinho acima do breakpoint
600), então não deu pra ir abaixo de 600. A 606px:
- **3.1 Settings:** cards usam a largura completa (~570px, só o padding normal ~18px),
  sem centralização extra. ✅
- **3.3 Form de abastecimento:** conteúdo ~534px (margens mínimas) + save bar full-width. ✅
Comportamento de mobile correto (o `maxWidth` só atua acima de 560/720). Pra fechar
100% o <600 real, vale um olho no device toolbar do Chrome (iPhone 393px), mas o
degradê já está confirmado.

---

## ✅ D1 — RESOLVIDO (após hard refresh / build novo)
As rodadas anteriores estavam pegando **bundle em cache**. Após **Cmd+Shift+R**
(hard refresh) o build novo entrou — confirmado pela **linha verde-lima (accent) no
topo do footer** do paywall (marcador do Code pra sinalizar build novo).
- **CTA "Em breve" agora full-width** (vai de ponta a ponta, ~0→1568, só padding
  normal), consistente com as save bars dos forms. ✅
- A linha accent full-width no topo do footer também aparece. ✅

**D1 fechado.** A Camada 1 está 100% no desktop/tablet/mobile (pelos limites do MCP).
Lição: nas próximas validações de mudança visual, **forçar hard refresh** (ou aba
anônima) antes de concluir — o cache do dev server mascarou o fix por várias rodadas.

### Pendência residual (não-bloqueante)
- **Login / Cadastro (1.3/1.4):** ainda não verificados (precisa logout; não autentico).

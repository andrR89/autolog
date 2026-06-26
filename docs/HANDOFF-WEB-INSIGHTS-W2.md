# Handoff — Web Sprint 8: Insights IA (5.2) + W2 (overflow cosmético)

> Reteste web 25/06, conta `web.teste.0625@autolog.test`, Chrome via MCP,
> `flutter run -d chrome --web-port=8080`. **W1 (Drift web) já resolvido** —
> ver `docs/HANDOFF-WEB-DRIFT.md`. Achados completos em
> `docs/ACHADOS-WEB-2026-06-25.md`.

> 🔁 **REVALIDAÇÃO (25/06, 2ª passada):** ambos **ainda reproduzem** — ou o fix
> não entrou nesse build, ou o `flutter run` não recompilou.
> - **I1 ❌ ainda falha** — "Não conseguimos analisar agora"; confirmado de novo
>   que **nenhuma request sai pra Supabase/`functions`** (`performance.getEntriesByType('resource')`
>   só lista o `.js` da lib). Falha 100% no client antes do HTTP.
> - **W2 ❌ ainda reproduz** — "BOTTOM OVERFLOWED BY 47 PIXELS" no empty-state do
>   fuel (veículo sem abastecimento, desktop largo).
> - **➕ Novo — sync caiu pra `cloud_off`:** no início da sessão deu `cloud_done`;
>   após reload virou vermelho persistente. A UX amigável funciona ("Sem conexão
>   — toque pra tentar"), mas o sync não completa. Pode ser backend/JWT fora do ar
>   nesta sessão ou regressão do rebuild — checar `dart_define`/Supabase do
>   `flutter run` atual.

> ✅ **REVALIDAÇÃO AGENDADA (3ª passada) — 25/06/2026 ~19:49 (horário local) / 22:49 UTC:**
> - **I1 ✅ RESOLVIDO.** "Analisar agora" agora abre estado de loading (skeleton) e
>   retorna **resultado real da IA**: seção "LEMBRETES SUGERIDOS (3)" — *Lavagem do
>   veículo*, *Revisão e manutenção preventiva (60000 km)*, *Verificação de consumo
>   de combustível* —, "Nenhum padrão identificado no histórico" e seções
>   MANUTENÇÃO/ASSISTENTE. **Nenhum snackbar de erro.** A request **agora sai pra
>   Supabase**: o `read_network_requests` capturou
>   `OPTIONS https://vdtlldfklcrtpuumfkbm.supabase.co/functions/v1/analyze-history → 200`
>   (preflight CORS liberado) e a Edge Function respondeu com os dados que renderizaram
>   na UI. Antes (2ª passada) **nenhuma** request saía. Fix confirmado neste build.
>   *(Obs.: `performance.getEntriesByType('resource')` continua só listando o `.js` da
>   lib porque a resposta cross-origin não expõe Timing-Allow-Origin; a evidência veio
>   do painel de network, não do `performance`.)*
> - **W2 ❌ AINDA REPRODUZ.** No detalhe de "W2 Check" (sem abastecimento), o
>   empty-state "Nenhum abastecimento" ainda mostra a faixa
>   **"BOTTOM OVERFLOWED BY 47 PIXELS"** (amarelo/preto), confirmada por zoom. Cosmético,
>   mas não corrigido. Se o fix do overflow já foi codado, é provável que **não tenha
>   entrado neste build** — o `flutter run -d chrome` precisa de **kill + rerun** (não
>   basta hot reload) pra pegar mudança de layout/provider/asset.
> - **Sync ❌ `cloud_off` vermelho** (mesmo estado da 2ª passada). Indicador no topo da
>   garagem segue cloud_off. Em ambiente local de teste pode ser esperado (sem
>   round-trip Supabase de sync nesta sessão), mas vale confirmar com `dart_define`/JWT.
> - **Nota de ambiente:** o build é DDC (debug, 1922 módulos). Um tab novo aberto via
>   MCP não montava o `flutter-view` (o bootstrap esperava a conexão DWDS, que o tab
>   original logado retinha). Foi necessário disparar `window.$dartRunMain()` no tab
>   automatável pra inicializar o app. Não afeta os veredictos — apenas registro do
>   procedimento.

---

## ⚠️ I1 — Insights IA falha no web ("Não conseguimos analisar agora")

**Severidade:** média. Não quebra (erro tratado), mas a feature de IA não entrega.
**Onde:** Detalhe do veículo → menu ⋮ → **Insights** → botão **"Analisar agora"**.
**Plataforma:** Web. (No mobile não retestei nesta rodada.)

### Sintoma
Ao tocar "Analisar agora", aparece o snackbar amigável:
> "Não conseguimos analisar agora. Tente em alguns minutos."

O tratamento de erro do client está **correto** (não vaza stack, não crasha).
O problema é a chamada em si falhar.

### Dado de diagnóstico (web)
Inspecionei `performance.getEntriesByType('resource')` logo após a falha:
- **Nenhuma** request pra `*.supabase.co`, `/functions/`, `/rest/` apareceu para
  a chamada de insights.
- Pra comparar, o **sync funcionou** na mesma sessão (cloud_done), então auth +
  Supabase REST estão OK no web.

Isso aponta pra uma de duas hipóteses (Code confirma com os logs):
1. **A chamada falha/curto-circuita antes do round-trip HTTP** — ex.: checagem
   de cota local, branch que depende de plugin mobile-only, ou exceção montando
   o request (algo platform-specific que vira no-op/erro no web).
2. A request até sai mas é abortada (CORS na Edge Function de insights, ou a
   função retorna erro) e a entrada de performance foi evictada/limpa na
   navegação. *(menos provável, já que o sync apareceria com o mesmo problema.)*

### O que checar (Code)
- Logo do client no caminho do "Analisar agora" (qual exceção cai no catch que
  dispara o snackbar). Logar a causa real antes do snackbar genérico ajudaria.
- Se a feature de insights usa cota (`usage_quota`) — a conta de teste é nova,
  pode estar batendo em checagem de quota/entitlement que falha no web.
- Se o pipeline de insights toca algum plugin mobile-only (ex.: leitura de algo
  nativo) antes de chamar a Edge Function.
- Logs da Edge Function de insights no Supabase (recebeu request? respondeu 4xx/5xx?).
- CORS: a Edge Function de insights está liberada pra `http://localhost:8080`?

### Repro
1. Login web, criar veículo + 2 abastecimentos cheios (pra ter histórico mínimo).
2. Detalhe → ⋮ → Insights → "Analisar agora".
3. Observar o snackbar + console + network.

---

## 🟡 W2 — Overflow cosmético no empty-state do fuel (detalhe do veículo)

**Severidade:** baixa (cosmético).
**Onde:** Detalhe do veículo **sem abastecimentos** → card de empty-state
"Nenhum abastecimento".
**Plataforma:** Web desktop largo (janela ~1568px).

### Sintoma
A faixa de debug do Flutter **"BOTTOM OVERFLOWED BY 47 PIXELS"**
(amarelo/preto) aparece sob o card de empty-state do fuel. Renderiza, mas o
layout estoura na vertical.

### Provável causa / fix
Coluna com altura fixa / `Spacer`/`Expanded` que não cabe na viewport desktop
larga (mais baixa proporcionalmente). Provavelmente some no viewport mobile.
É da família da onda de responsividade (Bloco 9 do roteiro web), mas como
mostra a faixa de debug do framework, vale envolver o empty-state num
`SingleChildScrollView`/`LayoutBuilder` ou afrouxar a constraint de altura.

### Repro
Criar veículo, abrir o detalhe **antes** de cadastrar abastecimento, em janela
desktop larga.

---

## Status do roteiro web (resumo)
- ✅ Bloco 2 (persistência Drift WASM + consumo 16,7 km/l), Bloco 3.1 (sync),
  Bloco 4.4/4.5/4.6/4.7/4.8 (despesas, lembretes, relatórios fl_chart, idioma, tema).
- ⚠️ Bloco 5.2 (insights) → I1 acima.
- ⏭️ Faltam: editar/excluir veículo (4.1/4.2), diálogo excluir conta (4.9),
  scan câmera (5.1), Calendar OAuth (5.3), export CSV/PDF/JSON (5.4-5.6, dependem
  de liberar download), TTS (5.9), cross-device mobile (3.2/3.3).

## ✅ W2 — RESOLVIDO (4ª passada, reteste manual 25/06)
"W2 Check" (sem abastecimento) → empty-state agora exibe "Nenhum abastecimento aqui ainda. / Toque em 'Novo abastecimento' pra começar a história deste carro." **SEM a faixa "BOTTOM OVERFLOWED BY 47 PIXELS"**. Overflow eliminado. Copy também mudou ("...aqui ainda.") confirmando build novo. **I1 e W2 ambos fechados.** (Sync seguia cloud_off neste reteste — ambiente local, conferir dart_define/JWT.)

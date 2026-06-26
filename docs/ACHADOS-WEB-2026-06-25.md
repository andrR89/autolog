# Achados — Web port (Sprint 8), 25/06

**Tester:** Claude (Cowork) · **Ambiente:** Chrome (Claude in Chrome MCP), janela 1440×900 · **URL:** http://localhost:8080

> Status: **pré-login OK; pós-login BLOQUEADO por bug crítico.** Você logou (conta `web.teste.0625@autolog.test`) e a garagem **não carrega**: o Drift não abre no web. Blocos 2–5 ficam bloqueados até a correção. Detalhe + fix em `docs/HANDOFF-WEB-DRIFT.md`.

## ✅ W1 — RESOLVIDO (reteste 25/06, após restart do `flutter run`)
Garagem carrega limpa (empty-state "Sua garagem está esperando", sem banner vermelho). `indexedDB.databases()` retorna `[{name:'autolog', version:1}]` → Drift WASM abriu e criou o banco. Bloco 2.3 já validado. Fix aplicado: `DriftWebOptions` em `database.dart` + `web/sqlite3.wasm` (731 KB) e `web/drift_worker.js` (354 KB). Histórico abaixo ⤵️

## 🔴 W1 — CRÍTICO (original): Drift não abre no web (garagem não carrega pós-login)
- **Sintoma:** login funciona → `/#/vehicles` mostra banner vermelho `Invalid argument(s): When compiling to the web, the` `web` `parameter needs to be set` + estado de erro "Não foi possível carregar sua garagem". "Tentar novamente" só repete o erro.
- **Causa-raiz:** `lib/data/local/database.dart:125` chama `driftDatabase(name: 'autolog')` **sem** o parâmetro `web:` (obrigatório no web no `drift_flutter ^0.2.4`). Além disso, os assets `web/sqlite3.wasm` e `web/drift_worker.js` **não existem** no projeto. O comentário do provider promete o caminho web (WasmDatabase/IndexedDB), mas ele nunca foi implementado.
- **Por que o pré-login passou:** nenhuma query Drift roda antes do login; o erro só aparece quando a primeira tela toca o banco.
- **Stack:** `SyncIndicator` (`sync_indicator.dart:19` → `syncStatusProvider`) é só o primeiro a tocar o banco; a garagem estoura igual.
- **Fix completo:** `docs/HANDOFF-WEB-DRIFT.md` (passar `DriftWebOptions` + adicionar os 2 assets em `web/`).
- **Impacto:** bloqueia Blocos 2 (persistência), 3 (sync), 4 (features), 5 (limitações). Web é inutilizável pós-login até cair.

## Bloco 1 — Boot e auth
- **1.1 ✅** http://localhost:8080 abre direto no **onboarding** (`/#/onboarding`), slide "Bem-vindo ao AutoLog / Acompanhe consumo, custos e lembretes do seu carro. Tudo offline.", **4 dots**, "Pular"/"Próximo". Sem erro vermelho na tela.
- **1.2 ✅** Console no boot: aparece só **"Exeption on setup: PlatformException(...)"** (2×, uma por load) — é o PostHog (analytics off no web, ignorado por design). **NÃO** apareceu Drift/sqlite, dart:io/ffi, path_provider, Sentry, 404 nem CORS.
- **1.3 ✅ (com ressalva esperada)** "Pular" → `/#/login` renderiza. No desktop os campos E-mail/Senha e os botões (Entrar, Continuar com Google/Apple) **esticam a largura toda (~1500px)** — gigante, como o roteiro previu. Não é bug (Bloco 9).
- **Network:** nenhuma request falhando (só `assets/shaders/ink_sparkle.frag` 200). Sem 404/CORS.
- **1.4 / 1.5 / 1.6 ⏭️** criar conta / persistência de sessão / logout-login → **precisa de você** (não posso criar conta nem autenticar).

## Bloco 6 — Console (parcial, pré-login)
Até o login, só o **PostHog "Exeption on setup"** (esperado). Nada das categorias "reporta" (dart:io/ffi, path_provider MissingPlugin, flutter_local_notifications, Sentry, 404 de assets, CORS/Supabase) apareceu. Vou continuar com o console aberto nos Blocos 2–5.

## Bloco 9 — Responsividade (observação)
No desktop (1440px+) a UI mobile estica feio: a tela de login vira uma coluna única com campos e botões de ~1500px de largura, logo + tagline num "header band" no topo e muito espaço morto. Renderiza e é usável, mas claramente pensado pra mobile — confirma a necessidade da onda de responsividade (max-width nos forms etc.). *(Resize pra 768px via MCP não refletiu no screenshot — capturei só o desktop; o comportamento de tablet deve ser a mesma coluna esticada, só mais estreita.)*

---

## Bloco 2 — Persistência local (Drift WASM) ✅
- **2.1 ✅** Criei veículo manual (Web Teste / Fiat Uno / Flex / 50.000 km). Validação do form funciona (odômetro obrigatório → snackbar "Verifique os campos obrigatórios destacados"). Aparece na garagem ("1 carro").
- **2.2 ✅** F5 (reload) → veículo **persiste**. Drift WASM/IndexedDB grava de verdade.
- **2.3 ✅** `indexedDB.databases()` → `[{name:'autolog', version:1}]`.
- **2.4 ✅ (Regra de Ouro)** 2 cheios (50.000 e 50.500 km, 30 L cada) → **"ÚLTIMO CONSUMO 16,7 km/l"** (500÷30 = 16,67). Antes do 2º cheio mostrava "aguardando baseline / Registre dois cheios" — correto. Custo R$ 0,60/km (combustível). Idêntico ao mobile.
- **2.5 ⏭️** multi-aba (mesma origem) não testado ao vivo, mas IndexedDB é por origem → comportamento garantido.

## Bloco 3 — Sync com Supabase ✅ (parcial)
- **3.1 ✅** Indicador na AppBar: criou veículo → `cloud_upload` (pendente); toquei → "Sincronizando…" (spinner) → **"Sincronizado" (cloud_done)**. Web→Supabase funciona.
- **3.2/3.3 ⏭️** cross-device com mobile (mesma conta) → precisa de você logar no app mobile com `web.teste.0625@autolog.test`.
- **3.4 ⏭️** snackbar de erro (cloud_off) — não forcei offline.

## Bloco 4 — Features ✅
- **4.4 ✅ Despesas:** adicionei "Lavagem teste web / R$ 50". "GASTO ESTE MÊS R$ 50,00 / 1 despesa". Depois, no detalhe, o **custo total/km subiu pra R$ 0,70/km** (incluindo a despesa) — cálculo certo.
- **4.5 ✅ Lembretes:** criei "Trocar oleo teste web" por data (25/07/2026) → "1 pendente". **Nenhum popup de permissão de notificação do navegador apareceu** — o plugin de notificação local é no-op no web (mobile-only); o lembrete salva normalmente. Comportamento esperado (sem service worker = sem push, Bloco 5.8).
- **4.6 ✅ Relatórios:** 3 gráficos `fl_chart` renderizam no web — BarChart "Gasto por mês", LineChart "Consumo/Média mensal" (16,7 km/L), LineChart "Preço/litro Evolução" (R$ 5,00/L). + "Meus postos".
- **4.7 ✅ Idioma → English:** muda na hora ("Settings / Go Premium / Unlimited scans and insights. / Language / English"). Reativo, igual mobile.
- **4.8 ✅ Tema claro/escuro:** troca instantânea (fundo creme ↔ escuro).
- **4.1/4.2/4.9 ⏭️** editar veículo / excluir (soft delete) / diálogo "Excluir minha conta" — não testados ainda.

## Bloco 5 — Features que podem falhar
- **5.2 ⚠️ Insights IA:** "Analisar agora" → snackbar amigável **"Não conseguimos analisar agora. Tente em alguns minutos."** Não quebrou, mas a chamada falhou. Causa não confirmada (dado insuficiente? cota? Edge Function no web? CORS?). **Precisa você olhar os logs do backend** pra distinguir. O tratamento de erro do client está bom.
- **5.1 / 5.3 / 5.4 / 5.5 / 5.6 / 5.9 ⏭️** scan câmera / Calendar OAuth / export CSV / PDF / JSON / TTS — **não testados**. Downloads (CSV/PDF/JSON) eu seguro até você liberar (regra: baixar arquivo exige tua autorização explícita). Scan precisa de permissão de câmera do navegador.

## 🟡 W2 — cosmético: overflow no empty-state do fuel (detalhe do veículo)
Antes de cadastrar abastecimentos, o card de empty-state ("Nenhum abastecimento") mostra a faixa amarela/preta do Flutter **"BOTTOM OVERFLOWED BY 47 PIXELS"** em tela desktop larga (1568px). Renderiza, mas o layout estoura. Provável que suma num viewport mobile — é da mesma família da onda de responsividade (Bloco 9), mas como aparece a faixa de debug, vale anotar.

## Bloco 6 — Console (durante Blocos 2–5)
Sem erros novos de Drift/sqlite, dart:io/ffi, path_provider, Sentry, 404 ou CORS durante a navegação logada. Só o PostHog "Exeption on setup/identify/capture" (esperado, analytics off no web). *(A falha do Insights 5.2 não joguei trace completo aqui — vale você cruzar com os logs do backend.)*

## ✅ REVALIDAÇÃO AGENDADA (3ª passada) — 25/06/2026 ~19:49 local / 22:49 UTC
Reteste no build web (`flutter run -d chrome`, localhost:8080, conta `web.teste.0625@autolog.test`, veículos "Web Teste" e "W2 Check").

- **I1 (Insights IA) → ✅ RESOLVIDO.** Web Teste → ⋮ → Insights → "Analisar agora" mostra loading (skeleton) e retorna **resultado real da IA**: "LEMBRETES SUGERIDOS (3)" (Lavagem do veículo; Revisão e manutenção preventiva 60000 km; Verificação de consumo de combustível) + "Nenhum padrão identificado". **Sem snackbar de erro.** A request **agora chega ao backend**: network capturou `OPTIONS .../functions/v1/analyze-history → 200` e a Edge Function respondeu. Na 2ª passada nenhuma request saía (falha no client antes do HTTP) — corrigido.
- **W2 (overflow cosmético) → ❌ AINDA REPRODUZ.** "W2 Check" (sem abastecimento) → empty-state "Nenhum abastecimento" segue com a faixa **"BOTTOM OVERFLOWED BY 47 PIXELS"** (confirmada por zoom). Provável que o fix não tenha entrado neste build — exige **kill + rerun** do `flutter run` (hot reload não basta).
- **Sync → ❌ `cloud_off` vermelho** (igual 2ª passada). Indicador no topo da garagem segue cloud_off; pode ser esperado em ambiente local, confirmar `dart_define`/JWT.
- **Nota:** build DDC debug; tab novo via MCP não montava o app (bootstrap esperando DWDS, retido pelo tab original logado) — usei `window.$dartRunMain()` pra inicializar. Não afeta os veredictos.

## ⏭️ Pendente pra fechar o roteiro
1. **Você libera os downloads?** Aí eu testo export CSV (5.4), PDF (5.5) e JSON/backup (5.6) — todos baixam arquivo, então preciso do teu OK.
2. **Editar/excluir veículo (4.1/4.2)** e **diálogo "Excluir minha conta" (4.9)** — testo na sequência (no delete-account eu NÃO confirmo de verdade).
3. **Insights 5.2** — me diz se quer que eu investigue o trace no console/network, ou se você olha o backend.
4. **Cross-device (3.2/3.3)** — depende de logar no mobile com a mesma conta.

## ✅ W2 — RESOLVIDO (4ª passada, reteste manual 25/06)
"W2 Check" (sem abastecimento) → empty-state agora exibe "Nenhum abastecimento aqui ainda. / Toque em 'Novo abastecimento' pra começar a história deste carro." **SEM a faixa "BOTTOM OVERFLOWED BY 47 PIXELS"**. Overflow eliminado. Copy também mudou ("...aqui ainda.") confirmando build novo. **I1 e W2 ambos fechados.** (Sync seguia cloud_off neste reteste — ambiente local, conferir dart_define/JWT.)

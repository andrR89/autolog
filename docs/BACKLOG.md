# BACKLOG.md — AutoLog MVP

> Sequenciado por dependência. Cada item é uma tarefa fechável por um agente.
> Marque `[x]` ao concluir. Não pule etapas — a fundação (sync, dados) sustenta tudo.

---

## Sprint 0 — Fundação
*Objetivo: esqueleto que compila, persiste local e tem identidade de usuário.*

- [x] **0.1** Setup do projeto Flutter + estrutura de pastas (`ARCHITECTURE.md §5`), lint, `flutter analyze` limpo.
- [x] **0.2** Configurar Drift: schema das 5 tabelas (`vehicles`, `fuel_entries`, `expenses`, `reminders`, `usage_quota`) com campos de sync (`id` UUID, `updated_at`, `sync_status`, `deleted_at`).
- [x] **0.3** Modelos de domínio (freezed + json_serializable) para cada entidade.
- [x] **0.4** Projeto Supabase: tabelas espelho, RLS por `user_id`, Auth (email/senha + Google).
- [x] **0.5** Tela de login/cadastro + fluxo de sessão (Supabase Auth).

## Sprint 1 — Núcleo de dados e sync
*Objetivo: criar/ler/editar veículo localmente e sincronizar.*

- [x] **1.1** Repositório de `vehicles` (CRUD local via Drift, soft delete).
- [x] **1.2** `SyncService`: push de `pending`, pull incremental por `updated_at`, last-write-wins. **Com testes.**
- [x] **1.3** CRUD de veículo na UI (criar, listar, editar, "excluir"). Validar odômetro inicial.
- [x] **1.4** Indicador de status de sync na UI (pending/synced/offline).

## Sprint 2 — Abastecimento manual + consumo
*Objetivo: o coração do app funcionando sem IA ainda.*

- [x] **2.1** Repositório de `fuel_entries` (CRUD local + sync).
- [x] **2.2** **Service de cálculo de consumo** seguindo `PRD.md §6`. **Testes obrigatórios** cobrindo: primeiro abastecimento, parciais entre cheios, sequência de cheios, odômetro não-monotônico.
- [x] **2.3** Formulário de abastecimento manual (litros, preço/litro, total auto-calculado, odômetro, flag tanque cheio, tipo combustível).
- [x] **2.4** Lista de abastecimentos + exibição de consumo (km/l, custo/km) ou "—" quando sem baseline.

## Sprint 3 — Scan por IA (a tese)
*Objetivo: foto → formulário pré-preenchido. O diferencial do produto. O manual continua sendo o caminho base.*

- [x] **3.0** Abstração `ImageSource` (interface única; impl mobile = câmera). Web vem na fase 8.
- [x] **3.1** Edge Function no Supabase: recebe imagem, checa `usage_quota`, chama Claude Haiku 4.5, retorna JSON estruturado. Parse defensivo. **Chave da API só aqui.** *(código pronto + provider switched; **deploy pendente** — André instala CLI e roda `supabase functions deploy scan-receipt`)*
- [x] **3.2** Captura de foto no app + compressão/redimensionamento antes do upload.
- [x] **3.3** Fluxo de scan de cupom: foto → loading → formulário **pré-preenchido para revisão** → confirmar → salvar. Marcar `source = ai_scan`. **Fallback manual sempre acessível no mesmo formulário.** *(implementado com `MockScanService`; trocar pelo `RealScanService` na 3.1)*
- [ ] **3.4** OCR de odômetro on-device (ML Kit) — só dígitos, preenche o campo odômetro. Só mobile.
  - ⚠️ **Dependência removida do `pubspec` no Sprint 0** (`google_mlkit_text_recognition`): o ML Kit não suporta arm64 no **simulador iOS (Apple Silicon)**. Re-adicionar aqui e **testar o OCR em device físico** (iPhone real) ou emulador Android. Abstrair atrás de interface pra não quebrar o build do simulador.
- [x] **3.5** Tratamento de cota esgotada (free): mensagem + CTA para premium + opção de seguir no manual.

## Sprint 4 — Despesas e lembretes
- [x] **4.1** Repositório + CRUD + UI de `expenses` (categorias, valor, data).
- [x] **4.2** Repositório + CRUD + UI de `reminders` (por km / por data).
- [x] **4.3** Notificações locais (flutter_local_notifications) disparando lembretes.
- [x] **4.4** Lógica: lembrete por km dispara quando odômetro registrado ≥ `due_km`.

## Sprint 5 — Relatórios
- [x] **5.1** Query agregada: gasto total por mês (combustível + despesas).
- [x] **5.2** Query agregada: consumo médio (km/l) ao longo do tempo.
- [x] **5.3** Query agregada: evolução do preço/litro.
- [x] **5.4** Telas de relatório com gráficos (fl_chart). *Gating free/premium fica pro Sprint 6 (paywall).*

## Sprint 6.D — Sync das 3 entidades restantes (dívida técnica pré-lançamento) ✅

- [x] **6.D-fuel** — Sync de `fuel_entries` (façade + service + remote source, JOIN com vehicles, RLS server-side). 11 testes.
- [x] **6.D-expenses** — Sync de `expenses` (mesmo padrão). 11 testes.
- [x] **6.D-reminders** — Sync de `reminders` (mesmo padrão). 11 testes.
- [x] **6.D-orchestrator** — `GlobalSyncService` (executa serial vehicles → fuel → expenses → reminders, agrega `GlobalSyncResult`, captura exceções por entidade) + `SyncStatusNotifier` agora soma pendentes das 4 entidades. 7 testes.

Resultado: 333 testes verdes, `flutter analyze` limpo, iOS sim builds.

## Sprint 6.E — Expandir cadastro do veículo (pré-requisito da IA) ✅

- [x] **6.E.1** Adicionar `year`, `uf`, `color` em `Vehicle` (freezed + Drift schema v2 com `onUpgrade` + mappers + JSON).
- [x] **6.E.2** ~~Lista hardcoded FIPE~~ — adiado pra post-MVP (texto livre por ora; ver _Post-MVP_ abaixo).
- [x] **6.E.3** Form de cadastro/edição: 5 campos (make/model/year/uf/color) + validators (`validateYear`, `validateUf`, `normalizeUf`, `brUfs`).
- [x] **6.E.4** Backfill: veículos legados ficam com `null`; `vehicle_card` mostra "Honda Civic 2018" só quando preenchidos.
- [ ] **6.E.5** ⚠️ **Pendente Diretor**: aplicar SQL no Supabase remoto (ver bloco abaixo).

```sql
-- Sprint 6.E — adicionar campos opcionais ao Vehicle (executar no Supabase)
ALTER TABLE public.vehicles ADD COLUMN year integer;
ALTER TABLE public.vehicles ADD COLUMN uf text;
ALTER TABLE public.vehicles ADD COLUMN color text;
```
Resultado: 355 testes verdes, analyze limpo, iOS build OK.

## Sprint 6.F — Scan de despesa (generalizar pipeline)

- [ ] **6.F.1** Refatorar `ScanService` pra suportar 2 modos: `fuel` (existente) e `expense` (novo).
- [ ] **6.F.2** Edge function `scan-expense` com prompt específico: extrai valor, data, categoria, descrição, tipo de documento (cupom/boleto/NF). Detecta IPVA/licenciamento.
- [ ] **6.F.3** UI: botão "Escanear comprovante" na criação de despesa (espelha pattern do fuel).
- [ ] **6.F.4** Pipeline: foto/upload → IA → form pré-preenchido → user confirma (Regra #3). Fallback manual continua (Regra #3b).
- [ ] **6.F.5** Cota: definir se compartilha `scan_count` com fuel ou separada. Validada server-side.
- [ ] **6.F.6** Testes: parse defensivo (JSON malformado, campos null, categoria desconhecida → "outros"), cota, fallback.

## Sprint 6.F — Scan de despesa ✅

Implementação completa, edge function `scan-expense` deployada em produção.

## Sprint 6.G — Insights de IA (predição sob demanda) ✅

- [x] **6.G.1** Edge function `analyze-history` (auth JWT, busca 36 meses, Haiku 4.5, parse defensivo, shape validation).
- [x] **6.G.2** Tela `InsightsScreen` + botão "Insights" no header do detalhe do veículo (`fuel_history_screen`) com estados empty/loading/success/quota/error.
- [x] **6.G.3** Cota nova `analysis_count` (3/mês free), gating server-side, incremento condicional (só se útil).
- [x] **6.G.4** Dedupe puro (`dedupe.dart`): título normalizado (lower + sem acento) + janela de ±14 dias em dueDate OU match exato em dueKm; soft-deleted ignorados.
- [x] **6.G.5** 26 testes novos verdes (parse defensivo + service pipeline + dedupe).

Migration 0003 aplicada e edge function `analyze-history` deployada em produção.

### Débito técnico identificado (corrigir antes do go-live)

> Em ambos `scan-receipt`/`scan-expense` (que compartilham `scan_count`) e `analyze-history` (`analysis_count`): quando o mês vira, o primeiro upsert sobrescreve `month` mas não zera o contador da outra função → vazamento. Cenário raro; corrigir lendo primeiro e enviando ambos os contadores zerados quando detecta mês novo. Sprint pequena (1 patch em cada edge fn + teste manual).

---

# Plano completo pré-monetização — Ondas 1 a 3

> Decisão Diretor (26/05/2026): fazer **TUDO** abaixo antes de monetizar.
> Cada sprint inclui guidelines de UX no spec (não há rodada de polish separada).
> Itens marcados ⭐ = alto valor / baixo esforço (priorizar dentro da onda).

## ONDA 1 — Cadastro rico do veículo

> A fundação. As ondas 2 e 3 dependem dos dados extras adicionados aqui.

- [x] **6.H** Tipo (carro/moto) + specs técnicos ✅ — `VehicleType` enum, 4 campos novos, Drift v3 + migration onUpgrade, validators, form com seletor visual + seção colapsável, vehicle card com ícone do tipo. **426 testes verdes.** Migration `0004_vehicle_type_and_specs.sql` a deployar.
- [x] **6.I** ⭐ FIPE autocomplete ✅ — API parallelum v2, cache Drift TTL 7d, fallback stale offline, BottomSheet 3 passos, highlight verde fading, chip valor no card. **449 testes verdes.** Migration `0005_vehicle_fipe.sql` a deployar.
- [x] **6.J** Histórico FIPE ✅ — tabela `fipe_history` (PK composta), snapshot automático no save FIPE, `FipeHistoryChart` (4 estados: 0/1/2+/13+ pontos), LineChart `fl_chart`, badge YoY verde/vermelho. **465 testes verdes.** Local-only no MVP — sync entre devices + cron mensal ficam pós-MVP.
- [x] **6.K** Scan CRLV ✅ — Edge fn `scan-crlv` aceita imagem ou PDF (CRLV-e), Haiku 4.5 com message type condicional, validators server-side (plate Mercosul/antigo, RENAVAM 9-11 dig, chassi 17 alfanum). `file_picker` adicionado. RENAVAM + chassi viraram campos no Vehicle (schema v6). **497 testes verdes.** Migration `0006_vehicle_renavam_chassi.sql` + edge fn `scan-crlv` a deployar.
- [x] **6.L** IA preenche specs técnicos ✅ — Edge fn `infer-vehicle-specs` (Haiku 4.5, cota `scan_count` compartilhada, validação de range server-side, incremento condicional confidence ≥ 0.3). Chip "✨ Preencher com IA" na seção técnica, só visível com make+model+year preenchidos E algum técnico vazio. Não sobrescreve user input. **512 testes verdes.** Edge fn a deployar.

> **Polish anotado:** highlight verde fading nos campos preenchidos pela IA (existe no FIPE, faltou aqui). Não bloqueia — entra no polish round.

> **🏁 ONDA 1 COMPLETA** — 6.H + 6.I + 6.J + 6.K + 6.L entregues. 512 testes verdes, analyze limpo, iOS build OK. Pendente em prod: migrations 0004/0005/0006 + edge functions `scan-crlv` e `infer-vehicle-specs`.

## ONDA 2 — Inteligência & utilidade (depende do cadastro rico)

- [x] **6.M** ⭐ Calendário de manutenção sugerido pelo modelo ✅ — Edge fn `suggest-maintenance` (Haiku 4.5, cota `scan_count`), modelo `MaintenanceSchedule`, tela `MaintenancePlanScreen` na InsightsScreen, dedupe via `dedupeProposed` (6.G), FAB "Criar todos restantes". **530 testes verdes.** Edge fn `suggest-maintenance` a deployar.
- [x] **6.N** ⭐ Lembretes automáticos IPVA/licenciamento por UF ✅ — `fiscal_calendar.dart` hardcoded (SP/RJ/MG/PR/RS/SC + default), `suggestFiscalReminders` pura, tela `FiscalPlanScreen` com disclaimer "Confira no Detran", botão 3ª seção da InsightsScreen, dedupe. **547 testes verdes.** Zero infra de backend — só dados estáticos.
- [x] **6.O** Documentos pessoais (CNH + multas + seguro) ✅ — 3 entidades novas (UserProfile/Fines/Insurances) com schema v7 + sync (GlobalSyncService passou pra 7 entidades), 3 forms, tela "Documentos", validators, `suggestDocumentReminders`, botão "Sugerir lembretes" com dedupe. **657 testes verdes.** Migration `0007_personal_documents.sql` + nenhuma edge fn nova.
- [x] **6.P** ⭐ Tracker de preço por posto ✅ — `stationName/stationBrand` em FuelEntry (schema v8), autocomplete de 12 bandeiras BR, `StationStats` + agregação pura, tela `MyStationsScreen` linkada em reports. **679 testes verdes.** Migration `0008_fuel_entry_station.sql`.
- [x] **6.Q** ⭐ Custo por KM + tendência ✅ — `CostMetrics`, `TrendAnalysis` (com `goodWhenDown`), cards `CostPerKmCard`/`TrendCard`/`TrendBadge` no detalhe do veículo. **693 testes verdes.** Tudo puro, sem schema.

> **Polish:** consumo da tendência usa max-min odômetro/litros (simples) em vez de cheio-a-cheio. Card mostra histórico inteiro em vez de últimos 12m. Anotar pra refinar quando rodar UX polish round.
- [x] **6.R** Calculadora etanol×gasolina ✅ — `FuelEconomy`+`FuelComparison`, consumo real cheio-a-cheio por tipo (fallback genérico se sem hist), tela `FuelEconomyScreen` com 3 cards (preços / consumo / recomendação), botão no detalhe **só pra veículos flex**. **704 testes verdes.**
- [x] **6.S** Posto preferido ✅ — `analyzeFavoriteStation` puro (reusa `aggregateByStation`), `FavoriteStationCard` no detalhe + `_FavoriteInsightSection` em MyStations. Cheapest qualified mínimo 3 visitas. **713 testes verdes.**
- [x] **6.T** ⭐ Chat com histórico ✅ — Edge fn `chat-history` (Haiku 4.5, contexto 36m, cota `chat_count` 10/mês), tabela local `chat_messages` (sem sync), modelo + repo + service, tela ChatScreen com bubbles + 4 sugestões iniciais, botão na InsightsScreen. **731 testes verdes.** Schema v9.
- [x] **6.U** Push proativo (local notifications) ✅ — Schema v10 com `notifications_log`, evaluator puro (3 detectores: consumo down >10%, CNH 7-30d, fiscal IPVA/Lic 7-30d, dedupe 7d, prioridade fiscal>cnh>consumo), service com `flutter_local_notifications` + persistência no log, orquestrador fire-and-forget, trigger no `fuel_entry_saver`. **741 testes verdes.** Settings UI persistente pulada (TODO post-MVP — adicionar `shared_preferences`).
- [x] **6.V** ⭐ Recap semanal/mensal Spotify Wrapped ✅ — `computeRecap` pura (range week/month, totais, km, consumo, preços, posto favorito reusando aggregateByStation, top categoria com labels PT-BR), `RecapScreen` com PageView vertical full-screen + 5-7 slides + auto-avanço 4s + indicador, entry point card destacado em reports. **751 testes verdes.** TODO post-MVP: `share_plus`.

> **🏁🏁 ONDA 2 COMPLETA (26/05/2026)** — 10 sprints, 751 testes verdes, 0 analyze issues, iOS build OK. Migrations pendentes em prod: 0007 (documents) + 0008 (station) + 0009 (chat_quota). Edge functions novas: `suggest-maintenance`, `chat-history`. Próximo passo: commit inicial em https://github.com/andrR89/autolog.

## Sprint 6.W.1 — Patch IA contextual ✅

Patch corretivo pós-homologação:
- **Fix 1:** `chat-history` agora envia veículo completo (placa/type/specs/FIPE, sem renavam/chassi por privacidade) + stats computadas (odômetro atual, total rodado, consumo médio, posto preferido, top categoria de despesa, faixa de preços, lembretes ativos).
- **Fix 2:** `suggest-maintenance` aceita `vehicle_uf` + `current_odometer_km`; prompt regional com regras condicionais (UF litorânea → corrosão; ≥80k km → correia/embreagem/suspensão; ≤2010 → mangueiras/borrachas).
- **Fix 3:** `brFiscalCalendar` expandido de 6 → **27 UFs** (todos os estados BR cobertos, valores típicos 2024-2026 com disclaimer "Confira no Detran" obrigatório na UI).

**757 testes verdes** (+6). Edge functions `chat-history` + `suggest-maintenance` a re-deployar.

## ONDA 3 — Conforto, viralidade & integrações

- [ ] **6.W** Modo "viagem" — agrupa abastecimentos + despesas como uma unidade ("Viagem a Floripa — R$ 850"). Tela timeline da viagem.
- [ ] **6.X** ⭐ Compartilhar veículo com cônjuge — multi-user via Supabase RLS + tabela `vehicle_members`. Permissões `owner|editor|viewer`.
- [ ] **6.Y** ⭐ PDF "Histórico do veículo" exportável — FIPE + manutenção + km + despesas em PDF formatado pra usar como prova na venda.
- [ ] **6.Z** Modo escuro (já estava em post-MVP, sobe pra cá).
- [ ] **6.AA** Widget de tela inicial — iOS WidgetKit / Android AppWidget. Mostra próximo lembrete + total do mês.
- [ ] **6.BB** Áudio TTS — botão "ouvir insights" pra quem está parado ao dirigir.
- [ ] **6.CC** ⭐ Emissão de CO2 calculada — baseada em consumo real + tipo combustível. Card no detalhe.
- [ ] **6.DD** Gamificação leve — streak (dias seguidos registrando) + badges (5 abastecimentos abaixo da média, etc).
- [ ] **6.EE** Google Calendar sync — lembretes viram eventos.
- [ ] **6.FF** WhatsApp bot — número que registra abastecimento via mensagem (Twilio + função extract).
- [ ] **6.GG** OBD-II Bluetooth — leitor opcional pra puxar km automático + dados de saúde do motor (alta complexidade hardware — pode escorregar pra pós-lançamento).

## Pré-go-live (curto, mas obrigatório)

- [ ] Patch do débito técnico de cota (vazamento entre meses) — corrigir `scan-receipt`, `scan-expense`, `analyze-history`.
- [ ] **7.x** itens existentes (estados vazios, exclusão LGPD, ícone/splash, política de privacidade, build assinado).

## POST-LANÇAMENTO (anotado em 26/05/2026)

> Decisão Diretor: estes itens explicitamente saem do escopo pré-lançamento.

- **Suporte completo a veículos elétricos** — eles não usam gasolina mas têm gastos iguais (manutenção, IPVA, seguro). Adaptar: novo `FuelType.eletrico`, métrica `kWh/100km` em vez de `km/L`, custo por carga, integração com app de carregamento.
- **Modo "motoboy/Uber"** — calcular **lucro** do veículo (entradas de corridas - saídas operacionais). UI de "ganhos" + meta diária/mensal + estimativa de R$/km líquido. Atrai público profissional.
- Voice input (registrar abastecimento falando)
- Benchmark anônimo entre usuários (precisa massa crítica de users)
- Scanner de multa Detran (depende de APIs estaduais)
- Apple Wallet / IFTTT / Zapier
- Comunidade / reviews de oficinas / marketplace de veículos
- Recurring reminders (já estava no post-MVP)
- ML Kit OCR offline (já estava no post-MVP)
- Configuração de despesas recorrentes virando lembrete automático (já estava no post-MVP)

---

## Pré-Sprint 6 — Polish de UX/Design (gate de qualidade visual)

> Decisão do Diretor: antes de mexer em billing (Sprint 6), o app precisa passar por uma **rodada dedicada de UX/design**. Considerar um **agente especializado** (papel novo no workflow: "designer", possivelmente um sub-agente com modelo equipado de skills de design/Material 3 + frontend-design da superpowers).

- [ ] Auditoria visual sistema-wide: hierarquia tipográfica, paleta (cores semânticas — success/warn/error), spacing, density.
- [ ] Onboarding visual do scan (a tese central) — primeira impressão.
- [ ] Estados vazios "humanos" (não só texto cinza).
- [ ] Microinterações (loading, success feedback, transições).
- [ ] Identidade visual: ícone do app, splash, paleta consistente.
- [ ] Revisitar copy PT-BR pra tom de voz consistente.
- [ ] Tela de detalhe do veículo: hoje é "fuel history" — talvez vire um dashboard mais rico (totais do mês, próximo lembrete, último abastecimento em destaque).

---

## Sprint 6 — Monetização (Android + Web)
- [ ] **6.1** Integrar **RevenueCat** como camada de entitlement unificado.
- [ ] **6.2** Google Play Billing (assinatura mensal/anual) dentro do app Android, via RevenueCat.
- [ ] **6.3** Checkout web via **Stripe** (preço menor), divulgado FORA do app. Sincroniza entitlement via RevenueCat.
- [ ] **6.4** Backend: `is_premium` atrelado à conta, agnóstico de plataforma. Webhooks Play + Stripe → RevenueCat → `usage_quota.is_premium`.
- [ ] **6.5** Paywall + gating: cota de scan (5/mês free), veículos extras, relatórios avançados.
- [ ] **6.6** Restaurar compras / sincronizar status entre devices e plataformas.
- [ ] **6.7** ⚠️ Antes de publicar: revisar Payments policy (Play) atual. Garantir que NÃO há link de pagamento externo dentro do app.

## Sprint 7 — Polimento e lançamento
- [ ] **7.1** Onboarding (primeiro veículo + explicar o scan = primeiro "aha moment").
- [ ] **7.2** Estados vazios, erros de rede, feedback de sync — todos tratados.
- [ ] **7.3** Exclusão de conta (LGPD) — apaga dados do usuário.
- [ ] **7.4** Ícone, splash, ficha da Play Store, política de privacidade.
- [ ] **7.5** Build de release assinado + publicação interna/beta na Play Store.

## Sprint 8 — Web (2ª onda, após validar mobile)
*Só começar depois do mobile lançado e a tese validada. Arquitetura já preparada desde o Sprint 0.*

- [ ] **8.1** Build Flutter Web funcional; Drift rodando sobre WASM/IndexedDB.
- [ ] **8.2** `WebImageSource`: upload de arquivo + drag-and-drop (substitui câmera no scan).
- [ ] **8.3** Odômetro na web: manual ou via scan multimodal (sem ML Kit).
- [ ] **8.4** Checkout Stripe na web (já feito no 6.3) integrado ao fluxo web.
- [ ] **8.5** Layout responsivo (desktop não é telefone esticado).
- [ ] **8.6** Deploy + SEO básico (a web também é canal de descoberta).

---

## Dívida técnica / pós-MVP (não fazer agora)
- iOS (3ª onda — reavaliar regras de "reader app" / billing na época).
- Resolução de conflito mais robusta que last-write-wins (se multi-device pesar).
- Guardar imagem de cupom para reauditoria (decidir storage).
- Scan de notas além de combustível (oficina, peças).
- Comparação de preço de postos / geolocalização.
- Exportação de dados (CSV/PDF).
- **Rewarded ad opcional** ("assista, ganhe +1 scan") — só se houver massa de free que não converte, e só com dados na mão.
- Entrar nos programas de billing alternativo das lojas (avaliar quando houver volume).
- **Validar `dueDate > hoje`** no form de lembrete `porData` (notif do passado vira no-op, lembrete fica dead-on-arrival — paridade com a validação de `dueKm`).
- **Lembretes periódicos por km** (ex.: troca de óleo a cada 10.000 km). Quando marca done, auto-cria o próximo com `dueKm = current + interval`.
- **Lembretes periódicos por data** (ex.: IPVA todo ano). Auto-cria o próximo ao marcar done com `dueDate += interval`.
- **Despesas recorrentes que viram lembretes automaticamente** (ex.: configurar "IPVA 1234 reais todo ano" → cria reminder automaticamente perto da data, e ao fazer a despesa marca done).
- **Dark mode**. Exige: (a) `buildDarkTheme()` complementar; (b) wiring `MaterialApp.darkTheme` + `themeMode` (system/light/dark) com setting do usuário; (c) refactor de tokens absolutos (`AppColors.surface`/`brand` etc.) pra tokens semânticos via `Theme.of(context).colorScheme.X`; (d) audit visual dos hero brand-dark, chips coloridos e cores de chart no fl_chart pra contraste em dark. Custo estimado: ~1.5–2h de orquestração + ciclo de homologação. Bom release note pós-lançamento ("Dark mode chegou!").

# Achados — Roteiro de Teste 23/06 (Ondas 1, 2, 3)

**Tester:** Claude (Cowork) · **Ambiente:** Simulador iPhone 16e, iOS 26.3, build debug · **Conta:** premium.0618@autolog.test

> Legenda: ✅ validado · 🟡 validado por código (ambiente não permite o passo na mão) · 🔴 bug · ⏭️ precisa de você (dashboard web / device físico / 2ª conta).
> Setup feito: NSX com **3 abastecimentos** (1000→1500→2000 km), baseline OK (consumo **13,9 km/l**, custo **R$ 0,51/km** — cálculo de consumo correto).

## ✅ B1 — RESOLVIDO (reteste 23/06)
O fix do `dialogTheme` (cor explícita no title/contentTextStyle) funcionou. Reimportei o backup e o diálogo agora mostra **"Confirmar restauração"** + a contagem (1 veículos, 3 abastecimentos, 0 despesas, 0 lembretes, 0 multas, 0 apólices) + o texto explicativo, tudo legível, com Cancelar/Restaurar. Item fechado.

## 🔴 Bug encontrado (resolvido — ver acima)

### B1 — Diálogo "Confirmar restauração" com texto invisível (Bloco 7.6)
Ao tocar **Importar** → selecionar o JSON, o diálogo de confirmação abre **só com os botões Cancelar/Restaurar**; o título "Confirmar restauração" e a contagem do bundle (`X veículos, Y abastecimentos…`) **não aparecem** — área branca em branco. O texto **existe no código** (`backup_card.dart` L188-201), então é **bug de cor de texto** (provável white-on-white) no `AlertDialog` em tema claro. O usuário confirma uma restauração às cegas.
- **Suspeita:** `AlertDialog` não herda a cor de texto certa do tema (title/contentTextStyle). Pode afetar **outros AlertDialogs** (vale checar diálogos de exclusão/confirmação).
- **Print:** diálogo branco com só "Cancelar"/"Restaurar".

## 🟢 Cosmético
- **8.1** — o card de Settings diz **"Virar Premium / Scan e insights ilimitados."**; o roteiro esperava CTA "Tudo desbloqueado". Só variação de copy, não bug.

---

## 🌊 Onda 1 — Confiança

### Bloco 1 — Sync error friendly 🟡 (código)
Modo avião não dá pra simular no simulador (usa a rede do Mac), mas o fix está no `sync_error_mapper.dart`:
- Rede (socket/host lookup/client/handshake) → **"Sem conexão. Verifique sua internet e tente novamente."** (exatamente o esperado em 1.2).
- 42P17/recursão, RLS/permission, JWT/sessão, timeout → cada um com frase PT-BR própria.
- Lista de entidades vira "Não consegui sincronizar: vehicles, fuel. Tente novamente." — **sem** `StateError`/`PostgrestException`/`supabase.co`. Indicador `cloud_off` com tooltip "Sem conexão — toque pra tentar". **Sem regressão.**

### Bloco 2 — DashedFrame ✅ + 🟡
Existe **um widget compartilhado** `DashedFrame` (`core/design/widgets/dashed_frame.dart`) usado nos 4 empty states: garagem (carro), abastecimento (bomba — **vi ao vivo**), despesas (recibo), lembretes (sino). Refactor não quebrou o visual; ícones corretos por tela.

### Bloco 3 — Sentry ✅ device + 🟡 código (⏭️ dashboard)
- **3.1 ✅** card amarelo "Disparar erro de teste (debug)" com ícone de bug, no fim de Settings (confirma build debug).
- **3.2 ✅** ao tocar: dispara `Sentry.captureException` e mostra snackbar **"Erro de teste enviado. Olha o dashboard do Sentry."**
- **3.4 🟡** scrubber (`sentry_init.dart`) é agressivo: força `user: null`, `sendDefaultPii=false`, e remove URL Supabase, JWT, Authorization/apikey/bearer e e-mail de mensagens/breadcrumbs/contexts. Vazamento de PII é improvável por design.
- **3.3/3.4 ⏭️** confirmar o issue real no dashboard e inspecionar o stack trace **na sua aba do Sentry** (o Chrome aqui não autentica na sua sessão e o SPA deu timeout). Disparei o evento agora (ambiente `debug`).

---

## 🌊 Onda 2 — UX que move métrica

### Bloco 4 — PostHog ✅ PII (código) (⏭️ eventos no dashboard)
- **PII check ✅** — `track()` passa todo prop por `_isSafeProp`, que **rejeita** chaves com email/password/token/jwt/plate/placa/chassi/renavam/nickname/description/station_name **e** qualquer string > 64 chars (free text). PII não entra nos eventos por contrato de runtime.
- **Eventos 4.1–4.7 ⏭️** — gerei parte das ações no device (login premium, 2× `fuel_entry_created` manual, abrir paywall = `paywall_view`/`paywall_cta`). Confirmar a chegada dos eventos e props **na sua aba do PostHog Live events** (mesmo motivo do Sentry).

### Bloco 5 — Notificação contextual 🟡 (código)
Pré-requisito (desinstalar pra zerar permissão) não dá no fluxo atual, mas o comportamento está no código:
- Boot: `requestAlertPermission/Badge/Sound: false` → **sem popup no boot** (5.1).
- Salvar lembrete **Por data** → `requestPermissionIfNeeded()` (pede **no momento certo**, 5.2).
- **Por km** não pede (5.4). Save continua mesmo se negar (5.3, `scheduleReminder` é no-op sem permissão).

### Bloco 6 — a11y ✅ (código)
Labels presentes: toggle de senha **"Mostrar senha"/"Ocultar senha"** (login+cadastro, 6.1/6.2); **"Insights"** (6.3); Documentos com `Semantics` **"Editar CNH" / "Editar apólice {veículo}" / "Editar multa {veículo}"** (6.4); chat **"Pergunta"** (6.6); FIPE **"Buscar"** (6.7); excluir conta **"Digite EXCLUIR pra confirmar"** (6.8). Anúncio real no VoiceOver/TalkBack ⏭️ (não dá pra dirigir o simulador com leitor de tela ligado).

---

## 🌊 Onda 3 — Retenção + monetização

### Bloco 7 — Backup completo ✅ device + 🟡 código (1 bug)
- **7.1 ✅** card "Backup completo" com **Exportar tudo** + **Importar**.
- **7.2 ✅** Exportar → share sheet "AutoLog — backup completo · JSON · 3 KB", arquivo **`autolog_backup_2026-...json`** (padrão de nome ok).
- **7.4 🟡** `toJson` tem: `version`, `exported_at` (ISO-8601 UTC), `app_version`, `user_id`, `vehicles`, `fuel_entries`, `expenses`, `reminders`, `fines`, `insurances`, `user_profile`. **NÃO** inclui `usage_quota` nem `vehicle_members` (excluídos por design). ✅
- **7.6/7.7 ✅** (não-destrutivo) reimportei o mesmo backup: diálogo aparece (🔴 **texto invisível, B1**), restauração roda, **sem duplicar** veículo/abastecimentos → dedup por UUID funciona. Snackbar "Restauração concluída: X novos, Y atualizados, Z mantidos." (código L163). Não deletei o único veículo pra não zerar o setup.
- **7.8 🟡** versão incompatível → `FormatException` mostrada **direto** (snackbar vermelho): **"Versão 999 do backup não suportada. Atualize o app."** (sem prefixo "Erro ao importar:"). Sem crash.

### Bloco 8 — Paywall + entitlements ✅
- **8.1 ✅** card "Virar Premium" (brand-dark) no topo de Settings *(copy ≠ roteiro, ver cosmético)*.
- **8.2 ✅** paywall "Tudo do AutoLog, sem limites.", **5 features**, **3 planos** (Mensal R$9,90 / Anual R$79,90 / Vitalício R$199,90).
- **8.3 ✅** Anual selecionado por padrão com badge **"Mais escolhido"**; tocar Mensal/Vitalício move o check/borda accent.
- **8.4 ✅** CTA **"Em breve"** em lima.
- **8.5/8.6 ✅** (código) snackbars: "Pagamentos chegam na próxima atualização. Te avisamos por e-mail quando estiver disponível." / "Restauração estará disponível junto com pagamentos."
- **8.7 ✅** fechar (X) volta pra Settings, sem crash.
- **8.8 ⏭️** cota esgotada → paywall: não testável com conta premium (sem caminho de cota). Precisa da conta free `autolog.tester.0618@gmail.com` com cota estourada.

---

## ⏭️ Precisa de você (ambiente)
1. **Sentry dashboard** (3.3/3.4): confirmar o issue "AutoLog test event — Sentry handshake from device" (ambiente `debug`) e checar que o stack trace **não** tem email/`supabase.co`/JWT/Authorization. Disparei o evento agora.
2. **PostHog Live events** (4.1–4.7): confirmar eventos e props.
3. **Bloco 5** no device físico/desinstalando (popup contextual real).
4. **8.8** com conta free + cota estourada.
5. **VoiceOver/TalkBack** (6.x) anúncio real.

## Tempo
~70 min (boa parte no setup dos abastecimentos via clipboard e nos timeouts do Sentry no navegador).

## Sensação por onda
- **Onda 1:** sólida — mensagens de erro amigáveis e empty states consistentes; integração Sentry bem instrumentada e com PII scrubbing sério.
- **Onda 2:** analytics com contrato anti-PII robusto; permissão de notificação no momento certo. Bom.
- **Onda 3:** paywall caprichado e completo; backup funciona ponta-a-ponta — **mas** o diálogo de restauração com texto invisível é o ponto que precisa de fix.

## Surpresa positiva
O `_isSafeProp` (PostHog) + o scrubber do Sentry mostram cuidado real com privacidade — rejeitam PII por chave **e** por heurística (string longa). E o backup re-importável sem duplicar (dedup por UUID) deu confiança no restore.

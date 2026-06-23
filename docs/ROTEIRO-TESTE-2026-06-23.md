# Roteiro de Teste — Ondas 1, 2 e 3 (2026-06-23)

> Valida tudo que foi entregue desde 22/06: sync amigável, refactor DashedFrame, Sentry, PostHog, notif contextual, a11y, backup/restore JSON, paywall scaffold.
> Tempo estimado: **45-60 min**.
> Pré-requisitos: build atual rodando, conta `premium.0618@autolog.test` / `AutoLog2026!Premium`, **um device físico Android se for testar TalkBack** (opcional).

## Setup (3 min)

1. App instalado, build com `--dart-define-from-file=dart_define.json`.
2. Login com a conta acima.
3. Tem ao menos **1 veículo** com **3 abastecimentos** cadastrados (pra os exports e analytics fazerem sentido). Se não tiver, cria primeiro.

### Como reportar achados
Pra cada bug:
- **Bloco / passo**: ex. "Bloco 5, passo 5.4"
- **Esperado vs observado** (1 linha cada)
- **Print** sempre que possível
- **Plataforma**: iOS (modelo) ou Android (modelo)

---

## 🌊 Onda 1 — Confiança

### Bloco 1 — Sync error friendly (item #10)

| # | Ação | Esperado |
|---|------|----------|
| 1.1 | Abra o app online normal. Indicador de sync na AppBar de Vehicles | `cloud_done` verde (sincronizado) |
| 1.2 | Ativa modo avião → toca no ícone | Vira `cloud_off` vermelho, snackbar com mensagem PT-BR amigável (NÃO mais "Bad state: sync errors: vehicles, fuel, …"). Esperado: **"Sem conexão. Verifique sua internet e tente novamente."** |
| 1.3 | Desativa modo avião → toca em "Tentar" | Volta a `cloud_done` em alguns segundos |

> ⚠️ Se aparecer `StateError`, `PostgrestException` ou `supabase.co` na mensagem = regressão. Reporta.

---

### Bloco 2 — DashedFrame (item #11) — regressão visual

| # | Tela | Esperado |
|---|------|----------|
| 2.1 | Sai do app, faz logout, cria conta nova | Empty state da **Garagem** com moldura tracejada + ícone de carro, headline "Sua garagem está esperando." |
| 2.2 | Volta logado na conta premium, abre o detalhe de um veículo SEM abastecimentos (cria um veículo NSX rapidinho) | Empty state com moldura tracejada + ícone de bomba, headline "Nenhum abastecimento aqui ainda." |
| 2.3 | Abre Despesas desse veículo sem dados | Moldura tracejada + ícone de recibo |
| 2.4 | Abre Lembretes desse veículo sem dados | Moldura tracejada + ícone de sino |

> O visual deve estar **idêntico ao antes do refactor**. Se algum sumiu ou está com tamanho diferente, reporta.

---

### Bloco 3 — Sentry crash reporting (item #8)

| # | Ação | Esperado |
|---|------|----------|
| 3.1 | Settings → role até o final | Card amarelo **"Disparar erro de teste (debug)"** com ícone de bug. Só aparece em build debug. |
| 3.2 | Tocar | Snackbar "Erro de teste enviado. Olha o dashboard do Sentry." |
| 3.3 | Aguarda ~30s e abre https://ezsoft-5k.sentry.io/issues/ | Aparece um issue novo **"Exception: AutoLog test event — Sentry handshake from device"** |
| 3.4 | Inspeciona o stack trace | NÃO deve aparecer: email do user, URL `supabase.co`, JWT (`eyJ…`), header Authorization. **Se aparecer = vazamento de PII, reporta urgente.** |

---

## 🌊 Onda 2 — UX que move métrica

### Bloco 4 — PostHog analytics (item #14)

> Abre https://us.posthog.com → Activity → Live events em outra aba antes de começar.

| # | Ação | Evento esperado no PostHog |
|---|------|----------------------------|
| 4.1 | Logout + login com `premium.0618@autolog.test` | `logout` (anônimo) + `login_success` com `method=email`. Person passa a ter UUID do user (não anônimo) |
| 4.2 | Cria veículo manualmente | `vehicle_created` com props `fuel_type`, `vehicle_type`, `has_year`, `has_fipe`, `used_fipe_search` |
| 4.3 | Registra um abastecimento manual | `fuel_entry_created` com `source=manual`, `fuel_type`, `full_tank` |
| 4.4 | Escaneia um cupom (galeria) | `scan_receipt_opened` (origin=gallery), `scan_receipt_succeeded` ou `scan_receipt_failed`. Salva o registro: `fuel_entry_created` com `source=ai_scan` |
| 4.5 | Settings → Exportar dados → escolhe Abastecimentos | `export_csv_used` com `export_type=fuel` |
| 4.6 | Settings → Exportar dados → PDF Histórico | `export_pdf_used` |
| 4.7 | Settings → "Virar Premium" → abre paywall | `paywall_view`. Toca em "Em breve": `paywall_cta` com `plan=yearly` (ou o plano selecionado) |

> ⚠️ **PII check**: nenhum evento pode ter `email`, `nickname`, `plate`, `placa`, `description` nas props. Se você ver algum, reporta. Os campos seguros são: tipo, count, bool, ID interno.

---

### Bloco 5 — Notificação contextual (item #9)

> Esse bloco só faz sentido se **desinstalar** o app primeiro (zera a permissão de notificação).

| # | Ação | Esperado |
|---|------|----------|
| 5.1 | Desinstala o app, reinstala, abre. NÃO faz nada com lembretes. | **iOS**: SEM popup de "AutoLog gostaria de enviar notificações". Antes pedia no boot, agora não. |
| 5.2 | Loga, vai em algum veículo → Lembretes → Novo lembrete → escolhe **Por data** → preenche e salva | **AGORA** aparece o popup "AutoLog gostaria de enviar notificações". Esse é o momento certo — user acabou de pedir um lembrete. |
| 5.3 | Recusa o popup | Lembrete salva mesmo assim, sem crash. Notificação local nunca dispara, mas o lembrete em si fica registrado. |
| 5.4 | Cria outro lembrete tipo **Por quilômetro** | **NÃO** pede permissão de novo (kmtype não usa notif local). |

---

### Bloco 6 — a11y (item #17) — opcional mas valioso

> iOS: Settings → Acessibilidade → VoiceOver. Android: Configurações → Acessibilidade → TalkBack.

| # | Ação | Esperado |
|---|------|----------|
| 6.1 | Ativa VoiceOver/TalkBack. Vai pra tela de login. Foca no toggle de visibilidade da senha (👁) | Lê **"Mostrar senha"** (ou "Ocultar senha" depois de tocar). Antes lia só "Botão". |
| 6.2 | Cadastro → mesmo toggle | Idem |
| 6.3 | Veículo → ícone Insights (✨) na AppBar | Lê o tooltip "Insights". (Tente também filtro 🎛, mais ⋯, chevron de voltar — todos devem ter label.) |
| 6.4 | Documentos → tap num card de CNH/Apólice/Multa | Lê algo como "Botão. Editar CNH" / "Editar apólice [veículo]" / "Editar multa [veículo]". Antes era invisível pro screen reader. |
| 6.5 | Tela de Configurações → roda a tela inteira com swipe pra direita | Cada controle tem rótulo legível. |
| 6.6 | Chat com IA → campo de pergunta | Lê **"Pergunta"** (label antes faltava — só hint não era anunciado quando focado). |
| 6.7 | FIPE search → campo de busca | Lê "Buscar" + hint. |
| 6.8 | Settings → Excluir minha conta → campo de confirmação | Lê **"Digite EXCLUIR pra confirmar"**. |

> Se algum controle ficou silencioso ou foi anunciado errado, reporta o bloco/passo.

---

## 🌊 Onda 3 — Retenção + monetização

### Bloco 7 — Backup completo (item #15)

| # | Ação | Esperado |
|---|------|----------|
| 7.1 | Settings → role até "Backup completo" | Card "Backup completo" com 2 botões: **Exportar tudo** e **Importar** |
| 7.2 | Tocar **Exportar tudo** | Share sheet do iOS com arquivo `autolog_backup_2026-06-23T….json`. Snackbar mostra a contagem (X veículos, Y abastecimentos, Z despesas). |
| 7.3 | Salva o arquivo (Arquivos / Drive / WhatsApp pra você mesmo) | Arquivo .json salvo |
| 7.4 | Abre o JSON num editor de texto pra conferir | Tem campos: `version: 1`, `exported_at`, `user_id`, `vehicles`, `fuel_entries`, `expenses`, `reminders`, `fines`, `insurances`, `user_profile`. Decimais corretos com vírgula? Datas ISO-8601? **NÃO deve ter** `usage_quota` nem `vehicle_members`. |
| 7.5 | Volta no app → deleta UM veículo (anota qual) | Garagem perde esse carro |
| 7.6 | Settings → Backup completo → **Importar** → seleciona o JSON exportado em 7.2 | Diálogo "Confirmar restauração" com a contagem do bundle |
| 7.7 | Confirma | Snackbar "Restauração concluída: X novos, Y atualizados, Z mantidos". O veículo deletado **NÃO volta** (já foi soft delete — restore só insere/atualiza, não desdeleta). Os abastecimentos sumiram com o veículo. |
| 7.8 | Tenta importar um JSON inválido (modifica o `version` no editor pra `999`) | Snackbar PT-BR clara: "Versão 999 do backup não suportada. Atualize o app." Não crasha. |

> ⚠️ Se o app crashar com qualquer arquivo, reporta com o JSON anexo.

---

### Bloco 8 — Paywall + entitlements (item #13)

| # | Ação | Esperado |
|---|------|----------|
| 8.1 | Settings → topo da tela | Card **"Virar Premium"** brand-dark, com ícone ⭐ accent, CTA "Tudo desbloqueado" |
| 8.2 | Tocar no card | Abre tela **AutoLog Premium**: header "Tudo do AutoLog, sem limites.", 5 features com ícone/título/subtítulo, 3 planos (Mensal/Anual/Vitalício) |
| 8.3 | Plano selecionado | **Anual** por padrão (badge "Mais escolhido"). Toca em Mensal e Vitalício → muda check/borda accent. |
| 8.4 | Botão CTA | Diz **"Em breve"** (não "Assinar"), com cor accent (lima). |
| 8.5 | Tocar "Em breve" | Snackbar PT-BR: "Pagamentos chegam na próxima atualização. Te avisamos por e-mail quando estiver disponível." |
| 8.6 | Tocar "Já sou Premium — restaurar" | Snackbar: "Restauração estará disponível junto com pagamentos." |
| 8.7 | Fecha (X) → volta pra Settings | Sem crashes |
| 8.8 | Vai pra abastecimento → tenta scan **com a conta `autolog.tester.0618@gmail.com`** (não-premium) DEPOIS de 5 scans no mês — ou simula no DB. Quando der "cota esgotada", toca no botão "Ver Premium" no banner amarelo | Abre `/paywall` (antes só mostrava snackbar "Premium chega em breve") |

> Reporta se: planos não atualizam quando seleciona, CTA não dá feedback, navegação pela cota não vai pro paywall.

---

## ✅ Encerramento

Manda pro Diretor:
1. Lista numerada de bugs (bloco/passo, print, plataforma).
2. Tempo total que demorou.
3. Sensação geral: 1 linha por onda.
4. O que te surpreendeu positivamente (também conta).

Bom teste! 🚗

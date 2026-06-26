# Roteiro de Teste — Web port (Sprint 8)

> Valida o primeiro build web do AutoLog. **Escopo:** verificar o que
> funciona, o que não funciona e como cada limitação se manifesta. NÃO é
> uma homologação fechada — esperamos vários "não funciona" porque
> plugins mobile-only viraram no-op.
>
> Tempo estimado: **30 min**.
> Como rodar: `flutter run --device-id chrome --dart-define-from-file=dart_define.json --web-port=8080` (já está rodando) e abrir http://localhost:8080.

## Setup (1 min)

1. Chrome (de preferência sem extensões pesadas — ad block pode bloquear PostHog).
2. Abre o DevTools (F12) → console e network limpos.
3. Cria/loga numa **conta nova** (não usa a `premium.0618` real — web grava num IndexedDB separado e pode bagunçar tua sessão mobile).

### Como reportar
- **Bloco / passo** + **esperado vs observado** + **print** + **log do console** (se houver).

---

## Bloco 1 — Boot e auth (5 min)

| # | Ação | Esperado |
|---|------|----------|
| 1.1 | Abre http://localhost:8080 | Tela de **onboarding** renderiza (4 slides). Sem erro vermelho na tela. |
| 1.2 | Console do Chrome | Pode aparecer **"Exeption on setup"** do PostHog (ignorado por design — analytics desligado no web por enquanto). NÃO deve aparecer erro de Drift / sqlite. |
| 1.3 | Pula → vai pra `/login` | Tela de login carrega, layout mobile (campos em coluna) — vai estar **gigantesco e estranho num desktop**. Anota mas não é bug — é o tema da seção 9 deste roteiro. |
| 1.4 | Cria conta nova (email descartável) | Sucesso → cai em garagem vazia. |
| 1.5 | Recarrega a página (F5) | Continua logado (sessão Supabase persistida). |
| 1.6 | Logout, volta a fazer login | Funciona. |

> ⚠️ Crash, tela branca ou stack trace no Console = reporta com o trace completo.

---

## Bloco 2 — Persistência local (Drift WASM) (5 min)

| # | Ação | Esperado |
|---|------|----------|
| 2.1 | Cria 1 veículo (manualmente, sem FIPE pra ser rápido) | Aparece na garagem |
| 2.2 | Recarrega a página (F5) | Veículo continua lá. |
| 2.3 | DevTools → Application → IndexedDB | Existe um banco **`autolog`** ou similar com tabelas (vehicles, fuel_entries…) |
| 2.4 | Adiciona 2 abastecimentos manuais → confere cálculo de consumo | Mesmo cálculo do mobile (Regra de Ouro #2). Se mostrar "—" no primeiro e número no segundo, está certo. |
| 2.5 | Abre outra aba (Chrome → Nova guia → mesmo URL) | **Mesma sessão**, mesma garagem (IndexedDB é por origem, não por aba). |

> ⚠️ Se F5 zerou os dados = bug crítico (a persistência WASM não está funcionando).

---

## Bloco 3 — Sync com Supabase (5 min)

| # | Ação | Esperado |
|---|------|----------|
| 3.1 | Conferir indicador na AppBar de Vehicles | `cloud_done` em alguns segundos |
| 3.2 | Loga no mobile com a MESMA conta (se tiver acesso) | Veículos criados no web aparecem |
| 3.3 | Cria 1 veículo no mobile → volta pro web → toca no `cloud_done` pra forçar pull | Veículo do mobile aparece no web |
| 3.4 | Toca em "cloud_off" se ele aparecer | Snackbar PT-BR amigável (não `Bad state`) |

> Se sync não acontecer entre web e mobile, anota — pode ser o webhook do RLS fix (migration 0014) ou o session/cookie no web.

---

## Bloco 4 — Features que devem funcionar (10 min)

| # | Tela / ação | Esperado |
|---|------|----------|
| 4.1 | Garagem → editar veículo → mudar nome | Salva, volta pra lista atualizada |
| 4.2 | Excluir veículo | Soft delete; não some do IndexedDB mas some da lista |
| 4.3 | Registrar abastecimento manual (sem scan) | OK |
| 4.4 | Despesas → adicionar uma | OK |
| 4.5 | Lembretes → criar 1 por data | **AGORA** depende: o popup de permissão de notificação do navegador deve aparecer (ou ser silencioso). Lembrete salva mesmo se negar. |
| 4.6 | Relatórios → abre gráficos | LineCharts/BarChart renderizam (fl_chart roda em web) |
| 4.7 | Settings → trocar idioma pra English | UI muda |
| 4.8 | Settings → tema escuro | Funciona |
| 4.9 | Settings → "Excluir minha conta" → digita EXCLUIR (NÃO confirma de verdade) | Diálogo legível, layout OK |

---

## Bloco 5 — Features que provavelmente NÃO funcionam (5 min)

> Esperamos esses falharem. **Reporta o COMPORTAMENTO** (silencioso? snackbar? crash?) pra a gente decidir como tratar.

| # | Tela / ação | Esperado |
|---|------|----------|
| 5.1 | Scan de cupom no fuel form (botão "Escanear cupom") | Pode pedir câmera do navegador, pode falhar. Câmera web é diferente da nativa. Anota o comportamento. |
| 5.2 | Insights → Análise de histórico (chama IA) | Provavelmente OK (chama Edge Function). Confere. |
| 5.3 | Settings → Calendar (Google Calendar sync) | OAuth web é diferente. Pode ou não funcionar. |
| 5.4 | Settings → Export CSV | Deve baixar um .csv |
| 5.5 | Settings → Histórico em PDF | Deve baixar um .pdf |
| 5.6 | Settings → Backup completo → Exportar tudo | Deve baixar um .json |
| 5.7 | Settings → Backup completo → Importar | File picker do navegador abre OK |
| 5.8 | Lembrete por data com data próxima → fechar a aba antes de chegar a hora | Notificação NÃO dispara em background (web não roda app fechado). Sem service worker = sem push. **Esperado.** |
| 5.9 | TTS (botão ▶ em insights/recap) | Pode ou não funcionar — anota |

---

## Bloco 6 — Erros no Console (5 min)

Durante todo o teste, **deixa o Console aberto**. Filtra por `error` e anota o que aparecer:

| Categoria | Provavelmente esperado | Como reportar |
|---|---|---|
| PostHog `Exeption on setup` | Sim (analytics desligado no web) | Ignora |
| `dart:io` / `dart:ffi` related | NÃO deveria mais aparecer | **Reporta** |
| `path_provider` `MissingPluginException` | Possível em fluxos específicos | **Reporta** com a ação que disparou |
| `flutter_local_notifications` falhas | Possível | **Reporta** com a ação |
| Sentry erros (`sentry-flutter`) | Não deveria | **Reporta** |
| 404 de assets (.png, .ttf, fontes) | Não deveria | **Reporta** |
| CORS / Supabase | Não deveria | **Reporta** print do request falhando |

---

## 🖼️ Bloco 9 — Responsividade (observação geral, sem checklist)

A UI atual foi pensada **só pra mobile**. No desktop (≥1024px) e tablet (768-1023px) você vai notar:

1. **Listas e cards ocupam a tela inteira** — veículo virou banner gigante de 1500px de largura.
2. **Forms também esticam** — campos com 1400px ficam parecidos com nada.
3. **FAB no canto inferior direito** funciona mas fica perdido em monitor 27".
4. **AppBar com 6 ícones** (filtros, insights, lembretes…) — espaço sobrando.

Anota a sensação geral em 2-3 linhas. Não precisa de bug por bug — vamos abordar isso na próxima onda de UI responsiva (ver "Próximos passos" abaixo).

Coisas específicas que ajudam (se quiser):
- Tira print da garagem com 0, 1 e 4 veículos em desktop largo (1440px) e em tablet (768px).
- Mesma coisa pro detalhe do veículo + fuel form + paywall.
- Se algo **ficou inutilizável** (texto cortado, botão fora da tela, scroll travado), aí é bug.

---

## ✅ Encerramento

Manda pro Diretor:
1. Lista numerada por bloco/passo, com print + log do console.
2. Bug crítico vs cosmético separados.
3. **Sensação de responsividade** (parágrafo curto, opinativo).
4. Tempo total.

---

## Próximos passos planejados (não testa hoje)

Depois desse roteiro, a gente vai:
1. **Conditional imports** pra plugins que falham silenciosamente (analytics, notif local) — eles já estão isolados, então isso é mais limpeza.
2. **Responsividade**: layouts com `LayoutBuilder` quebrando em 3 breakpoints (mobile <600, tablet 600-1023, desktop ≥1024). Forma:
   - **Mobile**: igual hoje.
   - **Tablet/desktop**: max-width 720 nos forms; lista de veículos em grid 2-3 colunas; detalhe com painel lateral; AppBar com mais densidade.
3. **PWA + service worker** — pra instalar como app, mesmo sem app store.
4. **Deploy em Vercel/Cloudflare Pages** — URL pública pro app web.

Bom teste! 🌐

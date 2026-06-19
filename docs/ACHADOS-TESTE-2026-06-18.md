# Relatório de Teste Funcional — AutoLog

**Data:** 18/06/2026
**Tester:** Claude (Cowork)
**Build/Ambiente:** Simulador iOS — iPhone 16e, iOS 26.3
**Conta usada:** `autolog.tester.0618@gmail.com` (criada na hora via fluxo de cadastro, pois a senha da `teste@autolog.com` não existe em nenhum lugar)
**Roteiro:** `docs/ROTEIRO-TESTE.md` (Ondas 1+2+3)

---

## 0.000 SYNC RESOLVIDO ✅ (19/06, após migration de RLS)

Depois de aplicar a migration **`0014_fix_rls_recursion.sql`** no Supabase (`supabase db push --linked`), retestei o sync:
- O indicador da AppBar mudou de `cloud_off` (vermelho) para **nuvem com check (synced)**.
- Forcei o sync tocando no indicador: **nenhum erro**, sem snackbar "Sync falhou", indicador permanece **synced**.
- **Conclusão:** o bug `42P17` (RLS recursiva em `vehicles`) está **corrigido**. O sync com backend agora conclui. Bloco 10 destravado no simulador (o ciclo completo offline↔online em rede instável ainda é melhor validar em device físico, mas o push pro servidor já funciona).

---

## 0.00 RETESTE COM CONTA PREMIUM + SYNC (18/06, build com Supabase OK)

Conta premium `premium.0618@autolog.test` (login feito pelo André; eu não digito senha). O build agora sobe com o Supabase configurado.

### 🔴 NOVO BUG — Sync falha para todas as entidades (Bloco 10)
- Agora que há backend, o indicador `cloud_off` **surface um erro ao tentar sincronizar** (bom: não falha mais mudo). Mas o sync **falha**:
  > **"Sync falhou: Bad state: sync errors: vehicles, fuel, expenses, reminders, fines, insurances"** (com botão **Tentar**).
- **Persistente:** tocar em "Tentar" repete o mesmo erro. O indicador permanece `cloud_off`.
- **Observações:** o erro lista **todas as 6 entidades** (vehicles, fuel, expenses, reminders, fines, insurances) → cheira a problema sistêmico no push/pull (schema/tabela ausente no Supabase, RLS bloqueando, ou token/sessão). A mensagem exibida é um **`Bad state` cru** (StateError do Dart) — deveria virar uma mensagem PT-BR amigável.
- ✅ A **escrita offline-first segue OK** (tudo salva instantâneo). O que quebra é o **upload pro servidor**.

#### 🎯 CAUSA RAIZ IDENTIFICADA (build com diagnóstico enriquecido)
Com o build novo, o snackbar passou a mostrar o erro completo:
> "Sync falhou: Bad state: sync errors: vehicles, fuel, expenses, reminders, fines, insurances — **vehicles: PostgrestException(message: infinite recursion detected in policy for relation "vehicles", code: 42P17, details: Internal Server Error, hint: null)**"
- **`42P17` = infinite recursion detected in policy** → é um erro de **RLS (Row Level Security) no Supabase**, NÃO no client Flutter. A policy da tabela `vehicles` recursa infinitamente.
- **Causa típica:** policy de `vehicles` que faz subquery na própria `vehicles`, ou numa tabela de compartilhamento/membros (Regra de Ouro #8 — veículo compartilhado) cuja policy consulta `vehicles` de volta → loop. Como `vehicles` é a entidade-pai, o erro cascateia pras outras 6 entidades.
- **Correção (backend):** reescrever a policy de `vehicles` pra não se auto-referenciar — mover a checagem de associação/compartilhamento pra uma função `SECURITY DEFINER` em vez de subquery direta na tabela. O client está correto.
- **Ponto positivo:** o diagnóstico do client ficou ótimo — agora mostra entidade + mensagem + código Postgres, o que aponta a causa direto. (Só faltaria, pro usuário final, uma versão amigável; pro dev, esse detalhe é perfeito.)

### ✅ Scan premium (Bloco 4) — funciona
- "Escanear cupom" → "Escolher da galeria" → cupom real → extraiu **Litros 13,987** e **Preço 7,15**; **Total 100,01** (arredondamento de 2 casas confirmado também pelo caminho do scan — antes era `100,00705`).
- Banner "Dados extraídos do cupom. Revise antes de salvar." (Regra de Ouro #3 respeitada — não salva sozinho). Banner segue **verde** (o roteiro pedia amarelo — cosmético, inalterado).

### ⚠️ Cota / gating premium — não exercível neste build
- Não há **UI de assinatura/cota** (sem contador de scans, sem paywall, sem badge "Premium" em Configurações). Isso é coerente com o billing (RevenueCat) ser de uma sprint posterior. O scan na conta premium se comporta igual ao da conta free. **A diferenciação free×premium (cota de IA) não dá pra validar visualmente enquanto não houver a camada de billing/cota na UI.**

---

## 0.0 REVALIDAÇÃO FINAL — 18/06 (após os 17 fixes do Code)

O Code reportou **17 bugs corrigidos** (3 críticos/médios + 14 cosméticos, 1253 testes verdes). Revalidei no simulador (iPhone 16e). Resultado:

### ✅ Corrigidos e confirmados no app
1. **Export CSV (9.2/9.3) — RESOLVIDO.** "Abastecimentos" agora gera o share sheet do iOS com **`AutoLog — dados exportados · CSV · 302 bytes`**. O código (`lib/features/export/csv_export_service.dart`) confirma os requisitos do 9.3: **UTF-8 com BOM** (`0xEF 0xBB 0xBF`), **separador `;`**, **decimal com vírgula** (`NumberFormat('#,##0.00','pt_BR')`), **datas dd/MM/yyyy** e escaping RFC 4180.
2. **Total (R$) stale + casas decimais — RESOLVIDO.** Recalcula ao vivo: 30 L × R$ 6 → **R$ 180,00**; mudei o preço pra 7 → recalculou pra **R$ 210,00** (não fica mais "stale"). E arredonda a 2 casas: reproduzi o caso do scan (13,987 L × 7,15) → exibe **R$ 100,01** (antes mostrava `100,00705`).
3. **gCO₂/km — RESOLVIDO.** O card de CO₂ agora mostra **gCO₂/km: 31** (antes "—").
4. **i18n de % e eixos de gráfico — RESOLVIDO.** "**-81,6%** vs mai" e o eixo do gráfico de preço "**R$ 7,20 / R$ 6,40**" agora usam vírgula.
5. **"Comparar período" (7.4) — RESOLVIDO.** Existe botão (ícone compare-arrows) na AppBar de Relatórios que abre uma **tela dedicada** "Comparar período" (toggle Mês/Ano, cards Atual vs Anterior, barras Gasto/Litros/Distância/Consumo, "Período personalizado") — tudo com vírgula.
6. **Card da garagem mostra o odômetro atual — RESOLVIDO.** Agora exibe **11 000 km** (antes mostrava o km inicial 10 000).
7. **Overflow de 65px no empty state de Despesas — RESOLVIDO.** A tela renderiza limpa, sem a faixa listrada do Flutter, e sem o banner verde do scan vazado.

### ⚠️ Ainda aberto (ambiental — precisa device físico)
- **Indicador de sync continua em `cloud_off`.** Tocar dispara um spinner que volta pro estado offline. O startup do `flutter run` ainda loga `A URL do Supabase não pode ser vazia` → **o backend não está configurado neste build**, então o ciclo pending→synced não é observável no simulador. A **escrita offline-first segue OK**. Para fechar o Bloco 10 de verdade: rodar com a config do Supabase (`--dart-define-from-file`) em **device físico**.

### Cosmético remanescente (menor)
- O eixo X dos LineCharts de Relatórios ainda repete "mai" várias vezes (labels poluídos). Não bloqueia nada.

**Veredito da revalidação:** os 3 itens que ainda bloqueavam homologação (Export CSV 🔴, Total 🟠, e os cosméticos de Relatórios/CO₂/garagem) estão **resolvidos**. Só resta validar o **sync em device físico com backend configurado** — fora do alcance do simulador.

---

## 0. ATUALIZAÇÃO — Reteste 18/06 (após correções do Code)

Depois que a sessão de dev aplicou os 2 fixes (save crítico de veículo + leak de URL) e relançou o app com `--dart-define-from-file=dart_define.json`, refiz **Bloco 2** e segui para o **Bloco 3** (o coração do app). Resumo:

- 🔴→✅ **Save de veículo CORRIGIDO.** O form agora revela as seções DETALHES DO VEÍCULO / Detalhes técnicos / COMBUSTÍVEL E ODÔMETRO e o campo obrigatório "Odômetro inicial". Veículo "Fiesta Teste" (Ford Fiesta) criado e persistido com sucesso.
- ✅ **Bloco 3 — cálculo de consumo (Regra de Ouro #2) VALIDADO.** Todos os valores batem:
  - Reg 1 (10000, Cheio) → **"—"** (sem baseline) ✅
  - Reg 2 (10300, Cheio) → **12,0 km/L** (300/25) ✅
  - Reg 3 (10500, Parcial) → **"—"** (parcial não fecha tanque; não corrompe a média) ✅
  - Reg 4 (10800, Cheio) → **12,5 km/L** ✅ — ver nota sobre o roteiro abaixo
- ✅ **3.4 / 3.5 (retrocesso + validação cruzada cronológica):** odômetro menor que um registro de data posterior é **bloqueado** com aviso claro ("Já existe abastecimento em 30/05 com odômetro maior (10800 km) — anterior") e o botão Salvar fica desabilitado.
- ✅ **3.6 (ordenação):** lista em ordem decrescente por data.
- ✅ **3.7 (editar → recalcula):** mudei Reg 2 de 25→30 L; consumo recalculou de 12,0 → **10,0 km/L** corretamente.
- ✅ **3.8 (excluir → recalcula):** swipe para a esquerda → diálogo de confirmação ("Cancelar / Excluir") → exclui; consumo do Reg 4 recalculou de 12,5 → **20,0 km/L** (500/25, sem o parcial). Soft delete coerente na UI.

### Erro no próprio ROTEIRO (não é bug do app)
A tabela do Bloco 3.B rotula o Reg 4 como **"12,0 km/L"**, mas a própria fórmula ao lado é `(10800−10300) ÷ (15+25) = 500/40` = **12,5 km/L**. O app calcula **12,5**, que é o matematicamente correto. **Corrigir o valor esperado no roteiro para 12,5.**

### 🟠 NOVO BUG (MÉDIO) — Total não recalcula e grava valor "stale" (integridade de dados)
- **Onde:** form de abastecimento (criar e editar), campo "Total (R$)" com chip `auto`.
- **Esperado:** Total = Litros × Preço, arredondado a 2 casas, recalculando sempre que Litros ou Preço mudam.
- **Observado:**
  1. O Total **não recalcula** quando edito Litros depois de já ter um valor (ficou "stale"). No Reg 1 deixei Litros=30 e Preço=5,89 (deveria dar **176,70**), mas o Total ficou **250,33** (resíduo de um teste anterior com 42,5 L) — e **esse valor errado foi gravado**. A lista mostra "1 mai · 30,000 L · R$ 250,32", inconsistente. O "Custo por km" do veículo herda o erro (mostrou R$ 0,79/km sobre dados inflados).
  2. Quando o produto tem mais de 2 casas (ex. 42,5 × 5,89 = 250,325) o Total exibe **3 casas decimais** ("250,325") em vez de arredondar a R$ 250,33; o rodapé mostra "R$ 250,32" (truncado).
- **Impacto:** dado financeiro incorreto gravado e propagado para custo/km e relatórios. O cálculo de **consumo (km/L)** NÃO é afetado (é baseado em odômetro/litros), por isso a Regra de Ouro #2 segue válida — mas o custo por km e somatórios de R$ ficam errados.
- **Sugestão:** recomputar `total = litros * preco` na borda sempre que qualquer um mudar; formatar/Arredondar a 2 casas (`decimal`), nunca truncar.

### 🟡 NOVO (BAIXO) — Validação de obrigatórios no form de abastecimento
- Ao salvar vazio, só **Odômetro** é sinalizado ("Informe o odômetro"); **Litros** e **Preço** não acusam erro (3.2 esperava cada obrigatório).
- O erro "Informe o odômetro" **não some** quando o campo é preenchido (só revalida no submit) — mesmo padrão do form de veículo.

### Observação positiva
O toggle "Enchi o tanque até o final" muda o texto para "Abastecimento parcial — Não conta como baseline para a média de consumo" quando desligado: UX clara. As validações de consumo e o recálculo on-edit/on-delete estão sólidos.

### Bloco 4 — Scan IA de cupom ✅ (testado com cupom real da galeria do simulador)
Havia um cupom fiscal de combustível na fototeca do simulador ("GASOLINA COMUM · 13,987L X 7,150 (40,70)"), então deu pra testar o scan de verdade.

- 4.1 ✅ Bottom sheet "DE ONDE VEM O CUPOM" com **Tirar foto** (câmera) e **Escolher da galeria**.
- 4.2 ✅ Extração pré-preencheu **Litros 13,987** e **Preço 7,15** (batem com o cupom).
- 4.3 ✅ Banner "Dados extraídos do cupom. Revise antes de salvar." — **porém VERDE com ✓**, o roteiro esperava **amarelo**. (cosmético)
- 4.4 ✅ Banner dismissa limpo no "Entendi".
- 4.5 ✅ Decimais em PT-BR com vírgula.
- 4.6 ✅ **Não crashou** com foto não-cupom (flor): retornou campos vazios. Minor: ainda mostra o banner verde "Dados extraídos do cupom" mesmo sem ter lido nada (poderia dizer "não consegui ler o cupom").
- 4.7 ✅ Salvo como abastecimento normal aparece na lista com **badge "scan" 📷** (vs "manual ✏️"); consumo 14,3 km/L correto.
- ✅ **Regra de Ouro #3 respeitada:** o scan **pré-preenche** o form e **não salva sozinho** (banner "Revise antes de salvar").

**🟠 Reforço do bug do Total (mesmo root cause):** no form, o campo "Total (R$)" mostrou **`100,00705` (5 casas decimais)** = 13,987 × 7,15, sem arredondar. Na **lista** o mesmo registro aparece corretamente como **R$ 100,01** — ou seja, o bug de arredondamento está na exibição do campo auto "Total (R$)" do form. Além disso, o Total computado (100,007) **não corresponde ao total impresso no cupom (40,70)** — vale conferir se a IA deveria extrair/honrar o total do cupom (o cupom de teste pode estar internamente inconsistente).

**Minor (cosmético):** após descartar um scan, o banner verde "Dados extraídos do cupom" apareceu **na tela de detalhe do veículo E na tela de Despesas** (persiste ao navegar — não é só transitório; só some no "Entendi").

### Bloco 5 — Despesas ✅
- 5.1 ✅ ícone 💲 → tela de Despesas. **Bug observado: "BOTTOM OVERFLOWED BY 65 PIXELS"** (faixa listrada amarela/preta do Flutter) no empty state — apareceu junto com o banner vazado; ao recarregar a tela sem o banner, renderizou ok (pode ser o banner empurrando o layout). Vale conferir o empty state das despesas.
- 5.2 ✅ Categorias em PT-BR (Manutenção, Lavagem, Estacionamento, …).
- 5.3 ✅ **R$ 1.234,56** — separador de milhar correto (formatação monetária de despesas OK; o bug de casas decimais é só no campo auto "Total" do abastecimento).
- 5.4 ✅ Agrupado por mês (JUNHO/2026); ordenação coerente.
- 5.5 ✅ Editar (toca no item) e excluir (swipe → diálogo "Cancelar / Excluir") funcionam; soft delete coerente.
- 5.6 ✅ AppBar de despesas sem ícone ✏️.
- Extra: **Descrição é obrigatória** (validou "Informe uma descrição"). Empty state tem **2 CTAs redundantes** (botão grande + pílula flutuante "Nova despesa"), mesmo padrão da garagem.

### Bloco 6 — Lembretes ✅ (inclui recorrência 6.MM)
- 6.1 ✅ ícone 🔔 → Lembretes (empty state também com 2 CTAs redundantes).
- 6.2 ✅ SegmentedButton **Por quilômetro / Por data**.
- 6.3 ✅ alvo (10000) menor que o km atual (11000) **bloqueia o salvar** com a mensagem PT-BR exata: **"Quilometragem alvo deve ser maior que a atual (11000 km)."**
- 6.4 ✅ alvo válido (20000) salva; lista "1 pendente".
- 6.5 ⏸️ Por data existe, mas **não testei o disparo da notificação local** (não dá pra avançar o relógio do simulador com segurança).
- 6.6 ✅ checkbox marca como feito → strikethrough + move pra CONCLUÍDOS, header "Tudo em dia".
- 6.7 ✅ "Repetir automaticamente" revela campo de intervalo ("Repetir a cada (km)").
- 6.8 ✅ ao concluir o recorrente (alvo 15.000), **o próximo aparece automaticamente** com **badge 🔁** e alvo **25.000** (15.000 + intervalo 10.000).
- 6.9 ✅ AppBar de lembretes sem ✏️.

### Bloco 7 — Relatórios + Comparar período ⚠️ (parcial)
- 7.1 ✅ ícone 📊 → Relatórios.
- 7.2 ✅ 3 cards: **Gasto/mês** (gráfico de **barras**, não line como o roteiro diz — cosmético), **Consumo médio** (LineChart, "Último: 14,3 km/L"), **Preço/litro** (LineChart, "Último: R$ 7,15/L"). Labels de mês em PT-BR ("mai"/"jun").
- 7.3 ⏸️ "Sem dados suficientes" não testado (o Fiesta tem dados; precisaria de um veículo vazio).
- 7.4 ❌ **Botão "Comparar período" NÃO encontrado na AppBar de Relatórios** (só "← Relatórios"). Existe uma comparação **inline** no topo ("-81,6% vs mai") e o toggle **Mês/Ano** aparece no **card de CO₂** (na tela de detalhe), mas **não achei a tela de comparação dedicada** que o roteiro descreve. Conferir se foi removido/movido ou é regressão.
- 7.5 ⏸️ toggle Mês/Ano: existe no card CO₂; sem tela de comparação dedicada pra exercitar "este mês vs anterior".
- 7.6 ✅ Card **EMISSÃO DE CO₂** na tela de detalhe: "**30,91 kg CO₂**", "Para compensar, **~1 árvore por ano**", toggle Mês/Ano, "Considera apenas a queima do combustível". **Porém o "gCO₂/km" mostrou "—"** (sem valor) mesmo havendo dados — verificar.

**🟡 NOVO (BAIXO) — Separador decimal com PONTO em vez de vírgula (i18n) nos Relatórios.** "-81.**6**% vs mai" (deveria "-81,6%") e o eixo Y do gráfico de preço mostra "R$6.**40**", "R$6.**60**" (deveria "R$ 6,40"). Os valores monetários grandes (R$ 100,01) estão corretos; o problema é em percentuais e labels de eixo dos gráficos. Além disso, o eixo X dos LineCharts repete "mai" muitas vezes (labels poluídos).

### Bloco 8 — Filtros e busca ✅
- 8.1 ✅ Bottom sheet "Filtros": busca ("Buscar por posto ou combustível"), chips **Gasolina/Etanol/Diesel/GNV**, Período (Últimos 30 dias / Este mês / Personalizado), "Só tanque cheio", "Ordenar por" (Data mais recente).
- 8.2 ✅ Aplicar Etanol → lista filtra (empty state contextual "Nenhum abastecimento com esses critérios · Tente ampliar o período…") + **badge com count "1"** no ícone de filtro.
- 8.3 ⏸️ Barra de busca existe; não dá pra medir o debounce de 300 ms por screenshots, e os registros de teste não têm posto pra busca textual.
- 8.4 ✅ "Limpar tudo" → lista volta completa, badge some.
- 8.5 ⛔ Paginação lazy + skeleton (>25 registros): só tenho 4 registros, não testável.

### Bloco 9 — Export CSV + PDF ⚠️ (PDF ok, CSV quebrado)
- 9.1 ✅ Card "Exportar dados" (agora **habilitado**, com dados) → sheet completo: dropdown **Veículo** (Fiesta Teste), chips de **Período** (Todo / Este ano / Este mês / Personalizado), botões de tipo **Abastecimentos / Despesas / Tudo**, e botão **"Histórico em PDF"**.
- 9.2 / 9.3 🔴 **CSV NÃO GERA.** Tocar em **Abastecimentos**, **Despesas** e **Tudo** **não produz nada** — sem share sheet, sem toast, sem arquivo. Testado 2× cada. Como o botão PDF na MESMA sheet abre o share sheet normalmente, o problema é **específico do export CSV** (o caminho de geração/compartilhamento do `.csv` não dispara). Logo, 9.3 (acentos/UTF-8 BOM/separador `;`/colunas) fica **bloqueado** — não há arquivo pra abrir no Excel/Sheets.
- 9.4 ✅ **PDF gera e compartilha.** "Histórico em PDF" → iOS share sheet com **`historico-fiesta-teste` · Documento PDF · 5 KB** (Pré-Visualização, Copy, Markup, Print, Salvar em Arquivos).
- 9.5 ⚠️ **Conteúdo do PDF (parcial):** capa "Histórico do Veículo — **Ford Fiesta**" com Apelido (Fiesta Teste), Ano (2016), Combustível (Gasolina), Km inicial (10000 km), Emissão (18/06/2026); seção **Consumo de Combustível** (Km total 1000 km, **Consumo médio 14,5 km/l**, Gasto total **R$ 644,83**, Abastecimentos 4); **Manutenções Realizadas** (tabela Data/Descrição/Km); **Despesas por Categoria** ("Nenhuma despesa registrada"). **Faltam vs roteiro 9.5: placa e valor FIPE.** A placa falta porque o veículo é **"sem placa"** (dado ausente, não bug). O **valor FIPE não aparece** — confirmar se deveria entrar no template do PDF. *Conferir também o "Consumo médio 14,5 km/l" — os registros individuais deram 12,0 e 12,5; ver como a média global é calculada.*
- 9.6 ✅ **Layout limpo:** tipografia boa, sem campos vazando, números em PT-BR (vírgula decimal, R$, datas dd/mm/aaaa).

### Bloco 10 — Sync e offline-first ⚠️ (offline-first ok; sync na nuvem não verificável neste ambiente)
- 10.1 🔴 **Indicador de sync fica em `cloud_off` (vermelho) permanentemente.** Tocar nele **dispara uma tentativa de sync** (vira spinner por ~3 s) e **volta para `cloud_off` vermelho** — ou seja, a sincronização **falha**. O terminal do `flutter run` mostra no startup `Invalid argument(s): A URL do Supabase não pode ser vazia` (SupabaseConfig), o que indica que **o backend pode não estar configurado neste build** → sync nunca conclui. Não dá pra afirmar a causa-raiz exata pelo simulador, mas o estado "synced/nuvem ok" do 10.1 **não foi alcançado**.
- ✅ **Regra de Ouro #1 (offline-first na escrita) — OK na prática.** Durante toda a sessão, **todas as escritas** (veículo, 4 abastecimentos, edições, exclusões, despesa, lembretes) **salvaram instantaneamente, sem spinner travando a UI**. Nenhuma escrita ficou bloqueada esperando rede. Esse é o comportamento central que o Bloco 10 quer provar, e ele passa.
- 10.2–10.6 ⛔ **Não verificáveis no simulador:** (a) o modo avião do simulador iOS não corta a conectividade real do app; (b) com o sync já falhando (Supabase vazio/inacessível), não há como observar a transição pending → synced nem confirmar que "tudo subiu". **Recomendo rodar o Bloco 10 em device físico com backend configurado.**

### 🟡 NOVO (BAIXO) — Card da garagem mostra km inicial, não o odômetro atual
- O card do "Fiesta Teste" na garagem mostra **"10 000 km"** (km inicial), mas o último abastecimento foi a **11.000 km** (a validação de lembrete inclusive usa "atual (11000 km)"). O card deveria refletir o **odômetro mais recente**, não o inicial — inconsistência de dado na visão geral.

---

## 1. Resumo executivo

> **Nota:** a seção 0 acima é a fonte mais atual. As seções 1–6 abaixo foram escritas na primeira rodada (quando o teste travou no Bloco 2) e estão **revisadas** aqui no resumo; o detalhamento por bloco mais recente está na seção 0.

Após os 2 fixes do Code (save crítico de veículo + leak de URL) e o relançamento com `--dart-define-from-file`, **o roteiro foi varrido do Bloco 0 ao 11**. O **coração do app passou**: criação/edição/exclusão de veículo (Bloco 2), **cálculo de consumo / Regra de Ouro #2** (Bloco 3, validado em todos os casos incl. recálculo on-edit e on-delete), **scan de cupom / Regra de Ouro #3** (Bloco 4, com cupom real), despesas (5), lembretes incl. recorrência (6), filtros (8) e temas (11). A **Regra de Ouro #1 (offline-first na escrita)** se confirmou na prática: todas as escritas salvaram instantâneas, sem travar.

**Bugs que ainda bloqueiam homologação:**
- 🔴 **Export CSV não gera** (Bloco 9.2/9.3) — botões Abastecimentos/Despesas/Tudo não produzem arquivo nem share sheet (o PDF na mesma tela funciona).
- 🟠 **Total (R$) "stale" + casas decimais** (Bloco 3/4) — grava valor financeiro incorreto, contamina custo/km e somatórios (consumo km/L não é afetado).
- 🔴/⚠️ **Sync na nuvem não conclui** (Bloco 10) — indicador fica em `cloud_off`; provável backend não configurado neste build. Não verificável no simulador.

**Não verificáveis no ambiente (não são reprovações):** login premium `teste@autolog.com` (sem senha), OAuth Google/Apple no simulador, disparo de notificação local, paginação >25 registros, e o ciclo completo de sync offline→online (precisa device físico + backend).

**Veredito:** **aprovação condicionada** — o núcleo funcional está sólido e bem-acabado, mas o **export CSV** e o **bug do Total** precisam de correção, e o **sync** precisa ser validado em device físico com backend configurado antes da homologação final.

---

## 2. Bugs encontrados (por severidade)

> ⚠️ O bug 🔴 de criação de veículo abaixo **já foi corrigido** no reteste de 18/06 (ver seção 0); mantido aqui como registro histórico. Os bugs ainda abertos do reteste são: **Export CSV não gera** (novo, abaixo), **Total stale/decimais** (seção 0) e **sync não conclui** (seção 0).

### 🔴 ABERTO — Export CSV não gera nenhum arquivo (Bloco 9.2/9.3)
- **Onde:** Settings → "Exportar dados" → sheet → botões **Abastecimentos / Despesas / Tudo**.
- **Esperado:** gerar `.csv` e abrir o share sheet do iOS (salvar/compartilhar).
- **Observado:** tocar em qualquer um dos 3 botões **não faz nada** — sem share sheet, sem toast, sem erro. Testado 2× cada, com período "Todo" e veículo "Fiesta Teste" (que tem dados).
- **Pista:** o botão **"Histórico em PDF"** na MESMA sheet **abre o share sheet normalmente** (gerou `historico-fiesta-teste.pdf`, 5 KB). Logo o problema é **específico do caminho de geração/compartilhamento do CSV**, não da sheet nem do share genérico.
- **Impacto:** bloqueia 9.2 e 9.3 inteiros (sem arquivo, impossível validar UTF-8 BOM / separador `;` / acentos / colunas).

### 🔴 CRÍTICO (CORRIGIDO 18/06) — Criação de veículo não persistia (Bloco 2.3)
- **Onde:** Form "Novo veículo" → botão "Adicionar veículo".
- **Esperado:** salvar, voltar para a lista, veículo aparece (offline-first, instantâneo — Regra de Ouro #1).
- **Observado:** ao tocar "Adicionar veículo" com dados válidos, **nada acontece** — sem navegação, sem mensagem de erro, sem spinner. Voltando para a garagem, ela continua **vazia** ("nenhum carro por aqui ainda").
- **Reproduzido com:** (a) dados manuais (Apelido+Marca+Modelo+Placa); (b) dados do FIPE (Ford Fiesta 1.6 16V Flex 2016); (c) placa preenchida e vazia; (d) após dispensar o foco do campo. Sempre o mesmo resultado.
- **Pista:** no form vazio o botão **responde** (mostra validação "Informe um apelido"), então o handler roda; com validação passando, o save simplesmente não conclui. Sugere falha/exception silenciosa no caminho de persistência local (repository/Drift) ou na navegação pós-save.
- **Impacto:** bloqueia Blocos 2.3–2.8, 3, 4, 5, 6, 7, 8, 9 e as partes de criação do 10/11.

### 🟠 MÉDIO — Stack trace cru + URL do Supabase vazando na UI (Bloco 1.4, caminho de rede)
- **Esperado:** mensagem PT-BR amigável, "sem stack trace".
- **Observado (quando o backend estava inacessível):** a tela exibiu a exceção crua:
  > "Erro de autenticação: ClientException with SocketException: Failed host lookup: 'vdtlldfklcrtpuumfkbm.supabase.co' (OS Error: ... errno = 8), uri=https://vdtlldfklcrtpuumfkbm.supabase.co/auth/v1/token?grant_type=password"
- Além de feio, **expõe a URL do projeto Supabase** na UI.
- **Observação:** com o backend no ar e senha errada, a mensagem é correta ("E-mail ou senha incorretos." ✅). O problema é específico do **caminho de erro de rede/inesperado** — que num app offline-first vai acontecer com frequência. Mapear para algo como "Sem conexão. Tente novamente."

### 🟠 MÉDIO — Form de veículo sem "ano", "combustível" nem seção "Detalhes"/chip "Preencher com IA" (Bloco 2.3 e 2.4)
- **Esperado (roteiro):** preencher marca, modelo, **ano**, placa, **combustível**; e expandir seção **"Detalhes"** para ver o chip **"Preencher com IA"**.
- **Observado:** o form de criação tem só IDENTIFICAÇÃO (Apelido, Marca, Modelo, Placa, RENAVAM, Chassi). **Não há** campo de ano, de combustível, nem seção "Detalhes", nem o chip de IA. Ano/combustível só aparecem via **"Buscar na FIPE"** (online).
- **Risco:** se ano/combustível **só** puderem ser definidos via FIPE (rede), isso conflita com o fallback manual offline (CLAUDE.md regra 3b). Confirmar se é design novo ou regressão; o roteiro precisa ser atualizado de qualquer forma.

### 🟡 SUSPEITO — Indicador de sync mostra "offline" estando online (Bloco 10.1)
- **Observado:** o ícone de nuvem na AppBar da home aparece como **nuvem cortada (cloud_off, vermelho)** mesmo com rede funcionando e logo após login/cadastro bem-sucedidos online. Tocar nele não mostra status.
- **Esperado (10.1):** estado "sincronizado" (check / nuvem ok) quando online.
- **A confirmar:** pode ser o indicador reportando connectivity incorretamente, ou "pendências não sincronizadas". Vale verificar a lógica do indicador.

### 🟡 BAIXO — Validação de obrigatórios e limpeza de erro (Bloco 2.2)
- Ao salvar vazio, só o **Apelido** acusa erro ("Informe um apelido"). Marca/Modelo não são sinalizados (roteiro fala "cada campo obrigatório"). Confirmar se Apelido é o único obrigatório por design.
- O erro "Informe um apelido" **não some ao digitar** no campo (só revalida no submit). UX: limpar erro on-change.

### 🟡 BAIXO / UX — Diversos
- **Permissão de notificações** é pedida **logo ao abrir (antes do onboarding)**, fora de contexto. Ideal pedir ao criar um lembrete.
- **"Pular"** aparece nos slides 1–3 mas **some no último slide** (lá só tem "Criar conta" / "Já tenho conta"). Roteiro 0.3 esperava ver "Pular" junto.
- **Empty state da garagem** tem **dois CTAs redundantes**: botão grande "Adicionar veículo" + pílula flutuante "Novo veículo".
- **Logout** está na AppBar da home (ícone de seta), **não em Settings**. Roteiro 1.12 diz "Settings → Sair", mas em Settings não há opção "Sair".
- Card **"Exportar dados"** em Settings está com o botão **desabilitado** (provavelmente por falta de dados).

---

## 3. Resultado por bloco

| Bloco | Status | Observações |
|---|---|---|
| 0 — Onboarding | ✅ Passou | 4 slides, swipe + indicador OK, Pular→login sem loop, não repete ao reabrir. Notas: notificação antes do onboarding; "Pular" some no último slide. |
| 1 — Auth | ✅ Parcial | 1.1–1.4 ✅ (variações mínimas de texto). 1.10/1.11 ✅. **1.5/1.6 não testados** (sem senha da conta premium). **1.7 Google / 1.8–1.9 Apple não testados** (OAuth não completável no simulador). 1.12 logout: ver nota UX. Bug do stack trace (rede). |
| 2 — Veículos | ✅ Corrigido | **2.3 save CORRIGIDO** (reteste 18/06) — "Fiesta Teste" criado e persistido. 2.1 ✅. 2.2 ⚠️ (só Apelido sinalizado). 2.8 (excluir) ainda pendente em veículo descartável. FIPE search funciona. |
| 3 — Abastecimento + consumo | ✅ Passou | Reteste 18/06: cálculo de consumo (—, 12,0, —, 12,5) ✅. 3.4/3.5 (retrocesso+cruzada) ✅. 3.6 ordenação ✅. 3.7 editar recalcula ✅. 3.8 excluir recalcula (→20,0) ✅. Bugs: Total stale/3-casas (integridade) + validação só de odômetro. Roteiro 3.B rotula Reg 4 errado (12,0 vs 12,5 correto). |
| 4 — Scan IA | ✅ Passou | Reteste 18/06 com cupom real: extração (13,987 L / 7,15) ✅, banner ✅ (verde, não amarelo), badge "scan" ✅, não-cupom não crasha ✅, Regra de Ouro #3 ✅. Bug: Total auto com 5 casas (100,00705). |
| 5 — Despesas | ✅ Passou | 5.1–5.6 ✅. Categorias PT-BR, R$ 1.234,56 separador ✅, editar/excluir ✅, sem ✏️ ✅, Descrição obrigatória. Bug: overflow 65px no empty state (com banner vazado). |
| 6 — Lembretes | ✅ Passou | 6.1–6.4 ✅, 6.6–6.9 ✅. Validação porKm exata ✅, recorrência 🔁 auto-gera próximo ✅. 6.5 (disparo de notificação) não testável no simulador. |
| 7 — Relatórios | ⚠️ Parcial | 7.1 ✅, 7.2 ✅ (Gasto é barra, não line), 7.6 CO₂ ✅ (mas gCO₂/km "—"). **7.4 "Comparar período" não encontrado na AppBar.** Bug i18n: "%" e eixos com ponto ("-81.6%", "R$6.40"). |
| 8 — Filtros/busca | ✅ Passou | 8.1 ✅ sheet completo, 8.2 ✅ filtra + badge count, 8.4 ✅ limpar. 8.3 (debounce) e 8.5 (paginação >25) não testáveis com 4 registros. |
| 9 — Export CSV/PDF | ⚠️ Parcial | 9.1 sheet ✅. **9.2/9.3 CSV NÃO gera (🔴, Abast./Desp./Tudo sem share sheet).** 9.4 PDF gera+compartilha ✅. 9.5 PDF conteúdo ⚠️ (falta placa[veículo sem placa] e valor FIPE). 9.6 layout PT-BR ✅. |
| 10 — Sync/offline | ⚠️ Parcial | **Offline-first na escrita ✅ (Regra de Ouro #1 OK).** Indicador fica em `cloud_off`; sync não conclui (provável backend não configurado — startup loga "URL do Supabase vazia"). 10.2–10.6 não verificáveis no simulador → **device físico + backend**. |
| 11 — Temas | ✅ Parcial | Dark em Settings + diálogos legível ✅. 11.3 "digite EXCLUIR" ✅ (2 etapas, botão desabilitado até digitar). 11.4 cancelar ✅. Telas de veículo em dark: bloqueadas. |

---

## 4. O que NÃO deu pra testar (e por quê)

> Atualizado após o reteste 18/06. O núcleo do app (Blocos 2–8, 11) **passou a ser testável** e foi varrido. O que segue sem cobertura:

1. **Login com a conta premium `teste@autolog.com` (1.5, 1.6):** a senha não está salva em repo, doc nem memória. Contornei criando um usuário novo, mas esse **não é premium**, então a **cota de IA / gating premium do scan (Bloco 4)** ficou sem validação representativa (o scan em si foi testado, mas não o limite de cota nem o caminho premium).
2. **Login social (1.7 Google, 1.8–1.9 Apple):** não consigo completar o fluxo OAuth real (escolher conta Google / capability Apple) dentro do simulador com segurança. Botões estão visíveis.
3. **Export CSV (Bloco 9.2/9.3):** não por falta de dados — **o CSV simplesmente não gera** (bug aberto). Sem arquivo, não dá pra validar UTF-8 BOM / separador `;` / acentos / colunas.
4. **Sync na nuvem / ciclo offline→online (Bloco 10.2–10.6):** (a) o modo avião do simulador iOS não corta a conectividade real do app; (b) o sync não conclui neste build (indicador `cloud_off`, startup loga "URL do Supabase vazia"). A **escrita offline-first em si foi validada** (salva instantâneo); falta só o round-trip de subida. Recomendo **device físico com backend configurado**.
5. **Disparo de notificação local (6.5):** não dá pra avançar o relógio do simulador com segurança.
6. **Debounce de busca (8.3) e paginação >25 registros (8.5):** o conjunto de teste tem só 4 abastecimentos; não exercitável.
7. **"Sem dados suficientes" em relatórios (7.3) e tela dedicada de "Comparar período" (7.4):** o Fiesta tem dados (precisaria de veículo vazio para 7.3); a tela de comparação dedicada **não foi encontrada** na AppBar (ver seção 0, possível regressão/remoção).
8. **Valor FIPE no PDF (9.5):** o PDF não mostra valor FIPE; conferir se deveria estar no template ou se o veículo não foi criado com preço FIPE.

---

## 5. Recomendações / próximos passos

1. **Prioridade #1 — Export CSV:** corrigir a geração do `.csv` (Abastecimentos/Despesas/Tudo não disparam nada; o PDF na mesma sheet funciona, então isolar o caminho do CSV). Depois revalidar 9.3 (UTF-8 BOM, separador `;`, acentos, colunas) abrindo no Excel BR/Sheets.
2. **Prioridade #2 — Total (R$):** recomputar `total = litros × preço` na borda sempre que qualquer um mudar e arredondar a 2 casas com `decimal` (nunca truncar/exibir 5 casas nem manter valor stale). Reprocessar custo/km e somatórios que herdaram o erro.
3. **Sync:** garantir que o build de teste sobe com a config Supabase (`--dart-define-from-file`) — o startup ainda loga "URL do Supabase vazia"; validar o ciclo pending→synced em **device físico**.
4. Corrigir o card da garagem para mostrar o **odômetro atual** (11.000) em vez do km inicial (10.000).
5. Caça-níqueis menores: i18n de "%" e eixos dos gráficos (vírgula), banner verde do scan que vaza ao navegar, overflow de 65px no empty state de despesas, gCO₂/km mostrando "—", e decidir o destino da tela "Comparar período".
6. Tratar o caminho de erro de rede no login para mensagem PT-BR genérica (e nunca expor a URL do Supabase) — pendente da primeira rodada.

---

## 6. Sensação geral

Resolvido o save crítico, deu pra varrer o roteiro inteiro — e o **coração do produto é sólido**. O **cálculo de consumo** (Regra de Ouro #2) está impecável em todos os casos, incluindo recálculo ao editar e ao excluir; o **scan de cupom** pré-preenche e respeita o "revise antes de salvar" (Regra de Ouro #3); e as **escritas são instantâneas** (offline-first, Regra de Ouro #1). Acabamento bom: onboarding fluido, validações PT-BR claras, busca FIPE rápida, recorrência de lembretes auto-gerando o próximo, exclusão de conta com dupla confirmação legível no dark.

O que ainda incomoda é nas **bordas de saída e de R$**: o **export CSV não gera** (o PDF gera bonito), o campo **Total (R$)** grava valor stale/com casas erradas (contamina custo/km, embora não afete o km/L), e o **sync na nuvem não fecha o ciclo** neste build. Nenhum desses toca o núcleo de cálculo — são correções localizadas. Com o CSV e o Total ajustados, e o sync validado em device físico, isso vai pra homologação tranquilo.

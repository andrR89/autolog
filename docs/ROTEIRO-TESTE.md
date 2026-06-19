# Roteiro de Teste Funcional — AutoLog

> Roteiro completo pra teste manual de todas as features entregues até a última onda (Ondas 1+2+3).
> **Objetivo:** validar o app fim-a-fim antes de partir pra Sprint 6 (monetização).
> Tempo estimado: **60-90 min** se rodar tudo.

---

## Setup (5 min, faz uma vez)

1. **App instalado**: Android (APK fornecido) ou iOS via TestFlight.
2. **Conta de teste**:
   - Email: `teste@autolog.com`
   - Senha: combinar com o Diretor antes
   - (essa conta já está marcada como **premium** no backend, então cota de IA fica liberada)
3. **Conexão**: começa **online** (Wi-Fi). Em alguns blocos vou pedir pra **ativar modo avião** propositalmente.
4. **Tela do device em mãos**: tira print de qualquer coisa estranha. Print > descrição em texto.
5. **Cronômetro mental**: se a UI travar mais de 2s em qualquer ação, **isso é bug** — anota.

### Como reportar um achado
Pra cada falha, manda:
- **Bloco / passo**: ex. "Bloco 4, passo 7"
- **Esperado vs observado**: 1 linha cada
- **Tema** em que aconteceu: light ou dark
- **Print** (sempre que possível)
- **Plataforma**: Android (modelo) ou iOS (modelo)

---

## Bloco 0 — Smoke test (2 min)

| # | Ação | Esperado |
|---|------|----------|
| 0.1 | Abrir o app pela 1ª vez (recém-instalado) | Tela de **onboarding** com 4 slides (não pula direto pro login) |
| 0.2 | Swipar entre os 4 slides | Indicador de página acompanha; conteúdo PT-BR sem palavra cortada |
| 0.3 | No último slide, ver os CTAs | Botão primário **"Criar conta"** + texto **"Já tenho conta"** + opção **"Pular"** |
| 0.4 | Tocar **"Pular"** | Vai pra `/login` sem loop |
| 0.5 | Fechar e abrir o app de novo | **Não** mostra onboarding de novo (já foi marcado como visto) |

> ⚠️ Se ficar em loop "Criar conta" → onboarding de novo → bug crítico do gate. Reporta.

---

## Bloco 1 — Auth (10 min)

### 1.A Login email/senha
| # | Ação | Esperado |
|---|------|----------|
| 1.1 | Em `/login`, deixar email vazio e tocar Entrar | Erro inline PT-BR: "Informe seu email" |
| 1.2 | Digitar email inválido (`abc`) | Erro: "Email inválido" |
| 1.3 | Email válido + senha curta (`123`) | Erro: "Senha deve ter no mínimo 6 caracteres" |
| 1.4 | Email + senha errada | Erro PT-BR de credenciais inválidas (sem stack trace) |
| 1.5 | Login correto com a conta `teste@autolog.com` | Cai na home `/vehicles` |
| 1.6 | Fechar o app e reabrir | **Continua logado** (sessão persistida) |

### 1.B Login Google
| # | Ação | Esperado |
|---|------|----------|
| 1.7 | Em `/login` tocar "Entrar com Google" | Abre navegador OAuth, escolhe conta, volta pro app logado |

### 1.C Apple Sign In (só iOS)
| # | Ação | Esperado |
|---|------|----------|
| 1.8 | Em iOS, ver botão "Continuar com Apple" em `/login` | Visível **só em iOS** (não aparece no Android) |
| 1.9 | Tocar o botão | Por enquanto dá **erro esperado** (capability ainda não configurada — débito 6.LL.iOS). Reporta se travar ou crashar |

### 1.D Cadastro
| # | Ação | Esperado |
|---|------|----------|
| 1.10 | `/signup` com email já existente | Erro PT-BR "Email já cadastrado" (ou similar, claro) |
| 1.11 | Cadastro novo válido (use email descartável) | Cai logado na home |

### 1.E Logout
| # | Ação | Esperado |
|---|------|----------|
| 1.12 | Settings → Sair | Volta pra `/login` limpo |

---

## Bloco 2 — Veículos (CRUD) (10 min)

> Logar de volta com `teste@autolog.com`.

> **Layout do form (cima → baixo, scroll vertical):**
> 1. Botões **"Buscar na FIPE"** e **"Escanear CRLV"**
> 2. Seção **"Identificação"**: Apelido (obrigatório), Marca, Modelo, Placa, RENAVAM, Chassi
> 3. Seção **"Detalhes do veículo"**: **Ano**, UF, Cor
> 4. Seção **"Detalhes técnicos"** (colapsável, fechada por padrão): Cilindrada, Capacidade do tanque, Potência + chip **"Preencher com IA"** (só aparece quando Marca+Modelo+Ano preenchidos)
> 5. Seção **"Combustível e odômetro"**: **TIPO DE COMBUSTÍVEL** (segmentado) e **Odômetro inicial** (obrigatório)
> 6. Barra sticky no fim: botão **"Adicionar veículo"**

| # | Ação | Esperado |
|---|------|----------|
| 2.1 | Tocar **+** pra adicionar veículo | Form abre com botão **voltar** na AppBar |
| 2.2 | Tentar salvar vazio | SnackBar PT-BR **"Verifique os campos obrigatórios destacados."** + scroll até o primeiro campo com erro vermelho. Apelido e Odômetro inicial marcam erro. |
| 2.3 | Preencher: **apelido**, marca, modelo, **ano**, placa, **combustível** e **odômetro inicial** (scroll até o fim) | Salva, volta pra lista, veículo aparece |
| 2.4 | Expandir a seção **"Detalhes técnicos"** (após preencher Marca+Modelo+Ano) | Chip **"Preencher com IA"** aparece (ícone ✨ + label brand) |
| 2.4b | Validar o chip "Preencher com IA" em **light** e **dark** | Visível nos dois: fundo brand com transparência, borda fina, ícone+texto na cor brand |
| 2.5 | Tocar no veículo na lista | Vai pra detalhe (fuel history) |
| 2.6 | Pencil ✏️ na AppBar do detalhe | Abre form de **editar** (não criar) com dados carregados |
| 2.7 | Editar e salvar | Volta pro detalhe atualizado |
| 2.8 | Lista → swipe ou menu → excluir veículo | Confirma → some da lista (soft delete) |

> ⚠️ Form sem botão voltar = regressão da Sprint 2. Reporta.
> ⚠️ Tocar "Adicionar veículo" **sem feedback nenhum** (nem SnackBar nem scroll) = regressão do fix de 18/06. Reporta.

---

## Bloco 3 — Abastecimento manual + cálculo de consumo (15 min)

> Este é o coração do app. **Cálculo errado aqui é bug crítico.**

### 3.A CRUD
| # | Ação | Esperado |
|---|------|----------|
| 3.1 | Detalhe do veículo → **+** abastecimento | Form com voltar |
| 3.2 | Salvar vazio | Erros inline |
| 3.3 | Decimais com **vírgula** (PT-BR): litros `42,5`, preço `5,89` | Aceita; **total auto-calcula** (`42,5 × 5,89 = 250,33`) e mostra `R$` formatado |
| 3.4 | Odômetro retrocedendo (menor que o último) | Form **bloqueia o Salvar** + mensagem PT-BR inline ("Quilometragem menor que o último registro") |
| 3.5 | Inserir abastecimento entre dois existentes com odômetro fora de ordem | Bloqueia também (validação cronológica cruzada) |
| 3.6 | Salvar válido | Aparece na lista; ordenação por **data DESC, depois odômetro DESC** |
| 3.7 | Tocar no item → editar litros → salvar | Lista atualiza; consumo recalcula se afetado |
| 3.8 | Swipe ou menu → excluir | Soft delete; consumo recalcula |

### 3.B Cálculo (Regra de Ouro #2)

Cria um veículo de teste com odômetro inicial `10000` e adiciona em ordem:

| Reg | Data | Odômetro | Litros | Tipo | Consumo esperado |
|-----|------|----------|--------|------|------------------|
| 1 | 01/05 | 10000 | 30 | Cheio | **—** (sem baseline) |
| 2 | 10/05 | 10300 | 25 | Cheio | **12,0 km/L** (300 km / 25 L) |
| 3 | 20/05 | 10500 | 15 | Parcial | **—** (parcial não fecha tanque) |
| 4 | 30/05 | 10800 | 25 | Cheio | **12,5 km/L** ((10800−10300) ÷ (15+25) = 500/40) |

> ⚠️ Se aparecer um número em vez de "—" no primeiro abastecimento, ou no parcial intermediário, **é bug crítico**. Reporta com prints.

---

## Bloco 4 — Scan IA de cupom (10 min)

> Conta `teste@autolog.com` é premium, então cota não estoura. Mesmo assim, vamos só **2 scans** pra preservar custo.

| # | Ação | Esperado |
|---|------|----------|
| 4.1 | Form de abastecimento → botão câmera/IA | Bottom sheet **Câmera** / **Galeria** |
| 4.2 | Escolher uma foto de cupom de posto (qualquer) | Loading; depois **pré-preenche** litros + preço + data |
| 4.3 | Banner **verde-cana** (`successSoft`) com ícone ✓ acima do form | "Dados extraídos do cupom. Revise antes de salvar." (verde é deliberado — convite à revisão, não cuidado/erro) |
| 4.3b | Foto **não-cupom** ou cupom ilegível → IA retorna vazio | Banner **âmbar** (`warningSoft`) com ícone `image_search`: "Não consegui ler o cupom. Tente outra foto ou preencha manualmente." |
| 4.4 | Tocar X / OK no banner | Banner **dismissa** (não fica fantasma) |
| 4.5 | Conferir valores em PT-BR (vírgula) | Decimais com `,` (não `.`) |
| 4.6 | Foto não-cupom (selfie, paisagem) | App responde gracioso (ou pré-preenche vazio, ou mostra erro PT-BR — **não pode crashar**) |
| 4.7 | Salvar como abastecimento normal | Aparece na lista com badge **`ai_scan`** (ou indicador visual) |

> ⚠️ Se o scan **salvar sozinho sem confirmação** = viola Regra de Ouro #3. Bug crítico.

---

## Bloco 5 — Despesas (5 min)

| # | Ação | Esperado |
|---|------|----------|
| 5.1 | Detalhe veículo → ícone **💲** na AppBar | Vai pra lista de despesas |
| 5.2 | + → form | Categorias em PT-BR (Manutenção, IPVA, Seguro, etc.) |
| 5.3 | Valor com vírgula `1234,56` | Lista mostra **R$ 1.234,56** (separador de milhar) |
| 5.4 | Ordenação | Data DESC |
| 5.5 | Editar / excluir item | Funciona |
| 5.6 | AppBar de despesas | **Sem ícone ✏️** (a edição do veículo só pelo detalhe) |

---

## Bloco 6 — Lembretes (10 min)

| # | Ação | Esperado |
|---|------|----------|
| 6.1 | Detalhe veículo → ícone **🔔** | Lista de lembretes |
| 6.2 | + → form | SegmentedButton **porKm** / **porData** |
| 6.3 | porKm com alvo **menor** que km atual do veículo | Salvar **bloqueado** + msg PT-BR "Quilometragem alvo deve ser maior que a atual (X km)" |
| 6.4 | porKm com alvo válido | Salva |
| 6.5 | porData no futuro | Salva; ao chegar a data, notificação local dispara |
| 6.6 | Lista → toggle "done" direto | Risca o item (strikethrough) |
| 6.7 | **Recorrente (6.MM)**: criar lembrete com toggle "Repetir automaticamente" ativo | Define intervalo (dias OU km) |
| 6.8 | Marcar esse recorrente como done | **Próximo lembrete aparece automaticamente** com badge 🔁 |
| 6.9 | AppBar de lembretes | Sem ícone ✏️ |

---

## Bloco 7 — Relatórios + Comparar período (5 min)

| # | Ação | Esperado |
|---|------|----------|
| 7.1 | Detalhe veículo → ícone **📊** | Tela de Relatórios |
| 7.2 | 3 cards: **Gasto/mês**, **Consumo médio/mês**, **Preço/litro/mês** | Cada um com LineChart + labels PT-BR ("mai/2026") |
| 7.3 | Veículo sem dados | "Sem dados suficientes ainda." em cada card |
| 7.4 | Botão **"Comparar período"** na AppBar | Abre tela de comparação |
| 7.5 | Toggle [Mês] / [Ano] | Dados alternam (este mês vs anterior / este ano vs anterior) |
| 7.6 | Card **CO₂** no fuel_history | Mostra **kg de CO₂** + **gCO₂/km** + "Para compensar, ~N árvores" |

---

## Bloco 8 — Filtros e busca em fuel_history (5 min)

| # | Ação | Esperado |
|---|------|----------|
| 8.1 | Lista de abastecimentos → ícone de filtro | Bottom sheet com **chips de combustível** + **period picker** + **sort** |
| 8.2 | Aplicar filtro de combustível | Lista filtra; **badge com count** aparece no ícone |
| 8.3 | Barra de busca → digitar (ex. nome do posto) | Debounce ~300ms antes de filtrar |
| 8.4 | Limpar filtros | Lista volta completa |
| 8.5 | Lista com **>25 abastecimentos** | Paginação lazy (não trava ao scrollar) + **skeleton** enquanto carrega |

---

## Bloco 9 — Export CSV + PDF (5 min)

### 9.A CSV
| # | Ação | Esperado |
|---|------|----------|
| 9.1 | Settings → ExportCard | Sheet pra escolher **veículo** + **tipo** (abastecimentos/despesas) + **período** |
| 9.2 | Gerar | Arquivo `.csv` salvo / compartilhado |
| 9.3 | Abrir no Excel BR ou Google Sheets | **Acentos OK** (UTF-8 com BOM), **separador `;`**, colunas alinhadas |

### 9.B PDF "Histórico do veículo"
| # | Ação | Esperado |
|---|------|----------|
| 9.4 | Mesma sheet → botão **"Gerar PDF"** | PDF abre/compartilha |
| 9.5 | Conteúdo do PDF | **Capa** com marca/modelo/placa + FIPE + **consumo médio** + **manutenção** + **despesas** |
| 9.6 | Layout | Tipografia limpa, sem campos vazando, números em PT-BR |

---

## Bloco 10 — Sync e offline-first (10 min)

> Esse bloco prova a Regra de Ouro #1.

| # | Ação | Esperado |
|---|------|----------|
| 10.1 | Indicador de sync na AppBar (home) | Estado **sincronizado** (check / nuvem ok) |
| 10.2 | Ativar **modo avião** | Indicador muda pra **offline** (cloud_off ou similar) |
| 10.3 | Criar veículo + 2 abastecimentos offline | **Salva instantâneo** sem spinner travando; ficam com badge "pending" |
| 10.4 | Editar/excluir um deles offline | Funciona, fica pending |
| 10.5 | Desativar modo avião | Indicador volta pra **sincronizando** → **synced** |
| 10.6 | Conferir que tudo subiu | Pendings somem; dados consistentes |

> ⚠️ Se **qualquer escrita** travou esperando rede, é violação da Regra de Ouro #1. Bug crítico.

---

## Bloco 11 — Tema claro + escuro (5 min)

> Validar **toda tela aberta neste roteiro** em ambos os temas.

| # | Ação | Esperado |
|---|------|----------|
| 11.1 | Trocar pra dark (Settings ou system) | Não há **texto invisível**, **fundo branco em dialog**, ou **chip apagado** |
| 11.2 | Reabrir: login, onboarding, lista veículos, form veículo (incluindo chip "Preencher com IA"), abastecimento, scan banner, despesas, lembretes, relatórios, comparar período, CSV sheet, PDF sheet | Tudo legível em ambos |
| 11.3 | Settings → **Excluir minha conta** (LGPD 7.3) | Diálogo **"digite EXCLUIR"** legível em **light E dark** (fundo + texto + botão) — **NÃO confirmar** com a conta de teste premium! |
| 11.4 | Cancelar o diálogo | Volta sem efeito |

> ⚠️ Achados de tema viraram fixes 6.L e 7.3 na última onda. Olhar com olho clínico esses dois pontos.

---

## Bloco 12 — Voltar ao normal

| # | Ação | Esperado |
|---|------|----------|
| 12.1 | Sair (logout) | Volta pra login |
| 12.2 | Desinstalar o app no fim | Limpa estado pro próximo teste |

---

## Resumo do que reportar

Ao final, manda pro Diretor:
1. **Lista de bugs** numerada por bloco/passo, com print + tema + plataforma
2. **Tempo total** que demorou (ajuda calibrar próximos roteiros)
3. **Sensação geral**: 1 frase sobre fluidez, polish, frustrações
4. Coisas que **te surpreenderam positivamente** (também conta)

Obrigado! 🚗

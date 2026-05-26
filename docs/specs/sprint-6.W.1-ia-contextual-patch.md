# Sprint 6.W.1 — Patch IA contextual (chat + manutenção + fiscal 27 UFs)

> Patch corretivo (Onda 2 follow-up). Aumenta contexto que IA recebe e
> estende calendário fiscal para todas as 27 UFs brasileiras.

## Decisões
- **Sem schema novo**, **sem migration**. Refactor de prompts + dados hardcoded.
- 3 fixes independentes na mesma sprint pra agrupar 1 deploy.

## Fix 1 — Chat IA recebe contexto rico

`supabase/functions/chat-history/index.ts` — `buildSystemPrompt`:

Hoje só passa `year + make + model + uf`. Vamos passar:
- Veículo: `year + make + model + plate + type + color + uf` (sem renavam/chassi por privacidade)
- Specs: `engineDisplacementCc + tankCapacityL + horsepower` (quando preenchidos)
- FIPE: `fipeValue + fipeReferenceMonth` (quando preenchidos)
- **Stats computadas** no backend antes de mandar pra IA:
  - `currentOdometerKm` = max(odometer) das fuel entries
  - `totalKmDriven` = max - min
  - `avgConsumptionKmL` = totalKmDriven / sum(liters), null se < 2 fuels
  - `favoriteStation` = top entriesCount entre (brand, name) identificados
  - `topExpenseCategory` = categoria com mais entries
  - `activeRemindersCount` = reminders não-deletados, não-feitos
  - `cheapestPricePerLiter` / `mostExpensivePricePerLiter` no histórico

Formato do system prompt expandido (PT-BR):
```
Você é o assistente do AutoLog.

# Veículo do usuário
Honda Civic LX 2018 • placa ABC1D23 • carro • cor preta • SP
Cilindrada: 1600 cc · Tanque: 47 L · Potência: 124 cv
FIPE: R$ 78.420 (jan/26)

# Stats agregadas (últimos 36m)
Odômetro atual: 65.432 km · Total rodado: 28.200 km
Consumo médio: 11,2 km/L
Posto preferido: Shell • BR-101 km 87 (14 visitas)
Categoria de despesa mais frequente: Manutenção
Preço gasolina: R$ 5,29 (mín) a R$ 6,15 (máx)
Lembretes ativos: 3

# Histórico bruto (últimos 20 abastecimentos / 20 despesas / 5 lembretes)
... (já tinha)
```

## Fix 2 — `suggest-maintenance` regional

`supabase/functions/suggest-maintenance/index.ts`:

Adicionar 2 params opcionais ao body:
- `vehicle_uf?: string` — clima/região influencia (litoral = corrosão, etc).
- `current_odometer_km?: number` — pra priorizar peças críticas se km alto.

`buildPrompt` ganha:
```
Tipo: carro
Marca: Honda
Modelo: Civic LX
Ano: 2018
  Cilindrada: 1600 cc
  Tanque: 47 L
  UF: SP                              ← novo
  Quilometragem atual: 65.432 km     ← novo
```

E sufixo no prompt:
```
- Se UF for litorânea (RJ, SP, BA, CE, PE, etc.), considere itens de
  prevenção a corrosão.
- Se quilometragem >= 80.000 km, priorize correia, embreagem e
  suspensão.
- Se ano <= 2010, mencione revisão de mangueiras e borrachas.
```

UI (`maintenance_plan_screen.dart`) — calcular `currentOdometerKm` do veículo
(max das fuel entries via `fuelEntryRepository.listByVehicle`) e passar
pro service.

Service (`MaintenanceSuggestionService.suggest`) — adicionar 2 params
opcionais.

## Fix 3 — Calendário fiscal completo (27 UFs)

`lib/features/insights/fiscal_calendar.dart`:

Substituir os 6 estados atuais por todos os 27. Valores baseados em
calendário típico 2024-2026 (disclaimer "Confira no Detran" já existe
na UI do 6.N).

| Região    | UFs adicionadas |
|-----------|-----------------|
| Sudeste   | ES |
| Sul       | (já cobertos PR, RS, SC) |
| C-Oeste   | DF, GO, MT, MS |
| Nordeste  | AL, BA, CE, MA, PB, PE, PI, RN, SE |
| Norte     | AC, AM, AP, PA, RO, RR, TO |

Pattern típico: IPVA entre janeiro e maio distribuído por final de placa;
licenciamento entre julho e novembro/dezembro distribuído por final.

Estados especiais com **cota única no mesmo mês para todas as placas**:
- DF, PR (já) — IPVA cota única.
- RR — IPVA único em janeiro.
- SC (já) — IPVA único em fevereiro.

Manter `_defaultCalendar` como fallback defensivo (caso futura UF nova
ou letra inválida).

## Testes

### `test/features/insights/fiscal_calendar_27_ufs_test.dart` (novo)
- `brFiscalCalendar.length == 27`.
- Contém todas as 27 UFs canônicas (AC, AL, AP, AM, BA, CE, DF, ES, GO,
  MA, MT, MS, MG, PA, PB, PR, PE, PI, RJ, RN, RS, RO, RR, SC, SP, SE, TO).
- Cada UF tem `ipva` e `licensing` com pelo menos 10 entradas
  (cobrindo dígitos 0-9).
- Cada UF retorna proposta válida pra `suggestFiscalReminders` (IPVA +
  Licenciamento com `dueDate != null`).

### `test/features/insights/maintenance_suggestion_service_test.dart` (estender)
Adicionar testes:
- `suggest(..., vehicleUf: 'SP', currentOdometerKm: 80000)` envia esses
  campos no body como `vehicle_uf` e `current_odometer_km`.
- Sem esses params → não envia (campos omitidos do body).

### `test/features/chat/chat_service_test.dart` (estender)
Sem mudança — chat-history mexe só no prompt server-side, não muda
contrato do client.

## Critérios de aceite
- [ ] Todos testes verdes (751+ + ~10 novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Deploy `chat-history` + `suggest-maintenance` no Supabase
- [ ] Smoke manual: pergunta no chat "qual meu posto preferido?" → IA
  responde direto sem dados brutos.

## Não-objetivos
- Validar datas exatas com SEFAZ de cada UF (impossível sem API).
- Adicionar fiscais variáveis (multas avulsas, simples assim).
- Privacidade: NÃO mandar renavam/chassi pro Haiku (decisão).

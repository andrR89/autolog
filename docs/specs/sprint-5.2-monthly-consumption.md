# Spec — Sprint 5.2: Consumo médio (km/l) por mês

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende da 2.2 (regra de tanque cheio do PRD §7). Função pura, sem deps externas.

## Regra de agregação (importante)
Consumo mensal **não é média aritmética dos km/l de cada ciclo** — isso enviesa quando ciclos têm km muito diferentes. A forma correta é **ponderada por km**:

```
consumo_mensal = sum(km_dos_ciclos_que_fecham_no_mês) / sum(litros_dos_ciclos_que_fecham_no_mês)
```

Mês do "ciclo" = mês da entry que **fecha** o ciclo (cheio que define o consumo). Parciais não fecham nada.

## Decisões técnicas

### 1. Função pura
`lib/features/reports/monthly_consumption.dart`:
```dart
class MonthlyConsumption {
  const MonthlyConsumption({required this.month, required this.kmPerLiter});
  final DateTime month; // UTC, primeiro dia do mês
  final Decimal kmPerLiter; // ponderado por km, escala 4
}

/// Espera entries do mesmo veículo, ordenados por data ASC.
/// Retorna lista ASC por mês. Meses sem ciclos fechados NÃO aparecem.
List<MonthlyConsumption> computeMonthlyConsumption(List<FuelEntry> entriesAsc);
```

### 2. Algoritmo
- Mantém `lastFullIndex` (índice do último cheio).
- Itera entries em ordem.
- Quando `entries[i].fullTank == true && lastFullIndex != null`:
  - `km = entries[i].odometer - entries[lastFullIndex].odometer`.
  - `liters = soma de liters de entries[lastFullIndex+1..i] inclusivo`.
  - Se `km > 0` E `liters > Decimal.zero`:
    - `month = bucketOf(entries[i].date)` (UTC dia 1).
    - `acc[month].km += km`; `acc[month].liters += liters`.
- Após `i`, se `entries[i].fullTank`: `lastFullIndex = i` (mesma regra defensiva da 2.2 — atualiza baseline mesmo quando km<=0).
- Ao fim: pra cada mês com dados, `kmPerLiter = (Decimal.fromInt(km) / liters).toDecimal(scaleOnInfinitePrecision: 4).round(scale: 4)`. Retorna ordenado por mês ASC.

### 3. Decimal sagrado
- Soma usa `Decimal +`.
- Divisão final usa Decimal API; `.toDecimal(...).round(scale: 4)` — sem double.

## Critérios de aceite (= testes em `test/features/reports/monthly_consumption_test.dart`)

1. **Lista vazia** → vazio.
2. **Um único entry** (cheio ou parcial) → vazio (sem ciclo fechado).
3. **Dois cheios no mesmo mês**: E1 cheio (15/05, 10000, 0L) + E2 cheio (25/05, 10500, 40L) → 1 bucket maio com km/l = 500/40 = 12,5000.
4. **Ciclo que abre num mês e fecha em outro**: E1 cheio (28/04), E2 cheio (10/05, 500km/40L) → bucket é maio (mês do **fechamento**), km/l = 12,5000.
5. **Múltiplos ciclos no mesmo mês — ponderado por km**:
   - E1 cheio (1/05, 10000), E2 cheio (10/05, 10500, 40L) → ciclo1: 500km/40L.
   - E3 cheio (20/05, 11000, 50L) → ciclo2: 500km/50L.
   - Bucket maio: km total = 1000, litros = 90 → 1000/90 = 11,1111.
6. **Múltiplos meses**: ciclo1 fecha em maio (12,5), ciclo2 fecha em junho (10,0) → 2 buckets ordenados ASC.
7. **Precisão decimal exata**: E1@10000, E2@10250 (+250km, 22.5L) — 250/22.5 = 11,1111.
8. **Ciclo com km <= 0 ou litros == 0**: ignorado (não polui o mês). Caso: odômetro regrediu entre dois cheios — esse ciclo é skip.

## Definition of Done
- 8 testes verdes; suíte completa verde (~267); `dart format`; `flutter analyze` limpo.
- Sem `double` no path do consumo.
- Função pura, sem providers/deps.

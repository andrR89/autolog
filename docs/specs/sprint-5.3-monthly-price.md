# Spec — Sprint 5.3: Evolução do preço/litro por mês

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Pure function, espelha estrutura de 5.1/5.2.

## Regra
Preço médio mensal = **média ponderada por litros**:
```
preço_médio_mês = sum(fuel_entries.totalCost no mês) / sum(fuel_entries.liters no mês)
```
Esse é o preço efetivo que o usuário pagou no mês — ponderar por litros é mais informativo que média aritmética dos preços/litro (que daria peso igual a um abastecimento de 5L e um de 50L).

## Decisões técnicas

### 1. Função pura
`lib/features/reports/monthly_price.dart`:
```dart
class MonthlyPrice {
  const MonthlyPrice({required this.month, required this.pricePerLiter});
  final DateTime month; // UTC, dia 1
  final Decimal pricePerLiter; // escala 4
}

/// Espera fuel_entries do mesmo veículo (caller filtra soft-deleted via repo).
/// Retorna lista ASC por mês. Meses sem litros (ou tudo zero) NÃO aparecem.
List<MonthlyPrice> computeMonthlyPrice(List<FuelEntry> fuelEntries);
```

### 2. Algoritmo
- Bucket: `DateTime.utc(date.year, date.month, 1)`.
- Acumular por bucket: `cost += e.totalCost` e `liters += e.liters`.
- Após acumular: pra cada bucket onde `liters > Decimal.zero`, `pricePerLiter = (cost / liters).toDecimal(scaleOnInfinitePrecision: 4).round(scale: 4)`.
- Pular bucket onde `liters == 0` (defensivo).
- Retorno ordenado ASC por mês.

### 3. Decimal sagrado
- Soma com `Decimal +`.
- Divisão com Decimal API + `.round(scale: 4)`.
- Zero `double`.

## Critérios de aceite (= testes em `test/features/reports/monthly_price_test.dart`)

1. **Lista vazia** → vazio.
2. **Um fuel só no mês**: 40L, R$ 200 → preço/L = 5,0000.
3. **Múltiplos fuels no mês, ponderado por litros**:
   - E1 (5/05): 10L × R$ 5/L = R$ 50.
   - E2 (15/05): 40L × R$ 6/L = R$ 240.
   - Total: 50L, R$ 290. Preço médio = 290/50 = 5,8000.
   - (Média aritmética simples seria 5,5000 — confirma que estamos ponderando.)
4. **Múltiplos meses**: maio R$ 5,0000, junho R$ 6,0000 → 2 buckets ordenados ASC.
5. **Precisão decimal**: 100/3 = 33,3333 (infinito → escala 4).
6. **Liters zero defensivo** (entry com liters=0): bucket pulado se for o único; ou só não conta se houver outros entries no mês (a soma só considera os com liters>0... ou todos? Decisão: se TODOS no mês tiverem liters=0, o bucket inteiro é pulado — `liters_total == 0`).
7. **Ordem ASC garantida** com input desordenado.
8. **Bucket UTC dia 1** independente da hora/dia.

## Definition of Done
- 8 testes verdes; suíte completa verde (~275); `dart format`; `flutter analyze` limpo.
- Sem `double` no path do preço.
- Pure function.

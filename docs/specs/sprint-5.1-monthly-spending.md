# Spec — Sprint 5.1: Agregação de gasto total por mês

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Primeira de 4 agregações da Sprint 5 (gasto/mês, consumo médio, evolução preço/litro, telas+gráficos).
> Depende de 2.1 (`FuelEntryRepository`) + 4.1a (`ExpenseRepository`).

## Escopo
Função pura que recebe abastecimentos + despesas de um veículo e devolve gasto total agregado por mês (calendário). Combustível (`total_cost` de fuel_entries) + despesas (`amount` de expenses).

Fora de escopo: UI/gráficos (5.4); outras agregações (5.2/5.3).

## Decisões técnicas

### 1. Função pura
`lib/features/reports/monthly_spending.dart`:
```dart
class MonthlyTotal {
  const MonthlyTotal({required this.month, required this.total});
  /// Primeiro dia do mês em UTC, à meia-noite. Identifica o "bucket".
  final DateTime month;
  /// Soma de fuel_entries.totalCost + expenses.amount do mês.
  final Decimal total;
}

/// Agrega gasto total (combustível + despesas) por mês.
/// Retorna lista ordenada por mês ASC. Meses sem dados não aparecem.
/// Soft-deleted devem vir já filtrados pelos repositórios.
List<MonthlyTotal> computeMonthlySpending({
  required List<FuelEntry> fuelEntries,
  required List<Expense> expenses,
});
```

### 2. Cálculo
- Bucket: `DateTime.utc(date.year, date.month, 1)` — meia-noite UTC do dia 1 do mês.
- Inicializa accumulator `Map<DateTime, Decimal>`.
- Itera fuel_entries: `acc[bucket] = (acc[bucket] ?? Decimal.zero) + e.totalCost`.
- Itera expenses: `acc[bucket] = (acc[bucket] ?? Decimal.zero) + ex.amount`.
- Devolve lista de `MonthlyTotal` ordenada por `month` ascendente.

### 3. Decimal sagrado
- Soma usa `Decimal +` (nunca `double`).
- Nada de `.toDouble()` em nenhum ponto da agregação.

## Critérios de aceite (= testes em `test/features/reports/monthly_spending_test.dart`)

1. **Listas vazias** → lista vazia.
2. **Só fuel, mesmo mês**: 2 entries em maio/2026 (R$ 200 + R$ 150) → 1 bucket maio/2026 com total R$ 350.
3. **Só expenses, mesmo mês**: 2 expenses em junho/2026 (R$ 100 + R$ 50) → 1 bucket junho/2026 com total R$ 150.
4. **Fuel + expenses no mesmo mês**: fuel R$ 200 + expense R$ 100 em julho/2026 → 1 bucket julho/2026 com total R$ 300.
5. **Meses diferentes**: fuel em maio R$ 200, expense em julho R$ 100 → 2 buckets ordenados por mês ASC (maio, julho).
6. **Decimal preciso**: entries com totais como `123.45` e `67.89` → soma `191.34` exata (igualdade Decimal).
7. **Ordem ASC garantida** mesmo com input desordenado.
8. **Mês como bucket UTC dia 1**: entry com data `DateTime.utc(2026, 5, 23, 14, 30)` resulta em bucket `DateTime.utc(2026, 5, 1)`.

## Definition of Done
- 8 testes verdes; suíte completa verde (~259); `dart format`; `flutter analyze` limpo.
- Sem `double` no path do gasto.
- Função pura (sem deps externas/providers).

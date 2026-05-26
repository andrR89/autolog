# Sprint 6.Q — Custo por KM + análise de tendência

> Onda 2, sprint 5/10. Pura — só análise de dados que já existem.
> Zero schema novo, zero IA, zero migration.

## Decisões pragmáticas
- Tudo função pura sobre `List<FuelEntry>` + `List<Expense>` do veículo.
- Cards no detalhe do veículo (`fuel_history_screen`).
- Tendência baseada em comparação de janelas (últimos 3 meses vs 3 meses anteriores).

## Funções puras

### `lib/features/reports/cost_per_km_calculator.dart`

```dart
class CostMetrics {
  const CostMetrics({
    required this.totalKm,
    required this.fuelCost,
    required this.otherCost,
    required this.totalCost,
    required this.fuelCostPerKm,    // null se totalKm == 0
    required this.totalCostPerKm,   // null se totalKm == 0
  });
  final int totalKm;
  final Decimal fuelCost;
  final Decimal otherCost;
  final Decimal totalCost;
  final Decimal? fuelCostPerKm;
  final Decimal? totalCostPerKm;
}

/// Computa custo por km para uma janela de fuelEntries/expenses.
/// totalKm = max(odometer) - min(odometer) das fuel entries da janela.
/// Se há < 2 fuel entries → totalKm = 0 e *PerKm = null.
/// Despesas (Expense) sem odometer entram no custo total mas não no totalKm.
CostMetrics computeCostMetrics({
  required List<FuelEntry> fuels,
  required List<Expense> expenses,
});
```

### `lib/features/reports/trend_analyzer.dart`

```dart
enum TrendDirection { up, down, stable }

class TrendAnalysis {
  const TrendAnalysis({
    required this.direction,
    required this.deltaPercent,    // Decimal positivo se subiu, negativo se caiu
    required this.currentValue,
    required this.previousValue,
    required this.hasEnoughData,   // false se < 2 fuel entries em alguma janela
  });
  final TrendDirection direction;
  final Decimal deltaPercent;
  final Decimal currentValue;
  final Decimal previousValue;
  final bool hasEnoughData;
}

/// Analisa tendência comparando duas janelas de tempo iguais.
/// stableThreshold: variação ≤ X% conta como "stable" (default 5%).
/// Se uma das janelas tem dados insuficientes, retorna hasEnoughData = false
/// e direction/deltaPercent indefinidos (stable + 0%).
TrendAnalysis analyzeConsumptionTrend({
  required List<FuelEntry> entries,
  required DateTime now,
  Duration windowSize = const Duration(days: 90),
  Decimal? stableThreshold,
});

TrendAnalysis analyzeSpendingTrend({
  required List<FuelEntry> fuels,
  required List<Expense> expenses,
  required DateTime now,
  Duration windowSize = const Duration(days: 90),
  Decimal? stableThreshold,
});
```

Helpers internos:
- `computeConsumption(List<FuelEntry>)` — média km/L na janela (usa cálculo de consumo já existente em `consumption_calculator.dart`).
- `totalSpending(...)` — soma despesas + fuel costs na janela.

## UI

### `lib/features/reports/widgets/cost_per_km_card.dart`

Card no detalhe do veículo:
- Header: "Custo por KM"
- 2 linhas grandes: "Combustível: R$ 0,42/km", "Total: R$ 0,68/km"
- Sub: período coberto ("Últimos 12 meses, baseado em 24 abastecimentos")
- Empty state se sem dados: "Cadastre mais abastecimentos pra calcular."

### `lib/features/reports/widgets/trend_badge.dart`

Componente reutilizável:
- Ícone de seta (up/down/equal) + percentual ("+8,2%" / "-3,1%" / "0,0%").
- Cor: verde quando bom (consumo descendo OU sem alteração); vermelho quando ruim.
- Convenção: pra **consumo (km/L)**, descer é RUIM (carro tá consumindo mais por km). Pra **gasto**, descer é BOM.

### `lib/features/reports/widgets/trend_card.dart`

Card resumo no detalhe:
- "Consumo (últimos 3 meses vs anteriores): 11,2 km/L → 10,4 km/L [-7,1%]"
- "Gasto mensal médio: R$ 380 → R$ 420 [+10,5%]"
- Empty state: "Dados insuficientes."

### Integração na tela
`lib/features/fuel/fuel_history_screen.dart`:
- Adicionar os 2 cards (cost + trend) na parte de cima, logo após o header do veículo, antes da listagem de fuel entries.
- Discreto: só renderiza se houver pelo menos 1 fuel entry. Senão omite os cards.

## Testes RED

### `test/features/reports/cost_per_km_calculator_test.dart`

- Lista vazia → totalKm=0, costs=0, perKm=null.
- 1 fuel entry → totalKm=0, perKm=null (precisa baseline).
- 2+ fuel entries — calcula corretamente (totalKm = max - min odometer, fuelCost = soma totalCost, perKm = fuelCost/totalKm).
- Expenses entram só no totalCost (não no totalKm).
- Precisão Decimal (scale 4 no per-km).

### `test/features/reports/trend_analyzer_test.dart`

- Janela vazia → hasEnoughData=false, direction=stable.
- Consumo melhora (sobe) → direction=up, deltaPercent positivo.
- Consumo piora (cai) → direction=down, deltaPercent negativo.
- Variação ≤ stableThreshold → direction=stable.
- `analyzeSpendingTrend`: gasto sobe → direction=up; cai → down.
- Datas fora da janela são ignoradas.

## Critérios de aceite
- [ ] Todos testes verdes (679+ + ~15 novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Cards visíveis no detalhe do veículo quando há dados

## Não-objetivos
- Comparativo entre veículos (futuro).
- Push proativo quando tendência piora (Sprint 6.U).
- Predição (Sprint 6.G já faz via Haiku).

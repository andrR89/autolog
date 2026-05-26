# Sprint 6.V — Recap mensal/semanal estilo Spotify Wrapped

> Onda 2, sprint 10/10. **Último** sprint da Onda 2.
> UI nova grande. Leitura de dados existentes (sem schema novo).

## Decisões pragmáticas
- **Sem schema**, **sem IA**, **sem edge function**, **sem migration**. Tudo lê do local.
- 2 modos: **semanal** (últimos 7 dias) e **mensal** (mês corrente).
- Cards swipáveis em pleno tela, fundo brand-color, números grandes, animação simples.
- Compartilhar via `share_plus` (verificar se já tem; senão pular share por ora).
- Trigger: botão "Ver Recap" na home/reports. Push automático (último dia do mês/semana) fica como TODO.

## Função pura

`lib/features/recap/recap_data.dart`:

```dart
enum RecapPeriod { week, month }

class RecapData {
  const RecapData({
    required this.period,
    required this.start,
    required this.end,
    required this.totalSpent,
    required this.fuelSpent,
    required this.expensesSpent,
    required this.kmDriven,
    required this.fuelEntriesCount,
    required this.expensesCount,
    required this.avgConsumptionKmL,    // null se < 2 fuels
    required this.cheapestPricePerLiter,
    required this.mostExpensivePricePerLiter,
    required this.favoriteStation,      // String? ex: "Shell • X"
    required this.topExpenseCategory,   // String? ex: "Manutenção"
  });
  // ... fields
}

RecapData computeRecap({
  required RecapPeriod period,
  required DateTime now,
  required List<FuelEntry> fuels,
  required List<Expense> expenses,
});
```

## UI

`lib/features/recap/recap_screen.dart`:

PageView vertical (1 card por página) com 5-7 slides:
1. **Hero** — "Seu mês em movimento" + emoji + período.
2. **Total gasto** — número grande R$ X.XXX, sub "em N abastecimentos + M despesas".
3. **Km rodados** — "Você rodou X km! 🚗", equivalente "≈ Y SP-RJ".
4. **Consumo médio** — "X,X km/L" (se aplicável).
5. **Preço gasolina** — "Mais barato: R$ X em {posto}. Mais caro: R$ Y."
6. **Posto preferido** — "Você ama o {favoriteStation}".
7. **Categoria top** — "Você gastou mais com {topExpenseCategory}".

Cada card: full-screen, fundo gradient brand, números enormes (AppTypography.metric), animação fade-in on appear.

Bottom: indicador de páginas + "Próximo" (auto-avança em 4s).

### Compartilhamento
Se `share_plus` no pubspec, botão flutuante "Compartilhar" → renderiza o card current em image (use `RepaintBoundary` + `toImage`) e usa `Share.shareXFiles`.

Se não, pular share (TODO).

### Entry point
`lib/features/reports/reports_screen.dart` — botão grande "✨ Ver meu Recap" no topo (gradient brand, chama atenção).

### Rota
`/recap?period=week|month` → `RecapScreen(period)`.

## Testes RED

### `test/features/recap/recap_data_test.dart`

- Listas vazias → tudo zerado.
- Período semanal vs mensal cobre range correto.
- totalSpent = fuelSpent + expensesSpent.
- avgConsumption: < 2 fuels → null.
- avgConsumption: max-min/litros.
- favoriteStation: usa `aggregateByStation` ou `analyzeFavoriteStation` (reusar).
- topExpenseCategory: contagem por categoria, retorna nome PT-BR.
- cheapest/mostExpensivePricePerLiter: min/max das fuel entries no range.
- Datas fora do range ignoradas.

## Critérios de aceite
- [ ] Todos testes verdes (741+ + ~10 novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Recap navegável com mock data
- [ ] Entry point visível em reports

## Não-objetivos
- Push automático no fim do mês (futuro).
- Compartilhamento se package não estiver — anota TODO.
- Comparativo com meses anteriores (futuro).
- Animações complexas (Lottie etc — futuro).

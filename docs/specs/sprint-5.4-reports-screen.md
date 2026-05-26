# Spec — Sprint 5.4: Tela de relatórios com gráficos

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa; André homologa visualmente.
> Última tarefa do Sprint 5. Depende de 5.1/5.2/5.3 (3 funções puras) + `fl_chart` (já no pubspec).

## Escopo
- Tela `ReportsScreen` em `/vehicles/:vehicleId/reports` com **3 gráficos** (linhas):
  1. **Gasto/mês** (R$): combustível + despesas.
  2. **Consumo médio/mês** (km/l): ponderado por km.
  3. **Preço/litro/mês** (R$): ponderado por litros.
- Cada seção é um Card com título PT-BR + LineChart do fl_chart.
- Entry-point: novo `IconButton(Icons.bar_chart, tooltip: 'Relatórios')` no AppBar do `FuelHistoryScreen`, ANTES do pencil (ordem final: 🔔 💲 📊 ✏️).
- Providers combinam streams de fuel + expenses e devolvem `AsyncValue` propagando loading/error.

Fora de escopo: filtros por período; agregados anuais; export.

## Decisões técnicas

### 1. Providers de agregação
`lib/features/reports/reports_providers.dart` (novo):
- `monthlySpendingProvider = Provider.family<AsyncValue<List<MonthlyTotal>>, String>` — combina fuelEntries + expenses (via providers existentes); chama `computeMonthlySpending`.
- `monthlyConsumptionProvider = Provider.family<AsyncValue<List<MonthlyConsumption>>, String>` — só fuelEntries; ordena ASC por data antes de chamar `computeMonthlyConsumption`.
- `monthlyPriceProvider = Provider.family<AsyncValue<List<MonthlyPrice>>, String>` — só fuelEntries; `computeMonthlyPrice`.

Cada um faz:
```dart
final fuel = ref.watch(fuelEntriesByVehicleProvider(vehicleId));
final expenses = ref.watch(expensesByVehicleProvider(vehicleId)); // só onde aplicável
if (fuel.isLoading) return const AsyncValue.loading();
if (fuel.hasError) return AsyncValue.error(fuel.error!, fuel.stackTrace!);
// ...mesmo pra expenses se usado...
return AsyncValue.data(computeXxx(...));
```

> Note: `fuelEntriesByVehicleProvider` retorna lista DESC (per repo). Pra consumption/price helpers que esperam ASC, fazer `.reversed.toList()` antes de chamar.

### 2. Formatter PT-BR de label de mês (testável)
`lib/features/reports/reports_helpers.dart` (novo):
```dart
/// "mai/2026", "jun/2026" — 3 letras minúsculas do mês PT-BR + barra + ano.
String formatMonthLabel(DateTime month);
```
Usa `intl` `DateFormat('MMM/yyyy', 'pt_BR')` e força minúsculas (DateFormat retorna "Mai/2026"; queremos "mai/2026"). Trim de pontos finais ("mai." → "mai" pra alguns locales).

### 3. Tela `ReportsScreen`
`lib/features/reports/reports_screen.dart`:
- `ConsumerWidget`. Constructor `({required Vehicle vehicle})`.
- AppBar: title "Relatórios — ${vehicle.nickname}" + BackButton (gerado pelo go_router push).
- Body: `SingleChildScrollView` com 3 `Card`s consecutivos:
  - Card 1 "Gasto por mês": label PT-BR ("Combustível + despesas"); LineChart com pontos `(monthIndex, total.toDouble())` — Y formatado em R$. Eixo X com `formatMonthLabel`.
  - Card 2 "Consumo médio por mês": LineChart com pontos `(monthIndex, kmPerLiter.toDouble())`; subtítulo "km/L (ponderado por km rodados)".
  - Card 3 "Preço por litro": LineChart com pontos `(monthIndex, pricePerLiter.toDouble())`; subtítulo "R$ (ponderado por litros)".
- Empty state por card (quando dados vazios): texto cinza PT-BR "Sem dados suficientes ainda."
- Loading/erro consistentes por card (cada um observa seu próprio provider).

> **Decimal→double boundary**: o cálculo das agregações é Decimal; a conversão pra `double` acontece SÓ no momento de criar `FlSpot` (display-only, mesma boundary das outras formatadas).

### 4. Entry-point no `FuelHistoryScreen`
Adicionar `IconButton(icon: const Icon(Icons.bar_chart), tooltip: 'Relatórios', onPressed: () => context.push('/vehicles/${vehicle.id}/reports'))` ENTRE o ícone de despesas (`attach_money`) e o de editar (`edit`). Nova ordem final: 🔔 → 💲 → 📊 → ✏️.

### 5. Roteamento
`lib/core/router.dart`: nova rota `/vehicles/:vehicleId/reports` com loader (`_VehicleReportsLoader`) seguindo o padrão dos outros — carrega Vehicle, null → redirect `/vehicles`.

## Critérios de aceite

**`test/features/reports/reports_helpers_test.dart`** (formatter testável):

1. `formatMonthLabel(DateTime.utc(2026, 5, 1))` → "mai/2026".
2. `formatMonthLabel(DateTime.utc(2026, 1, 1))` → "jan/2026".
3. `formatMonthLabel(DateTime.utc(2026, 12, 1))` → "dez/2026".
4. Sempre lowercase + sem ponto final.

**Deliverables (revisão Haiku + homologação visual):**
5. AppBar do detalhe tem 4 ícones na ordem 🔔 💲 📊 ✏️.
6. Tela de relatórios abre com 3 gráficos; estado vazio bonito quando não há dados; loading enquanto carrega.
7. Eixos X usam labels PT-BR; Y formatado adequado por tipo (R$ ou km/L).
8. Charts respondem ao adicionar/remover fuel/expense (providers são reativos via stream).

## Definition of Done
- 4 testes do helper verdes; suíte completa verde (~279); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Sem `.toDouble()` no path de cálculo (só na conversão pra FlSpot na borda de display).
- PT-BR em tudo.

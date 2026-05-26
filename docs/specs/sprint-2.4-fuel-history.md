# Spec — Sprint 2.4: Lista de abastecimentos + exibição de consumo

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 2.1 (`FuelEntryRepository`), 2.2 (`computeConsumption` + `isOdometerMonotonic`), 2.3 (form + saver).
> **Última tarefa do Sprint 2** — fecha o ciclo que homologa o coração do app.

## Escopo
- Nova tela `FuelHistoryScreen` em `/vehicles/:vehicleId` — lista reativa dos abastecimentos do veículo, com consumo (km/l) e custo/km exibidos por entry quando aplicável, ou "—" quando sem baseline.
- FAB "+" pra abrir o form de novo abastecimento (entry-point que faltava da 2.3).
- Tap em entry → editar; trash com confirm → soft delete (via saver).
- **Roteamento**: tap em um veículo na lista geral (`/vehicles`) passa a abrir `/vehicles/:id` (detalhe/histórico) em vez de `/vehicles/:id/edit`. Edit acessível pelo pencil na AppBar do detalhe.
- Helpers PT-BR puros e testáveis pra formatar consumo, custo/km e moeda BR.

Fora de escopo: relatórios agregados (Sprint 5), sync explícito dos fuel_entries no UI (vai junto se necessário; o sync engine de vehicles do 1.2 já cobre o padrão), scan IA (Sprint 3).

## Decisões técnicas

### 1. Helper de cálculo orientado pra display
`lib/features/fuel/fuel_history_helpers.dart`:
```dart
/// Adapta o output do computeConsumption (que espera ordem ASC por data)
/// para a ordem DESC usada na lista (mais recente primeiro), mantendo o
/// mesmo ConsumptionRow por entry.
List<ConsumptionRow> computeForDisplay(List<FuelEntry> descByDate);
```
Implementação: reversa → `computeConsumption` → reversa de volta. Pura.

### 2. Formatters PT-BR (testáveis)
No mesmo arquivo:
- `String formatKmPerLiter(Decimal? value)`: null → "—"; senão **1 casa decimal** com vírgula + " km/l" (ex.: "12,5 km/l").
- `String formatCostPerKm(Decimal? value)`: null → "—"; senão "R$ X,YY/km" (2 casas com vírgula).
- `String formatCurrencyBr(Decimal value)`: "R$ X.XXX,YY" — usar `intl` `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ', decimalDigits: 2)`. O `Decimal` vira `double` SÓ pra entrar no `NumberFormat` (display-only — nunca volta pro modelo, mesma boundary que 2.3 já tem).
- `String formatLitersBr(Decimal value)`: "X,YYY L" com até 3 casas decimais (truncar trailing zeros opcional; mais simples: 3 fixas).
- `String formatDateBr(DateTime date)`: "dd/MM/yyyy" (use `intl` `DateFormat`).

### 3. Tela `FuelHistoryScreen`
`lib/features/fuel/fuel_history_screen.dart` — `ConsumerWidget`:
- AppBar: título = `vehicle.nickname`; actions = ícone editar (`/vehicles/:id/edit`).
- Body: `AsyncValue` de `repo.watchByVehicle(vehicleId)` (provider novo `fuelEntriesByVehicleProvider(vehicleId)` ou inline `ref.watch`). Loading → spinner. Erro → texto + retry. Vazio → placeholder "Nenhum abastecimento registrado ainda. Toque em **+** pra começar.".
- Lista: cada item em `Card` com:
  - **Header**: data formatada (`formatDateBr`) à esquerda; "km/l" do consumo grande à direita (cor primária quando presente).
  - **Sublinha**: `formatLitersBr(liters)` • `formatCurrencyBr(totalCost)` • `formatCostPerKm(...)` • odômetro X km.
  - **Trailing icons**: ícone de tanque (`Icons.local_gas_station` cheio vs `Icons.water_drop` parcial — escolher Material que comunique), ícone de origem (`Icons.edit` manual / `Icons.photo_camera` ai_scan / `Icons.center_focus_strong` ocr).
  - **Tap** → `context.go('/vehicles/${vehicleId}/fuel/${entry.id}/edit')`.
  - **Long press** ou ícone de lixeira no card → `AlertDialog` "Excluir este abastecimento? Pode ser recuperado depois." → confirma → `fuelEntrySaverProvider.delete(entry.id)`.
- FAB "+" → `context.go('/vehicles/${vehicleId}/fuel/new')`.

### 4. Mudança de navegação na lista de veículos
`vehicles_list_screen.dart`: o `onTap` do tile do veículo passa a navegar pra `/vehicles/${v.id}` (detalhe/histórico) em vez de `/vehicles/${v.id}/edit`. O acesso ao edit fica na AppBar do detalhe.

### 5. Roteamento
Em `lib/core/router.dart`:
- Nova rota `/vehicles/:vehicleId` → loader do `Vehicle` (mesmo padrão de `_VehicleEditLoader`); vehicle null → redirect `/vehicles`. Renderiza `FuelHistoryScreen(vehicle: ...)`.
- Rotas existentes mantidas.

### 6. PT-BR sempre.

## Critérios de aceite

**Testes em `test/features/fuel/fuel_history_helpers_test.dart`:**

`computeForDisplay`:
1. Lista vazia → vazia.
2. Único entry → 1 row com `kmPerLiter == null`.
3. Dois cheios em DESC `[E2 mais novo, E1 mais antigo]` → E2 (na posição 0) recebe `kmPerLiter` calculado da janela E1→E2; E1 (posição 1) recebe `null`. Ordem preservada (DESC).
4. Cheio + parcial + cheio em DESC `[E3, E2 parcial, E1]` → E3 (pos 0) recebe `kmPerLiter` calculado da janela E2+E3; demais `null`. Ordem preservada.

`formatKmPerLiter`:
5. `null` → "—".
6. `Decimal.parse('12.5')` → "12,5 km/l".
7. `Decimal.parse('11.1111')` → "11,1 km/l" (1 casa, arredondamento).
8. `Decimal.parse('10')` → "10,0 km/l".

`formatCostPerKm`:
9. `null` → "—".
10. `Decimal.parse('0.5500')` → "R$ 0,55/km".
11. `Decimal.parse('1.2345')` → "R$ 1,23/km" (2 casas).

`formatCurrencyBr`:
12. `Decimal.parse('250.626981')` → "R$ 250,63".
13. `Decimal.parse('1234.56')` → "R$ 1.234,56" (com separador de milhar).
14. `Decimal.parse('0')` → "R$ 0,00".

`formatLitersBr`:
15. `Decimal.parse('43.219')` → "43,219 L".
16. `Decimal.parse('40')` → "40,000 L".

`formatDateBr`:
17. `DateTime.utc(2026, 5, 23)` → "23/05/2026".

**Deliverables (Haiku + homologação):**
18. Lista renderiza, mostra consumo onde aplicável, "—" onde não há baseline.
19. FAB abre form; salvar volta pra essa tela atualizada.
20. Editar/excluir funcionam.
21. Tap em veículo na lista geral abre o detalhe (não mais o edit direto).

## Definition of Done
- Testes verdes (~17 helpers); suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Sem hard delete na UI.
- Helpers PT-BR são puros e não tocam Decimal no path de cálculo (só no boundary de display).

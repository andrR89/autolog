# Spec — Sprint 2.2: Service de cálculo de consumo (regra de ouro #2)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Fonte: `docs/PRD.md §7` (regra de tanque cheio) + Regras de Ouro #2 do `CLAUDE.md`.
> **Esta é a lógica mais sensível do app.** Bug aqui = número errado de consumo na cara do usuário, o que mata a credibilidade.

## Escopo
Service puro que recebe uma lista de `FuelEntry` (do mesmo veículo) ordenada por data ascendente e retorna, para cada abastecimento, o consumo (km/l) e o custo por km **quando aplicável** — ou `null` quando não há baseline suficiente. Inclui helper de validação de odômetro monotônico (a UI vai usar pra **avisar, não bloquear**).

Fora de escopo: agregados por período (médias mensais — vão pros relatórios em Sprint 5), UI, persistência.

## A regra (de `PRD §7`, literal)
- Cada registro tem flag `full_tank` (bool).
- km/l = `(km_atual − km_do_último_tanque_cheio) / soma_de_litros_desde_o_último_tanque_cheio_(inclusive_o_atual)`.
- Parciais entre dois cheios → litros somam.
- Primeiro abastecimento nunca gera consumo.
- Exibir consumo como `null` (UI mostra "—") quando não há baseline suficiente — **nunca um número errado**.

### Reformulação operacional (o que o calculator implementa)
Iterando pela lista em ordem cronológica e mantendo "último cheio confirmado":
- Antes de existir um cheio anterior, **toda entry produz `null`**.
- Quando se encontra uma entry com `full_tank == true` e existe um `full_tank == true` anterior:
  - Janela = entries do `full_tank` anterior (exclusivo) até a entry atual (inclusivo).
  - Litros = soma de `liters` da janela (parciais + cheio atual).
  - Km = `entry.odometer - lastFullTank.odometer`.
  - **Custo da janela** = soma de `totalCost` da janela.
  - `kmPerLiter = km / litros` (Decimal, escala 4, half-even).
  - `costPerKm = custoDaJanela / km` (Decimal, escala 4, half-even).
  - Entry atual recebe esses valores; entries parciais dentro da janela ficam com `null` (não fecham ciclo).
- Quando a entry é `full_tank == false` ou não há baseline → `null`.

Casos de borda:
- **km <= 0** (odômetro não cresceu desde o último cheio): retorna `null` (dados inconsistentes — UI mostra "—" pra essa entry). O calculator NÃO lança exceção.
- **litros <= 0** (impossível tecnicamente, mas defensivo): `null`.
- Empty list → empty result.

## Decisões técnicas

### 1. Service puro
`lib/domain/services/consumption_calculator.dart` — função puríssima sem state:
```dart
class ConsumptionRow {
  final FuelEntry entry;
  /// km/l da janela que fecha NESTA entry (ou null se não fecha ciclo).
  final Decimal? kmPerLiter;
  /// custo/km da mesma janela (ou null).
  final Decimal? costPerKm;
  const ConsumptionRow({required this.entry, this.kmPerLiter, this.costPerKm});
}

/// Recebe entries do mesmo veículo, ordenados por data ascendente.
/// Retorna uma lista de mesma length, na mesma ordem.
List<ConsumptionRow> computeConsumption(List<FuelEntry> entriesAsc);
```

### 2. Divisão Decimal — escala e arredondamento
Use `(numerador / denominador).toDecimal(scaleOnInfinitePrecision: 4).round(scale: 4)`. 4 casas é mais do que a UI precisa (UI formata pra 1-2 casas no display); preserva precisão pra agregações futuras.

Sutileza: `toDecimal(scaleOnInfinitePrecision: 4)` só limita escala para divisões com decimal infinito (ex.: 1/3). Para divisões finitas (ex.: 130.49/250 = 0.52196), retorna a precisão exata completa. O `.round(scale: 4)` adicional uniformiza o resultado em 4 casas para ambos os casos. O `.round` do pacote Decimal usa **half-up** (convenção contábil padrão); para dados típicos de combustível a diferença para half-even é desprezível (exige `.xxxx5` exato no 5º decimal, raro com inputs reais).

### 3. Validador monotônico de odômetro
No mesmo arquivo, helper puro:
```dart
/// Retorna true se [candidate] é monotonicamente crescente em relação ao
/// [previous] (>=). Null em previous significa "primeiro registro" → sempre true.
/// A UI usa para AVISAR (não bloquear).
bool isOdometerMonotonic({required int candidate, required int? previous});
```
Regras: `previous == null` → true; `candidate >= previous` → true; senão → false.

### 4. Nenhum `double` em nenhum ponto do cálculo
`km` é `int`; `liters`/`totalCost` são `Decimal`. Divisão usa Decimal/Rational. Em **NENHUM** momento aparece `double` no path de dinheiro/volume/consumo.

## Critérios de aceite (= testes em `test/domain/services/consumption_calculator_test.dart`)

Construa entries com helper local (`_entry(...)`) com defaults razoáveis. Todos os testes devem confirmar PT-BR-friendliness sem precisar de I/O.

1. **Lista vazia** → lista vazia.
2. **Único registro (cheio ou parcial)** → `kmPerLiter == null` e `costPerKm == null`.
3. **Dois cheios consecutivos**:
   - E1: cheio, odômetro 10000, 40L, R$ 200.
   - E2: cheio, odômetro 10500 (=+500 km), 40L (consumida na janela), R$ 220.
   - E1 → null. E2 → `kmPerLiter == 500 / 40 = 12.5`. `costPerKm == 220 / 500 = 0.4400` (4 casas).
4. **Cheio → parcial → cheio** (PRD §7 — soma os litros):
   - E1: cheio, odômetro 10000.
   - E2: parcial, odômetro 10200, 20L, R$ 110.
   - E3: cheio, odômetro 10500 (+500 km da E1), 30L, R$ 165. Janela = E2+E3, litros = 50, custo = 275.
   - E1 → null. E2 → null (não fecha). E3 → `kmPerLiter == 500/50 = 10`; `costPerKm == 275/500 = 0.5500`.
5. **Múltiplos parciais entre dois cheios**: E1 cheio → P1 parcial → P2 parcial → E4 cheio. E4 recebe a soma dos litros e custos dos 3 (P1+P2+E4). Os parciais → `null`.
6. **Três cheios em sequência** (cada cheio calcula só com base no cheio anterior):
   - E1 cheio @10000, E2 cheio @10400 com 40L → 10.0; E3 cheio @10800 com 50L → 8.0. (Não acumula janela de E1 a E3.)
7. **Parcial primeiro, depois cheio, depois cheio**:
   - P1 parcial @10000 (não cheio → não vira baseline). E2 cheio @10300, 30L. E3 cheio @10700, 40L.
   - P1 → null. E2 → null (não havia cheio anterior). E3 → janela E2→E3, km=400, litros=40 → 10.0.
8. **Último cheio é o primeiro do veículo**: E1 cheio único → null.
9. **Odômetro <= último cheio** (caso defensivo — dado bagunçado): E1 cheio @10000, E2 cheio @9500 (regrediu). E2 → `null` (NÃO lança exceção). Não polui números.
10. **Litros zero defensivo**: E1 cheio @10000, E2 cheio @10500 com 0L (impossível em prática). E2 → null (divisão por zero protegida).
11. **Precisão decimal sagrada — Decimal exato sem double**:
    - E1 cheio @10000, 30L, R$ 174.99.
    - E2 cheio @10250 (+250 km), 22.5L, R$ 130.49.
    - `kmPerLiter == Decimal.parse('250') / Decimal.parse('22.5')` com escala 4 = `Decimal.parse('11.1111')` (half-even).
    - `costPerKm == Decimal.parse('130.49') / Decimal.parse('250')` com escala 4 = `Decimal.parse('0.5220')`.
    - Garantir `kmPerLiter` e `costPerKm` são `Decimal` exatos esperados.
12. **Ordem preservada**: o resultado mantém a ordem da entrada.
13. **Monotonic helper**:
    - `previous = null` → true.
    - `previous=100, candidate=100` → true (sem movimento ainda conta como ok pro aviso).
    - `previous=100, candidate=101` → true.
    - `previous=100, candidate=99` → false.

## Definition of Done
- 13 cenários de teste verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- **Zero ocorrência de `double`/`.toDouble()`/`as num`** no arquivo do calculator (Haiku confirma com grep).
- Nenhuma exceção lançada — entradas malformadas viram `null`.
- Função pura: sem deps externas (banco, network, providers).

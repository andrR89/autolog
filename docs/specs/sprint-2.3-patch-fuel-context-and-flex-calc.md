# Spec — Patch 2.3: combustível contextual + cálculo flexível 2→1

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> **Classificação: C (direção)** — duas mudanças de produto solicitadas em homologação.

## Mudança 1 — Opções de combustível contextuais ao veículo
Atualmente o form mostra as 5 opções (gasolina/etanol/diesel/flex/gnv) sempre. Mudança: filtrar pelo tipo do veículo.

| Veículo | Opções no form de abastecimento |
|---|---|
| gasolina | [gasolina] |
| etanol | [etanol] |
| diesel | [diesel] |
| flex | [flex, gasolina, etanol] |
| gnv | [gnv] |

Se houver só 1 opção, o `FuelTypeSegmented` ainda aparece (visual consistente) mas com 1 segmento — comportamento natural do widget.

**Caso especial GNV**: GNV é cobrado em m³, não litros. Pragmaticamente, mantemos o mesmo campo `liters` no modelo (golden rule: não mexer no modelo de dados) mas o **label** vira "Volume (m³)" quando o tipo do abastecimento é GNV. Cálculo idêntico (m³ × R$/m³ = total). Visual: subtítulo discreto explicando "GNV é cobrado em m³".

### Função pura
`lib/features/fuel/widgets/fuel_type_segmented.dart` (ou novo `fuel_form_validators.dart`):
```dart
/// Retorna a lista de FuelType permitidos pra abastecer um veículo dessa categoria.
List<FuelType> availableFuelTypesFor(FuelType vehicleType) {
  switch (vehicleType) {
    case FuelType.flex:    return [FuelType.flex, FuelType.gasolina, FuelType.etanol];
    case FuelType.gasolina: return [FuelType.gasolina];
    case FuelType.etanol:   return [FuelType.etanol];
    case FuelType.diesel:   return [FuelType.diesel];
    case FuelType.gnv:      return [FuelType.gnv];
  }
}
```

## Mudança 2 — Cálculo flexível: qualquer 2 → terceira automática
Hoje: litros × preço/L = total (total read-only/auto). Pedido: qualquer 2 das 3 preenche a terceira.

### Função pura
`lib/features/fuel/fuel_form_validators.dart` ganha:
```dart
class FuelTriplet {
  const FuelTriplet({this.liters, this.pricePerLiter, this.totalCost});
  final Decimal? liters;
  final Decimal? pricePerLiter;
  final Decimal? totalCost;
}

/// Recebe 0-3 valores e devolve uma triplet com o campo faltante calculado
/// (quando 2 dos 3 estão presentes). Se 3 estão presentes ou < 2 estão, devolve
/// inalterado. Divisão por zero → não calcula (não crash).
///
/// [exclude] indica qual campo NÃO deve ser sobrescrito (o "user-touched" mais
/// recente). Quando os 3 estão presentes, o campo a ser recalculado é o que
/// NÃO está em `exclude` E não foi o último digitado.
FuelTriplet computeMissingTriplet(FuelTriplet input, {FuelField? exclude});

enum FuelField { liters, pricePerLiter, totalCost }
```

Algoritmo:
- Conta quantos campos estão non-null: `n`.
- Se `n < 2`: retorna unchanged (nada a calcular).
- Se `n == 3`: retorna unchanged (já tem tudo; user manual override).
- Se `n == 2`:
  - Identifica o campo faltante.
  - Calcula: `liters` faltando → `totalCost / pricePerLiter`; `pricePerLiter` faltando → `totalCost / liters`; `totalCost` faltando → `liters * pricePerLiter`.
  - Defensivo: se denominador (`pricePerLiter` ou `liters`) for `Decimal.zero`, retorna unchanged.
  - Resultado da divisão: `.toDecimal(scaleOnInfinitePrecision: 4).round(scale: 4)` (consistente com 2.2/5.x).
  - Multiplicação: exata, sem arredondamento.

### Integração no form
- Form acompanha `lastTwoTouched: List<FuelField>` (queue de tamanho 2; o mais recente vai no fim).
- Quando user digita em um campo, atualiza a queue e chama `computeMissingTriplet` com os 2 valores em `lastTwoTouched` (os outros são "pra calcular").
- Field calculado mostra um pequeno badge "auto" cinza-discreto (já existe pra `totalCost` no design atual — generalizar pros 3).
- Se user limpa um campo: remove da queue de "touched"; a 3ª fica vazia até o user preencher outra.
- Validação no submit: pelo menos 2 dos 3 devem estar preenchidos E parseáveis E positivos.

## Critérios de aceite

**`test/features/fuel/fuel_form_calc_test.dart`** (novo):

`availableFuelTypesFor`:
1. `gasolina` → `[gasolina]`.
2. `etanol` → `[etanol]`.
3. `diesel` → `[diesel]`.
4. `flex` → `[flex, gasolina, etanol]`.
5. `gnv` → `[gnv]`.

`computeMissingTriplet`:
6. **2 presentes (liters+price)**, sem total → total = liters × price exato.
7. **2 presentes (liters+total)**, sem price → price = total / liters com escala 4.
8. **2 presentes (total+price)**, sem liters → liters = total / price com escala 4.
9. **3 presentes** → retorna unchanged.
10. **0 ou 1 presente** → retorna unchanged.
11. **Decimal precision**: liters=43.219, price=5.799 → total=250.626981 (exato).
12. **Defensivo**: liters=0 + total=200 → não calcula price (divisão por zero); retorna unchanged.
13. **Defensivo**: price=0 + total=200 → não calcula liters; retorna unchanged.

**Deliverables (revisão Haiku + homologação visual):**
14. Form mostra opções de combustível filtradas pelo veículo.
15. Para GNV: label do campo de volume vira "Volume (m³)" + sub explicativo.
16. User pode preencher qualquer 2 dos 3 campos; o terceiro auto-calcula com badge "auto".
17. Editar o campo "auto" reinverte: o user-touched anterior vira o "auto".

## Definition of Done
- 13 testes verdes (5 fuel-type + 8 triplet); suíte completa verde (~292); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Sem `double` no cálculo (Decimal só).
- Mantém os 4 testes existentes do fuel_entry_saver.

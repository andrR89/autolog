# Sprint 6.DD — CO2 calculado

> Função pura + card no detalhe do veículo. Sem schema, sem IA, sem migration.

## Decisões
- Fatores de emissão hardcoded em `kg CO2 / litro` por tipo:
  - Gasolina: 2.31 kg/L (fonte: IPCC 2006, tier 1)
  - Etanol: 1.51 kg/L (combustão; emissão "fóssil" considerada zero pelo ciclo
    da cana, mas mostramos a emissão real direta pra coerência)
  - Diesel: 2.68 kg/L
  - GNV: 1.93 kg/m³ (tratamos como L pra simplificar — usuário sabe)
  - Flex: peso médio (depende do mix de abastecimentos)
- Card no detail vehicle: total CO2 ano corrente + equivalência simples
  ("≈ X árvores absorvendo por 1 ano" usando 22 kg/ano/árvore).

## Mudanças

### Função pura
`lib/features/reports/co2_calculator.dart`:
```dart
class Co2Result {
  final Decimal totalKg;
  final int treesEquivalentYear; // floor(totalKg / 22)
}

Decimal kgCo2PerLiter(FuelType type);

Co2Result computeCo2({required List<FuelEntry> entries});
```

### Widget
`lib/features/reports/widgets/co2_card.dart`:
- ConsumerWidget recebe `Vehicle`. Lê fuels.
- Filtra ano corrente.
- Renderiza card discreto: "🌱 X kg CO₂ em 2026" + sub "≈ Y árvores/ano".
- Cor: AppColors.successSoft.

### Integração
`lib/features/fuel/fuel_history_screen.dart`:
- Adicionar `Co2Card(vehicle: vehicle)` após o TrendCard.

## Testes
- `test/features/reports/co2_calculator_test.dart`: vazio→zero;
  1 entry gasolina→peso correto; mix flex→soma; equivalência árvores; precision Decimal.

## Critérios
- Suite verde (839 + ~6 novos)
- analyze 0, iOS build OK

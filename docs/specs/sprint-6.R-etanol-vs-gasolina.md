# Sprint 6.R — Calculadora etanol × gasolina contextual

> Onda 2, sprint 6/10. Pura, pequena.
> Diferencial: usa o CONSUMO REAL do veículo (do histórico), não o 70% genérico.

## Decisões pragmáticas
- Função pura sobre `List<FuelEntry>` do veículo (filtra por `fuelType` pra calcular consumo separado de etanol/gasolina).
- Pré-preenche com últimos preços do histórico.
- Só renderiza em veículos `FuelType.flex` (outros tipos não fazem sentido).
- Sem schema novo, sem IA, sem migration.

## Função pura

`lib/features/reports/fuel_economy_comparator.dart`

```dart
class FuelEconomy {
  const FuelEconomy({
    required this.kmPerLiter,
    required this.basedOnEntries,
  });
  final Decimal kmPerLiter;
  final int basedOnEntries;
}

class FuelComparison {
  const FuelComparison({
    required this.gasolinaCostPerKm,
    required this.etanolCostPerKm,
    required this.bestChoice,        // FuelType.gasolina, FuelType.etanol
    required this.savingsPercent,    // Quanto economiza usando bestChoice
  });
  final Decimal gasolinaCostPerKm;
  final Decimal etanolCostPerKm;
  final FuelType bestChoice;
  final Decimal savingsPercent;
}

/// Calcula consumo médio por tipo de combustível a partir do histórico.
/// Usa abordagem cheio-a-cheio: pra cada par consecutivo (mesmo fuel type,
/// ambos cheios), consumo = (od2 - od1) / liters2.
/// Se não há ≥ 2 cheios pro fuel type → retorna null.
FuelEconomy? computeFuelEconomy(List<FuelEntry> entries, FuelType type);

/// Fallback genérico se não há histórico do tipo.
/// Carros flex modernos: gasolina ~12 km/L, etanol ~8.4 km/L (relação 70%).
const _genericGasolinaKmL = 12.0;
const _genericEtanolKmL = 8.4;

/// Compara custo por km dos 2 combustíveis. Usa histórico se disponível,
/// senão fallback genérico. Aplica consumo real do user quando possível.
FuelComparison compareFuels({
  required Decimal gasolinaPricePerLiter,
  required Decimal etanolPricePerLiter,
  required List<FuelEntry> historicalEntries, // pode ser vazio
});

/// Extrai o último preço por litro registrado pro tipo, ou null.
Decimal? lastPriceFor(List<FuelEntry> entries, FuelType type);
```

## UI

### `lib/features/reports/fuel_economy_screen.dart`

Tela acionada via botão "Etanol × Gasolina" no detalhe de veículos flex.

Layout:
- AppBar "Etanol × Gasolina".
- Card "Combustíveis" (top):
  - 2 TextField numéricos: preço gasolina, preço etanol (pré-preenchidos com `lastPriceFor` se disponível).
  - Helper text: "Pré-preenchido com o último abastecimento do tipo" (se aplicável).
- Card "Seu consumo" (meio):
  - 2 linhas: "Gasolina: X,X km/L (Y abastecimentos)" / "Etanol: X,X km/L (Z abastecimentos)".
  - Se sem dados pro tipo, mostra: "Sem dados — usando estimativa genérica (12,0 km/L)" com badge cinza "estimativa".
- Card "Recomendação" (bottom):
  - Grande: ícone do tipo vencedor + "Etanol compensa" / "Gasolina compensa".
  - Linha: "R$ X,XX/km vs R$ Y,YY/km".
  - Linha: "Economia de Z,Z% por km rodado".
- Atualizando preços em tempo real, recompura.

### Entry point
- Card no detalhe do veículo (`fuel_history_screen`) só pra `vehicle.fuelType == FuelType.flex`: "Etanol × Gasolina" com ícone `Icons.calculate_outlined`. Tap navega pra `/vehicles/:id/fuel-economy`.

### Rota
`/vehicles/:vehicleId/fuel-economy` → `FuelEconomyScreen(vehicle)`.

## Testes RED

### `test/features/reports/fuel_economy_comparator_test.dart`

- `computeFuelEconomy`:
  - lista vazia → null
  - 1 abastecimento → null (precisa baseline)
  - 2 cheios do tipo → calcula km/L corretamente
  - cheios alternando tipos (Flex) → pega só os do tipo solicitado
  - 1 parcial entre 2 cheios → ignora parcial, usa só cheios consecutivos do tipo
- `lastPriceFor`:
  - sem entries → null
  - última entry do tipo → preço dela
- `compareFuels`:
  - sem histórico → usa genérico (gasolina 12, etanol 8.4)
  - com histórico de ambos → usa real
  - etanol mais barato em R$/km → bestChoice = etanol
  - gasolina mais barata em R$/km → bestChoice = gasolina
  - savingsPercent calculado corretamente

## Critérios de aceite
- [ ] Todos testes verdes (693+ + ~12 novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Tela aparece SÓ pra veículos flex
- [ ] Pré-preenchimento de preços funciona

## Não-objetivos
- Comparativo com GNV (fica pós-MVP).
- Considerar custo de viagem (ida e volta ao posto) — fora de escopo.
- Notificação proativa "abasteça com etanol hoje" (6.U).

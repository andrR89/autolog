# Sprint 6.S — Posto preferido + ranking

> Onda 2, sprint 7/10. Pequena, pura. Usa `aggregateByStation` (do 6.P).

## Decisões
- **Posto preferido = mais frequentado** (maior `entriesCount`). Empate → maior `lastEntryDate`.
- **Mais barato qualificado** = menor `avgPricePerLiter` entre estações com ≥ 3 visitas (evita 1 abastecimento sortudo).
- Card no detalhe do veículo + seção em "Meus postos".
- Sem schema novo, sem IA, sem migration.

## Função pura

`lib/features/fuel/favorite_station_analyzer.dart`:

```dart
class FavoriteStationInsight {
  const FavoriteStationInsight({
    required this.favorite,           // mais frequentado (sempre o top 1)
    required this.cheapestQualified,  // menor avg com >=3 visitas (pode ser null)
    required this.topByFrequency,     // top N por entriesCount
  });
  final StationStats? favorite;
  final StationStats? cheapestQualified;
  final List<StationStats> topByFrequency;
}

/// Calcula insight de "posto preferido" a partir de FuelEntries do veículo.
/// Filtra entries sem brand E sem name (não contam pra ranking).
/// [minVisitsForCheapest] — só estações com >= N visitas elegíveis pra "mais barato" (default 3).
/// [topLimit] — quantos no ranking por frequência (default 5).
FavoriteStationInsight analyzeFavoriteStation(
  List<FuelEntry> entries, {
  int minVisitsForCheapest = 3,
  int topLimit = 5,
});
```

## UI

### `lib/features/fuel/widgets/favorite_station_card.dart`

ConsumerWidget recebe `Vehicle vehicle`. Lê fuel entries do veículo.

- Card no detalhe do veículo (`fuel_history_screen`).
- Header: "SEU POSTO PREFERIDO".
- Se `favorite == null` → empty: "Adicione bandeira/nome ao registrar abastecimento pra ver seu posto preferido."
- Se `favorite != null`:
  - Grande: "{favorite.brand ?? '—'} • {favorite.name ?? 'Posto'}"
  - Sub: "{entriesCount} abastecimentos • Médio R$ {avg}/L"
  - Se `cheapestQualified` é diferente do `favorite`: badge dica "💡 Mais barato: {cheapest.brand} • R$ {cheapest.avg}/L"

### Integração
- `fuel_history_screen.dart`: adicionar `FavoriteStationCard(vehicle: vehicle)` na lista de cards top (após Cost/Trend, antes do FuelEconomyBanner).
- `my_stations_screen.dart` (6.P): adicionar seção topo "Posto preferido" antes da lista (se algum existir).

## Testes RED

### `test/features/fuel/favorite_station_analyzer_test.dart`

- Lista vazia → favorite=null, cheapest=null, top=vazia.
- 1 entry sem brand/name → favorite=null (entries sem identificação não contam).
- 3 visitas Shell + 5 visitas Petrobras → favorite=Petrobras.
- Empate de frequência → desempate por lastEntryDate maior.
- cheapest: estação A com 5 visitas e avg 5.00, B com 2 visitas e avg 4.00 → cheapest=A (B tem < 3 visitas).
- cheapest: estação A com 5 visitas avg 5.00, B com 3 visitas avg 4.50 → cheapest=B.
- cheapest pode ser igual ao favorite (mesma estação).
- topByFrequency ordenado DESC e respeita topLimit.

## Critérios de aceite
- [ ] Todos testes verdes (704+ + ~10 novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Card visível no detalhe do veículo quando há ≥ 1 estação identificada
- [ ] Seção topo na tela "Meus postos"

## Não-objetivos
- Comparativo com média da região (precisa massa crítica de users — pós-MVP).
- Recomendação "abasteça hoje no posto X" (6.U).
- Vinculação geográfica/raio (futuro com geoloc).

# Sprint 6.P — Tracker de preço por posto

> Onda 2, sprint 4/10. Refactor leve no `FuelEntry` (2 campos opcionais novos)
> + tela "Meus postos" com agregação histórica por estabelecimento.

## Decisões pragmáticas
- 2 novos campos opcionais em `FuelEntry`: `stationName` (texto livre) e `stationBrand` (bandeira).
- Agregação por `(stationBrand, stationName)` normalizados (lowercase + trim). Vai pra tela.
- Agnóstica de IA — pura agregação sobre dados que o user já registra.
- Sem cota, sem edge function.

## Mudanças

### 1. FuelEntry model — 2 campos novos
`lib/domain/models/fuel_entry.dart` — adicionar após `receiptImageUrl`:
```dart
String? stationName,
String? stationBrand,
```
Rodar build_runner.

### 2. Drift table
`lib/data/local/tables.dart` — adicionar em `FuelEntries`:
```dart
TextColumn get stationName => text().nullable()();
TextColumn get stationBrand => text().nullable()();
```

### 3. Schema v7 → v8
`lib/data/local/database.dart`:
- Bump `schemaVersion` 7 → 8.
- `onUpgrade`:
```dart
if (from < 8) {
  await m.addColumn(fuelEntries, fuelEntries.stationName);
  await m.addColumn(fuelEntries, fuelEntries.stationBrand);
}
```

### 4. Repository mapper
`lib/data/repositories/fuel_entry_repository.dart` (ou onde estiver o `_FuelEntryMapper`) — propagar 2 campos em ambos sentidos.

### 5. Sync remote source
`lib/data/sync/remote_fuel_entry_source.dart` — adicionar mapeamento dos 2 campos em upsert + fetch. Snake_case: `station_name`, `station_brand`.

### 6. Bandeiras conhecidas
`lib/features/fuel/station_brands.dart`:
```dart
/// Bandeiras de combustível brasileiras comuns (autocomplete).
const Set<String> brStationBrands = {
  'Shell', 'Petrobras', 'Ipiranga', 'Ale', 'BR Petrobras',
  'Raízen', 'Atem', 'TG', 'Sim', 'Total', 'Esso',
  'Branca', // sem bandeira / posto independente
};

/// Normaliza pra match (trim + lowercase + sem acento).
String normalizeStation(String s);
```

### 7. Form de abastecimento
`lib/features/fuel/fuel_entry_form_screen.dart` — adicionar seção "Posto (opcional)":
- **Bandeira** — campo com autocomplete usando `brStationBrands`. Aceita digitar livre.
- **Nome do posto** — TextFormField texto livre opcional. Exemplo no hint: "Posto Shell BR-101 km 87".

Salvar propaga 2 campos via `FuelEntryRepository.create`.

### 8. Agregação pura
`lib/features/fuel/station_aggregation.dart`:
```dart
class StationStats {
  const StationStats({
    required this.brand,
    required this.name,
    required this.entriesCount,
    required this.totalLiters,
    required this.totalSpent,
    required this.avgPricePerLiter,
    required this.lastEntryDate,
  });
  final String? brand;
  final String? name;
  final int entriesCount;
  final Decimal totalLiters;
  final Decimal totalSpent;
  final Decimal avgPricePerLiter; // totalSpent / totalLiters
  final DateTime lastEntryDate;
}

/// Agrupa abastecimentos por (brand normalizado, name normalizado).
/// Entradas sem ambos os campos vão pro grupo especial "Sem identificação".
/// Ordena por número de entries DESC (mais frequentes primeiro).
List<StationStats> aggregateByStation(List<FuelEntry> entries);
```

### 9. Tela "Meus postos"
`lib/features/fuel/my_stations_screen.dart`:
- AppBar "Meus postos".
- Dropdown opcional pra filtrar por veículo (ou agregado).
- Lista de cards:
  - Title: `${brand ?? '—'} • ${name ?? 'Posto'}`
  - Subtitle: "{entriesCount} abastecimentos • Médio R\$ {avg}/L"
  - Trailing: total gasto + última data
- Empty state: "Nenhum posto identificado nos abastecimentos ainda. Adicione 'Bandeira' e 'Nome do posto' ao registrar."

### 10. Entry point
Adicionar item/card "Meus postos" na tela inicial ou no detalhe do veículo. Ícone `Icons.local_gas_station_outlined`.

### 11. Migration Supabase
`supabase/migrations/0008_fuel_entry_station.sql`:
```sql
ALTER TABLE public.fuel_entries ADD COLUMN IF NOT EXISTS station_name text;
ALTER TABLE public.fuel_entries ADD COLUMN IF NOT EXISTS station_brand text;
```

## Testes RED

### `test/data/local/fuel_entry_schema_v8_test.dart` (novo)
- `schemaVersion == 8`.
- Insert + read preserva stationName/stationBrand.
- Insert sem os campos → null.
- Migration v7→v8 adiciona 2 colunas, preserva linhas existentes.

### `test/features/fuel/station_aggregation_test.dart` (novo)
- Lista vazia → vazia.
- 1 entrada com brand+name → 1 stat com counts/totais certos.
- Múltiplas entradas mesma estação → agrupa, soma litros/gasto, calcula avgPricePerLiter (totalSpent/totalLiters).
- Brand="Shell" e Brand="shell  " (case+espaço) → mesmo grupo (normaliza).
- Entradas sem brand E sem name → grupo "Sem identificação".
- Ordenação por entries DESC.
- lastEntryDate é o max das dates do grupo.
- avgPricePerLiter com precisão Decimal (scaleOnInfinitePrecision: 4).

### `test/features/fuel/station_brands_test.dart` (novo, pequeno)
- `normalizeStation("Shell ") == "shell"`.
- `normalizeStation("Petrobrás") == "petrobras"` (sem acento).
- `brStationBrands` contém pelo menos 10 entradas e inclui as principais (Shell/Petrobras/Ipiranga).

## Critérios de aceite
- [ ] Todos testes verdes (657+ existentes + ~25 novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Form de abastecimento mostra seção "Posto" opcional
- [ ] Tela "Meus postos" navegável

## Não-objetivos
- Geolocalização (sem GPS — só texto livre).
- Comparador "qual posto mais barato perto" (futuro — depende de geoloc).
- Tracker preço por dia do posto (futuro — quando tiver volume).

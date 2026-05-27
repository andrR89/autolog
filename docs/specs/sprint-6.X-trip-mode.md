# Sprint 6.X — Modo viagem

> Agrupa fuel_entries + expenses de uma road trip num conceito unificado.
> Decisão pragmática: associação por **intervalo de datas** (não modifica
> FuelEntry/Expense pra ter tripId). Filtra `WHERE date BETWEEN start AND end`.

## Decisões
- Nova tabela `trips` (vehicleId, name, startDate, endDate, notes?).
- Sem `tripId` em FuelEntry/Expense — entries pertencem a uma trip por overlap de data.
- Local-only no MVP (não entra em GlobalSync); TODO pós-MVP.
- Acesso: botão "Viagens" no detalhe do veículo (`fuel_history_screen`).

## Mudanças

### 1. Schema v13 — tabela `trips`
```dart
@DataClassName('TripRow')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text()();
  TextColumn get name => text()();          // "Floripa", "Trip pra serra"
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

Bump v12 → v13. Migration `if (from < 13) { createTable(trips); }`.

### 2. Modelo + Repository
- `lib/domain/models/trip.dart` (freezed): id, vehicleId, name, startDate, endDate, notes?, timestamps, deletedAt.
- `lib/domain/repositories/trip_repository.dart` (abstract): create, update, softDelete, listByVehicle, watchByVehicle, getById.
- `lib/data/repositories/trip_repository.dart` (Drift impl).

### 3. Função pura de agregação
`lib/features/trips/trip_stats.dart`:
```dart
class TripStats {
  final int fuelCount, expenseCount;
  final Decimal fuelSpent, expensesSpent, totalSpent;
  final int kmDriven;           // max-min odometer das fuel entries no range
  final Decimal? avgConsumptionKmL;
  final int days;               // diferença em dias entre start e end + 1
}

TripStats computeTripStats({
  required DateTime start,
  required DateTime end,
  required List<FuelEntry> fuels,
  required List<Expense> expenses,
});
```

Filtra fuels/expenses por `date >= start && date <= end`.

### 4. UI
- `lib/features/trips/trips_list_screen.dart`: AppBar "Viagens", FAB "+ Nova viagem", lista cards (nome + datas + total).
- `lib/features/trips/trip_form_screen.dart`: name, date pickers start/end, notes opcional.
- `lib/features/trips/trip_detail_screen.dart`: nome no header, stats agregadas (total, km, consumo, dias), timeline de fuel+expense.

### 5. Entry point
Detalhe do veículo (`fuel_history_screen.dart`) — adicionar card/botão "Viagens" → `/vehicles/:id/trips`.

### 6. Rotas
- `/vehicles/:vehicleId/trips` → TripsListScreen
- `/vehicles/:vehicleId/trips/new` → TripFormScreen(create)
- `/vehicles/:vehicleId/trips/:tripId` → TripDetailScreen
- `/vehicles/:vehicleId/trips/:tripId/edit` → TripFormScreen(edit)

## Testes
- `test/features/trips/trip_stats_test.dart` — função pura (vazio, agregação, range filtragem, consumo).
- `test/data/repositories/trip_repository_test.dart` — CRUD básico.
- `test/data/local/trip_schema_v13_test.dart` — schema bump + migration.

## Critérios
- Suite verde (814+ + ~15 novos)
- analyze 0, iOS build OK
- TODO anotado: sync trip pra próxima sprint

## Não-objetivos
- Sync entre devices (TODO).
- Compartilhar trip (rachar conta com passageiros) — futuro.
- Geolocalização / mapa — futuro.

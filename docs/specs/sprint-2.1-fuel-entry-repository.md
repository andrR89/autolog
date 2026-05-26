# Spec — Sprint 2.1: Repositório de `fuel_entries` (CRUD local + soft delete)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Fonte: `docs/ARCHITECTURE.md §2, §3` + Regras de Ouro (em especial #2 — precisão decimal). Depende de 0.2 (schema) + 0.3 (modelos).

## Escopo
Repositório local de `FuelEntry` sobre Drift. CRUD com soft delete, escrita offline-first (toda mutação grava local, marca `sync_status=pending`, bumpa `updated_at`), listagem por veículo (não por usuário — o isolamento de usuário se dá via os veículos dele). Espelha 1.1 (`VehicleRepository`).

Fora de escopo:
- Sync remoto de fuel_entries (será adicionado paralelo à 1.2 quando precisar de sync no homologa do Sprint 2; segue o mesmo padrão).
- Cálculo de consumo (2.2 — service separado).
- UI (2.3, 2.4).
- Validações de domínio (odômetro monotônico avisar/não bloquear — vai no form em 2.3).

## Decisões técnicas

### 1. Interface no domínio, impl na data
- `lib/domain/repositories/fuel_entry_repository.dart`: `abstract class FuelEntryRepository` (domínio).
- `lib/data/repositories/fuel_entry_repository.dart`: `DriftFuelEntryRepository` + `fuelEntryRepositoryProvider`.

### 2. API
```dart
abstract class FuelEntryRepository {
  /// Cria. Repo define createdAt/updatedAt (UTC now) e sync_status=pending.
  /// Caller fornece id (UUID) e todos os campos de negócio.
  Future<FuelEntry> create(FuelEntry entry);

  /// Atualiza. Bumpa updated_at, marca pending, preserva createdAt.
  /// Falha (StateError) se id não existir ou estiver soft-deleted.
  Future<FuelEntry> update(FuelEntry entry);

  /// Soft delete. Idempotente: não sobrescreve deleted_at original.
  Future<void> softDelete(String id);

  /// Por id. Retorna null se não existir OU se estiver soft-deleted.
  Future<FuelEntry?> getById(String id);

  /// Todos os abastecimentos NÃO deletados do veículo, ordenados por
  /// date DESC (mais recente primeiro — natural pra UX e pro cálculo de consumo).
  Future<List<FuelEntry>> listByVehicle(String vehicleId);

  /// Stream reativo da mesma lista. Emite a cada mudança.
  Stream<List<FuelEntry>> watchByVehicle(String vehicleId);
}
```

### 3. Mapper Drift ↔ domínio
`lib/data/repositories/_fuel_entry_mapper.dart` (privado): `FuelEntry _toDomain(FuelEntryRow row)` + `FuelEntriesCompanion _toCompanion(FuelEntry e)`. Preserva **todos** os campos — em especial `liters`, `pricePerLiter`, `totalCost` como `Decimal` (Drift usa `DecimalConverter` da 0.2; o mapper só passa adiante). Aplica `.toUtc()` nos `DateTime` lidos do banco (mesmo padrão do mapper de Vehicle).

### 4. Regras de mutação (não-negociáveis)
- **Toda escrita marca `sync_status=pending`** (Regra de Ouro #1: offline-first). Mesmo se o caller mandar `synced`, repo sobrescreve.
- **`updated_at` controlado pelo repo**, sempre UTC `now`. Caller não passa.
- **`createdAt`** definido no `create`, preservado em `update`.
- **Soft delete é a única forma de "excluir"**.
- **NUNCA tocar em `double`** no caminho de dinheiro/volume — o Decimal vem do domínio, vai pro Drift `DecimalConverter` (TEXT), volta como Decimal. Mapper jamais converte para/de double.

### 5. Filtro de leitura
- `getById`, `listByVehicle`, `watchByVehicle` **sempre** filtram `deleted_at IS NULL` e por `vehicle_id`.
- `listByVehicle`/`watchByVehicle` ordenam por `date DESC` (mais recente primeiro).

### 6. Injeção de tempo
Construtor opcional `DateTime Function() now` (default `() => DateTime.now().toUtc()`). Mesmo padrão da 1.1 — habilita testes determinísticos.

## Critérios de aceite (= testes em `test/data/repositories/fuel_entry_repository_test.dart`)

Usando `AppDatabase(NativeDatabase.memory())` + `now` injetado:

1. **create**: insere; `getById` retorna o mesmo `FuelEntry`; `sync_status == pending`; `createdAt == updatedAt == now()` injetado; `deletedAt == null`.
2. **create — precisão decimal sagrada (CRÍTICO)**: criar com `liters=Decimal.parse('43.219')`, `pricePerLiter=Decimal.parse('5.799')`, `totalCost=Decimal.parse('250.634781')`. `getById` retorna **exatamente** os mesmos valores (igualdade `Decimal`, sem drift de double).
3. **create — caller manda synced**: repo sobrescreve para `pending` (não confia no caller).
4. **update**: bumpa `updated_at` (≠ createdAt), preserva `createdAt`, marca `pending`. Decimal continua exato após update.
5. **update — id inexistente**: lança `StateError`.
6. **update — soft-deletado**: lança `StateError`.
7. **softDelete**: marca `deleted_at`, `sync_status=pending`. `getById` retorna `null` em seguida; `listByVehicle` não inclui.
8. **softDelete idempotente**: segunda chamada não sobrescreve `deleted_at` original (verificável via leitura raw do banco).
9. **listByVehicle**: ordena por `date DESC` (mais recente primeiro); exclui soft-deletados; isolado por `vehicleId`.
10. **listByVehicle — isolamento**: criar dois abastecimentos em veículos diferentes; cada `listByVehicle` retorna só o do seu veículo.
11. **watchByVehicle**: emite inicial; emite de novo após `create`, `update`, `softDelete`.

## Definition of Done
- 11 testes verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- Sem hard delete. Sem `double` no caminho de dinheiro/volume (testes 2 e 4 garantem).
- `FuelEntryRepository` (domínio) sem leak de Drift.

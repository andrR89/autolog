# Spec — Sprint 1.1: Repositório de `vehicles` (CRUD local + soft delete)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Fonte: `docs/ARCHITECTURE.md §2, §3, §9` + Regras de Ouro. Depende de 0.2 (Drift schema) + 0.3 (modelos de domínio). **Bloqueada até homologação do Sprint 0.**

## Escopo
Repositório local de `Vehicle` sobre Drift. CRUD com **soft delete**, **escrita offline-first** (toda mutação grava local imediatamente, marca `sync_status=pending`, bump `updated_at`), filtro por `user_id` e exclusão de registros com `deleted_at != null` em todas as queries de leitura.

Fora de escopo:
- Sync remoto (vai na 1.2).
- UI (vai na 1.3).
- Repositórios das outras entidades (vêm com seus features).
- Geração de UUID dentro do repositório (cliente do repo fornece — mantém o repo testável sem deps de tempo/aleatoriedade).

## Decisões técnicas

### 1. Interface no domínio, implementação na data
- `lib/domain/repositories/vehicle_repository.dart`: `abstract class VehicleRepository` com métodos abaixo, **falando só na linguagem de domínio** (`Vehicle`, `String id`, `String userId`). Sem vazar `Drift`.
- `lib/data/repositories/vehicle_repository.dart`: `DriftVehicleRepository implements VehicleRepository` recebendo `AppDatabase` no construtor.
- Provider Riverpod `vehicleRepositoryProvider` retorna a impl real.

### 2. API do repositório
```dart
abstract class VehicleRepository {
  /// Cria um veículo. Repositório define createdAt/updatedAt (UTC now)
  /// e sync_status=pending. Espera o caller fornecer id (UUID).
  Future<Vehicle> create(Vehicle vehicle);

  /// Atualiza. Bumpa updated_at (UTC now), marca pending. Preserva createdAt.
  /// Falha (StateError) se o id não existir ou estiver soft-deleted.
  Future<Vehicle> update(Vehicle vehicle);

  /// Soft delete: set deleted_at=now, sync_status=pending, bump updated_at.
  /// Idempotente: deletar duas vezes não erra (mantém o deleted_at original).
  Future<void> softDelete(String id);

  /// Busca por id. Retorna null se não existir OU se estiver soft-deleted.
  Future<Vehicle?> getById(String id);

  /// Lista todos os veículos NÃO deletados do usuário, ordenados por createdAt asc.
  Future<List<Vehicle>> listByUser(String userId);

  /// Stream reativo da mesma lista (Drift watch). Emite a cada mudança.
  Stream<List<Vehicle>> watchByUser(String userId);
}
```

### 3. Renomear as row classes do Drift (resolve colisão de nomes)
Os modelos de domínio (freezed) e as data classes geradas pelo Drift colidem (ambos seriam `Vehicle`/`FuelEntry`/`Expense`/`Reminder`). Anotar cada tabela em `lib/data/local/tables.dart` com `@DataClassName('VehicleRow')` (e equivalentes: `FuelEntryRow`, `ExpenseRow`, `ReminderRow`, `UsageQuotaRow`) e rodar build_runner. Companions permanecem (`VehiclesCompanion` etc.).

Os testes da 0.2 já existentes não referenciam as row classes pelo nome (usam inferência), então renomear não os quebra.

### 4. Mapeamento Drift ↔ domínio
Em `lib/data/repositories/_vehicle_mapper.dart` (privado ao módulo): funções puras `Vehicle _toDomain(VehicleRow row)` e `VehiclesCompanion _toCompanion(Vehicle v)`. Preserva todos os campos incluindo enums e `sync_status`. Mapper testado isoladamente.

### 5. Regras de mutação (não-negociáveis)
- **Toda escrita local marca `sync_status=pending`** (Regra de Ouro: offline-first). O sync (1.2) é quem vira pra `synced`.
- **`updated_at` controlado pelo repositório**, sempre UTC `now`. Caller não passa `updated_at` em `update` (se passar, é ignorado).
- **`createdAt` definido no `create`** e nunca alterado depois.
- **Soft delete é a única forma de "excluir"**. Não existe método de hard delete no MVP.

### 6. Filtro de leitura
- `getById` e as listagens **sempre** filtram `deleted_at IS NULL`. Registros soft-deletados são invisíveis ao app (mas continuam no banco pro sync).
- Listagens **sempre** filtram pelo `userId` (isolamento equivalente ao RLS remoto).

### 7. Injeção de tempo (testabilidade)
Repositório recebe `DateTime Function() now` opcional no construtor (default `DateTime.now().toUtc()`). Permite testes determinísticos de `updated_at`/`deleted_at`.

## Critérios de aceite (= testes em `test/data/repositories/vehicle_repository_test.dart`)

Usando `AppDatabase(NativeDatabase.memory())` e `now` injetado:

1. **Mapper roundtrip**: `_toDomain(_toCompanion(v).asRow(...))` preserva todos os campos de `Vehicle` (id, userId, nickname, make/model/plate nulls, fuelType, initialOdometer, createdAt, updatedAt, deletedAt, syncStatus). (Pode ser testado via create+getById se preferir evitar API privada — o spec aceita ambas formas, desde que cubra a equivalência.)
2. **create**: insere; `getById` retorna o mesmo `Vehicle`; `sync_status == pending`; `createdAt == updatedAt == now()` injetado; opcionais nulos preservados.
3. **create — usuário separado**: dois usuários criando o mesmo "tipo" de veículo não se enxergam; `listByUser('u1')` não vê de `'u2'`.
4. **update**: muda `nickname`; `updated_at` vira `now()` novo (≠ createdAt original); `createdAt` preservado; `sync_status` volta a `pending` mesmo se estava `synced`.
5. **update — id inexistente**: lança `StateError`.
6. **update — id soft-deleted**: lança `StateError` (não dá pra editar o que está "excluído").
7. **softDelete**: marca `deleted_at = now()`, `sync_status = pending`, bump `updated_at`. `getById` retorna `null` em seguida. `listByUser` não inclui.
8. **softDelete — idempotente**: deletar duas vezes não lança e **não sobrescreve** o `deleted_at` original (preserva o primeiro timestamp).
9. **listByUser**: ordena por `createdAt` ascendente; exclui soft-deletados; isolado por `userId`.
10. **watchByUser**: emite a lista inicial; **emite de novo** após `create`, `update` e `softDelete`. (Testar com `expectLater` + matchers de stream.)

## Definition of Done
- Testes acima verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- Repositório usado por nenhum widget ainda (1.3 cuida da UI).
- Nenhum método de hard delete adicionado.
- `sync_status` em todas as mutações = `pending` (verificado pelos testes 2, 4, 7).

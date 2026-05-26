# Sprint 6.E — Expandir cadastro do veículo

> Pré-requisito pra **6.G (Insights de IA)**: a IA precisa de mais contexto
> que `nickname/make/model/plate/fuelType` pra dar análises ricas.

## Objetivo
Adicionar 3 campos opcionais no `Vehicle`:
- `int? year` — ano modelo (ex: 2018). Range válido: 1900..currentYear+1.
- `String? uf` — sigla da UF onde o veículo é emplacado (2 letras BR maiúsculas).
- `String? color` — cor livre (texto curto, sem normalização).

Os campos `make` (marca) e `model` **já existem** no modelo e na tabela. Apenas
não estão expostos no form atual — vão entrar na mesma sprint.

## Mudanças

### Modelo (`lib/domain/models/vehicle.dart`)
```dart
@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,
    required String userId,
    required String nickname,
    String? make,
    String? model,
    int? year,         // NOVO
    String? uf,        // NOVO
    String? color,     // NOVO
    String? plate,
    @FuelTypeConverter() required FuelType fuelType,
    required int initialOdometer,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    @SyncStatusConverter() required SyncStatus syncStatus,
  }) = _Vehicle;
  // ...
}
```

### Drift table (`lib/data/local/tables.dart`)
```dart
class Vehicles extends Table {
  // ... existentes
  IntColumn get year => integer().nullable()();
  TextColumn get uf => text().nullable()();
  TextColumn get color => text().nullable()();
  // ...
}
```

### Schema migration (`lib/data/local/database.dart`)
- Bump `schemaVersion` de 1 → 2.
- Implementar `MigrationStrategy`:
  ```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from == 1 && to >= 2) {
        await m.addColumn(vehicles, vehicles.year);
        await m.addColumn(vehicles, vehicles.uf);
        await m.addColumn(vehicles, vehicles.color);
      }
    },
  );
  ```

### Validators (`lib/features/vehicles/vehicle_form_validators.dart`)
```dart
/// Valida ano do veículo. Opcional (null aceito).
/// - vazio/null → null (válido, campo opcional)
/// - não inteiro → "Use apenas números"
/// - < 1900 → "Ano inválido"
/// - > currentYear+1 → "Ano inválido"
String? validateYear(String? raw, {DateTime? now});

/// Valida UF brasileira. Opcional.
/// - vazio/null → null
/// - != 2 caracteres alfabéticos → "UF deve ter 2 letras"
/// - não consta nas 27 UFs BR → "UF inválida"
/// Normaliza pra maiúsculas via [normalizeUf].
String? validateUf(String? raw);

/// Normaliza UF: trim + uppercase. Retorna null se vazio.
String? normalizeUf(String? raw);

/// Set canônico das 27 UFs brasileiras.
const Set<String> brUfs = {
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
  'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
};

/// Parse opcional: null se vazio, int se válido. UI valida com [validateYear] antes.
int? parseYearOptional(String? value);
```

### Form (`lib/features/vehicles/vehicle_form_screen.dart`)
Adicionar 5 campos novos (todos opcionais) na seção "Detalhes do veículo":
- Marca (TextFormField texto livre)
- Modelo (TextFormField texto livre)
- Ano (TextFormField numérico)
- UF (TextFormField 2 letras, uppercase)
- Cor (TextFormField texto livre)

Modo edição carrega valores existentes. Modo criação aceita todos vazios.

### Saver (`lib/features/vehicles/vehicle_saver.dart`)
Propagar os 5 novos campos do form pro `Vehicle.copyWith` no save.

## Mapeamento Supabase
A coluna remota `vehicles` precisa de `year integer`, `uf text`, `color text` (todos nullable). **Documentar como TODO no spec** — migration SQL será aplicada manualmente no Supabase pelo Diretor (sem alterar sync code; `Vehicle.toJson`/`fromJson` já passa os campos novos via codegen).

## Testes (todos RED até implementação)

### `test/features/vehicles/vehicle_form_validators_test.dart` (adicionar grupos)
- `validateYear`: vazio→null; "abc"→erro; "1899"→erro; futuro+2→erro; "2024"→null; "0"→erro.
- `validateUf`: vazio→null; "S"→erro; "SP"→null; "sp"→null (case-insensitive); "XX"→erro; "1234"→erro.
- `normalizeUf`: " sp "→"SP"; ""→null; null→null.
- `parseYearOptional`: ""→null; "2020"→2020; "abc"→lança.

### `test/data/local/vehicle_schema_migration_test.dart` (novo)
- Schema v2 aceita Vehicle com year/uf/color e roundtrip preserva.
- Schema v2 aceita Vehicle sem year/uf/color (todos null).
- Migration v1→v2: cria DB schema v1 (sem as 3 colunas) com 1 vehicle, simula upgrade chamando o `onUpgrade`, verifica colunas existem e dado antigo preservado (year/uf/color = null).

## Critérios de aceite
- [ ] Todos os testes verdes (332+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Form salva e edita os 5 campos (visualização: vehicle_card mostra make/model/year quando preenchidos)
- [ ] Sync round-trip preserva os campos (ver teste)

## Não-objetivos (post-MVP)
- Autocomplete de marca/modelo via tabela FIPE
- Lookup por placa via API externa
- Validação geográfica (UF vs região de emplacamento real)
- Aplicação da migration SQL no Supabase remoto (será passo manual do Diretor)

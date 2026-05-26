# Sprint 6.H — Tipo de veículo + Specs técnicos

> Fundação da Onda 1. As sprints 6.I (FIPE), 6.J (histórico), 6.K (scan CRLV)
> e 6.L (IA preenche) dependem da estrutura criada aqui.

## Decisões do Diretor (26/05/2026)
- Suporte só a **carro + moto** (cobre 99% pessoa física).
- **Cilindrada sempre em cc** (`engineDisplacementCc: int`). Carro 1.6L → 1600. UI exibe em L pra carro ("1.6 L (1600 cc)") e cc pra moto ("250 cc").
- **Tanque em litros** com `Decimal` (moto comum 12.5 L; Regra de Ouro #2).
- **Cavalos opcional** (`horsepower: int?`).

## Mudanças

### 1. Enum `VehicleType` (`lib/domain/models/enums.dart`)
```dart
enum VehicleType {
  carro('carro'),
  moto('moto');

  const VehicleType(this.wire);
  final String wire;

  static VehicleType fromWire(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => throw ArgumentError('VehicleType desconhecido: $value'),
    );
  }
}
```
Converter `VehicleTypeConverter` em `json_converters.dart` espelhando `FuelTypeConverter`.

### 2. Vehicle model — 4 campos novos
Arquivo: `lib/domain/models/vehicle.dart`

Adicionar após `color`:
```dart
@VehicleTypeConverter() @Default(VehicleType.carro) VehicleType type,
int? engineDisplacementCc,
@DecimalNullableJsonConverter() Decimal? tankCapacityL,
int? horsepower,
```

`type` tem default `carro` pra backfill suave de veículos antigos.
`Decimal?` no tanque exige `DecimalNullableJsonConverter` — verificar se já existe; se não, adicionar em `json_converters.dart` (espelha `DecimalJsonConverter` com null-safety).

Rodar `build_runner` após.

### 3. Drift table (`lib/data/local/tables.dart`)
```dart
TextColumn get type =>
    text().map(const VehicleTypeConverter()).withDefault(const Constant('carro'))();
IntColumn get engineDisplacementCc => integer().nullable()();
TextColumn get tankCapacityL =>
    text().map(const DecimalConverter()).nullable()();
IntColumn get horsepower => integer().nullable()();
```

(`DecimalConverter` existente serve — converte Decimal ↔ String. Pode usar `.nullable()` direto.)

### 4. Schema migration v2 → v3 (`lib/data/local/database.dart`)
```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(vehicles, vehicles.year);
      await m.addColumn(vehicles, vehicles.uf);
      await m.addColumn(vehicles, vehicles.color);
    }
    if (from < 3) {
      await m.addColumn(vehicles, vehicles.type);
      await m.addColumn(vehicles, vehicles.engineDisplacementCc);
      await m.addColumn(vehicles, vehicles.tankCapacityL);
      await m.addColumn(vehicles, vehicles.horsepower);
    }
  },
);
```

### 5. Validators novos (`lib/features/vehicles/vehicle_form_validators.dart`)
```dart
/// Cilindrada em cc. Opcional. Aceita 50..9999 cc.
String? validateEngineCc(String? raw) { ... }
int? parseEngineCcOptional(String? raw);

/// Tanque em litros (Decimal). Opcional. Aceita 0.5..500 L.
/// Usa parseDecimalPtBr (vírgula/ponto).
String? validateTankL(String? raw) { ... }
Decimal? parseTankLOptional(String? raw);

/// Cavalos. Opcional. Aceita 1..2000.
String? validateHorsepower(String? raw) { ... }
int? parseHorsepowerOptional(String? raw);

/// Helper de display: carro mostra L com 1 casa (1.6 L (1600 cc)),
/// moto mostra cc puro (250 cc). Retorna string PT-BR.
String formatEngineDisplay(int cc, VehicleType type);
```

### 6. Repository mapper
Arquivo: `lib/data/repositories/vehicle_repository.dart`

Propagar 4 novos campos em ambos sentidos do mapeamento.

### 7. Form (`lib/features/vehicles/vehicle_form_screen.dart`)

**UX explícita (Diretor: o mais usual possível):**

- **Topo do form (acima do nickname)**: seletor visual carro/moto em 2 ChoiceChips grandes com ícones (Material `directions_car` / `two_wheeler`). Default `carro` (não null). Largura igual, centralizado.
- **Seção "Detalhes técnicos"** abaixo de "Detalhes do veículo" — usando `ExpansionTile` colapsável (default colapsada, marcador "(opcional)" ao lado do título).
- Dentro da seção colapsável:
  - Cilindrada — label adapta ao `type` selecionado: "Cilindrada (cc)" pra moto, "Cilindrada (cc) — ex.: 1600 para 1.6L" pra carro.
  - Tanque — "Capacidade do tanque (L)" — keyboard numérico com vírgula.
  - Cavalos — "Potência (cv)" — keyboard numérico.
- Modo edição carrega valores existentes (se algum preenchido, abrir seção expandida automaticamente).

### 8. Saver (`lib/features/vehicles/vehicle_saver.dart`)
Propagar 4 novos campos de criar/editar.

### 9. Vehicle card (`lib/features/vehicles/widgets/vehicle_card.dart`)
- Ícone do tipo (carro/moto) no canto, substituindo ícone genérico atual.
- Subtítulo enriquecido: "Honda Civic 2018 • 1.6 L" (mostrar cilindrada formatada se preenchida).

## Mapeamento Supabase
Migration `supabase/migrations/0004_vehicle_type_and_specs.sql`:
```sql
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS type text NOT NULL DEFAULT 'carro';
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS engine_displacement_cc integer;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS tank_capacity_l text;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS horsepower integer;
```
(Note: tank_capacity_l é `text` pra match com Drift que armazena Decimal como String — mesmo padrão do `amount` em expenses.)

## Testes (todos RED até implementação)

### `test/features/vehicles/vehicle_form_validators_test.dart` (adicionar grupos)
- `validateEngineCc`: vazio→null; "abc"→erro; "49"→erro (abaixo de 50); "10000"→erro (acima de 9999); "1600"→null; "250"→null.
- `validateTankL`: vazio→null; "abc"→erro; "0.4"→erro; "501"→erro; "12,5"→null (aceita vírgula PT-BR); "60"→null.
- `validateHorsepower`: vazio→null; "0"→erro; "2001"→erro; "180"→null.
- `formatEngineDisplay`: (1600, carro) → "1.6 L (1600 cc)"; (250, moto) → "250 cc"; (1000, carro) → "1.0 L (1000 cc)"; (998, carro) → "1.0 L (998 cc)" (arredonda L pra 1 casa).
- `parseEngineCcOptional`, `parseTankLOptional`, `parseHorsepowerOptional`: vazio→null; válido→valor; inválido→FormatException.

### `test/data/local/vehicle_schema_v3_test.dart` (novo)
- `schemaVersion == 3`.
- Insert + read preserva type/engineCc/tank/horsepower.
- Insert sem nenhum dos novos campos → type default `carro`, demais null.
- Migration v2→v3: cria DB v2 com 1 vehicle, ALTER manual adiciona as 4 colunas, verifica linha legada preserva e type vem 'carro' (default).
- `Vehicle.toJson` inclui as 4 chaves novas; `fromJson` roundtrip.

## Critérios de aceite
- [ ] Todos os testes verdes (399+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Form: seletor carro/moto visível e funcional; seção colapsável de specs.
- [ ] Vehicle card mostra ícone do tipo + cilindrada formatada.
- [ ] Migration 0004 documentada pra deploy manual.

## Não-objetivos (vão pras próximas sprints)
- Suporte a caminhão/van (rejeitado pelo Diretor — pessoa física foco).
- FIPE autocomplete (Sprint 6.I).
- IA preenchendo specs (Sprint 6.L).

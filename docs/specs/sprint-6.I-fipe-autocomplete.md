# Sprint 6.I — FIPE autocomplete + cache local

> Onda 1, sprint 2/5. Depende do 6.H (precisa `VehicleType` pra escolher tabela FIPE certa).
> Habilita o "wow" do cadastro: 3 taps preenchem marca/modelo/ano/valor.

## Decisões do Diretor (26/05/2026)
- API pública **parallelum.com.br/fipe/api/v2** (sem auth, gratuita).
- Cache local TTL **7 dias** (FIPE atualiza mensalmente; 7d é folgado).
- Cache offline-first (Regra de Ouro #1): se rede falhar, serve stale; se nunca cacheou, mostra erro PT-BR.
- BottomSheet com 3 passos encadeados (marca → modelo → ano), search-as-you-type em cada.
- Auto-preenche o form com highlight verde fading ao confirmar.

## Mudanças

### 1. Nova dependência
Arquivo: `pubspec.yaml`
```yaml
dependencies:
  http: ^1.2.0  # FIPE API
```
Rodar `flutter pub get`.

### 2. Vehicle model — 3 campos novos (FIPE)
Arquivo: `lib/domain/models/vehicle.dart`

Adicionar após `horsepower`:
```dart
String? fipeCode,                                   // ex: "001234-5"
@DecimalNullableJsonConverter() Decimal? fipeValue, // ex: 78420.00
String? fipeReferenceMonth,                         // "YYYY-MM" da consulta
```

Rodar build_runner.

### 3. Drift table — 3 colunas
Arquivo: `lib/data/local/tables.dart`

Na classe `Vehicles`, após `horsepower`:
```dart
TextColumn get fipeCode => text().nullable()();
TextColumn get fipeValue => text().map(const DecimalConverter()).nullable()();
TextColumn get fipeReferenceMonth => text().nullable()();
```

### 4. Nova tabela `FipeCache` — local-only (NÃO sincroniza)
Arquivo: `lib/data/local/tables.dart`

```dart
@DataClassName('FipeCacheRow')
class FipeCache extends Table {
  TextColumn get key => text()();              // path completo: "/cars/brands"
  TextColumn get value => text()();            // JSON string serializado
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
```

Adicionar `FipeCache` ao `@DriftDatabase(tables: [...])` em `database.dart`.

### 5. Schema v3 → v4 (`lib/data/local/database.dart`)
```dart
@override
int get schemaVersion => 4;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) { /* ... 6.E ... */ }
    if (from < 3) { /* ... 6.H ... */ }
    if (from < 4) {
      await m.addColumn(vehicles, vehicles.fipeCode);
      await m.addColumn(vehicles, vehicles.fipeValue);
      await m.addColumn(vehicles, vehicles.fipeReferenceMonth);
      await m.createTable(fipeCache);
    }
  },
);
```

### 6. Modelos FIPE (`lib/data/remote/fipe_models.dart`)
```dart
@freezed
abstract class FipeBrand with _$FipeBrand {
  const factory FipeBrand({required String code, required String name}) = _FipeBrand;
  factory FipeBrand.fromJson(Map<String, dynamic> json) => _$FipeBrandFromJson(json);
}

@freezed
abstract class FipeModel with _$FipeModel {
  const factory FipeModel({required String code, required String name}) = _FipeModel;
  factory FipeModel.fromJson(Map<String, dynamic> json) => _$FipeModelFromJson(json);
}

@freezed
abstract class FipeYear with _$FipeYear {
  const factory FipeYear({required String code, required String name}) = _FipeYear;
  factory FipeYear.fromJson(Map<String, dynamic> json) => _$FipeYearFromJson(json);
}

@freezed
abstract class FipeVehicleDetails with _$FipeVehicleDetails {
  const factory FipeVehicleDetails({
    required String brand,
    required String model,
    required int modelYear,         // só o ano numérico (campo "modelYear" da API)
    required String fipeCode,
    required String fuel,           // string PT (Gasolina, Etanol, Diesel...)
    @DecimalJsonConverter() required Decimal priceValue,
    required String referenceMonth, // "YYYY-MM" derivado do "referenceMonth" da API
  }) = _FipeVehicleDetails;
  factory FipeVehicleDetails.fromJson(Map<String, dynamic> json) =>
      _$FipeVehicleDetailsFromJson(json);
}
```

### 7. `FipeRepository` (`lib/data/remote/fipe_repository.dart`)

```dart
abstract class FipeRepository {
  Future<List<FipeBrand>> listBrands(VehicleType type);
  Future<List<FipeModel>> listModels(VehicleType type, String brandCode);
  Future<List<FipeYear>> listYears(VehicleType type, String brandCode, String modelCode);
  Future<FipeVehicleDetails> getDetails(
    VehicleType type, String brandCode, String modelCode, String yearCode,
  );
}

class FipeException implements Exception {
  FipeException(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => 'FipeException: $message';
}

class HttpFipeRepository implements FipeRepository {
  HttpFipeRepository({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const _base = 'https://parallelum.com.br/fipe/api/v2';

  String _path(VehicleType t) => t == VehicleType.moto ? 'motorcycles' : 'cars';

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('$_base$path');
    try {
      final r = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) {
        throw FipeException('Resposta inesperada (${r.statusCode}) da FIPE');
      }
      return jsonDecode(r.body);
    } on TimeoutException {
      throw FipeException('Timeout consultando FIPE');
    } on FipeException { rethrow; }
    catch (e) { throw FipeException('Erro de rede ao consultar FIPE', cause: e); }
  }

  @override
  Future<List<FipeBrand>> listBrands(VehicleType type) async {
    final raw = await _get('/${_path(type)}/brands') as List;
    return raw.cast<Map<String, dynamic>>().map(FipeBrand.fromJson).toList();
  }
  // ... etc
}
```

### 8. `CachedFipeRepository` — Decorator (lib/data/remote/cached_fipe_repository.dart)

```dart
class CachedFipeRepository implements FipeRepository {
  CachedFipeRepository(this._delegate, this._cache, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final FipeRepository _delegate;
  final FipeCacheStore _cache;
  final DateTime Function() _now;
  static const _ttl = Duration(days: 7);

  Future<T> _cached<T>(String key, Future<T> Function() fetch, T Function(dynamic) decode, dynamic Function(T) encode) async {
    final hit = await _cache.read(key);
    if (hit != null && hit.expiresAt.isAfter(_now())) {
      return decode(jsonDecode(hit.value));
    }
    try {
      final fresh = await fetch();
      await _cache.write(key, jsonEncode(encode(fresh)), _now().add(_ttl));
      return fresh;
    } on FipeException {
      // Stale fallback: se tem cache (mesmo expirado), serve com aviso PT-BR.
      if (hit != null) return decode(jsonDecode(hit.value));
      rethrow;
    }
  }
  // métodos implementam usando _cached
}

abstract class FipeCacheStore {
  Future<FipeCacheRow?> read(String key);
  Future<void> write(String key, String value, DateTime expiresAt);
}

class DriftFipeCacheStore implements FipeCacheStore { ... }
```

### 9. UI — Form ganha botão FIPE
Arquivo: `lib/features/vehicles/vehicle_form_screen.dart`

- **Botão proeminente "Buscar na FIPE"** logo no topo (acima do seletor de tipo? ou abaixo?). Decisão UX: **abaixo do seletor de tipo, acima do nickname** — assim user já escolheu carro/moto antes de buscar (a busca depende disso).
- Visual: `FilledButton.icon` com `Icons.search`, full-width, brand color.
- Tap → abre `FipeSearchSheet` (modal bottom sheet full-height).

### 10. `FipeSearchSheet` (`lib/features/vehicles/widgets/fipe_search_sheet.dart`)

Sheet com 3 passos visíveis em barra superior (breadcrumb "Marca > Modelo > Ano"):

- **Passo 1 — Marca:** lista de marcas com `TextField` de busca em cima (filtra client-side por substring case-insensitive). Tap → próximo passo.
- **Passo 2 — Modelo:** lista de modelos da marca selecionada, mesmo filtro.
- **Passo 3 — Ano:** lista de anos do modelo. Tap → busca details + retorna ao form preenchendo make/model/year/fipeCode/fipeValue/fipeReferenceMonth.

Estados:
- Loading: shimmer/spinner por passo.
- Erro: card PT-BR com `Tentar de novo`.
- Empty (filtro): "Nenhum resultado pra 'X'".

### 11. Aplicação no form
Ao receber `FipeVehicleDetails`:
- Preenche `make`, `model` (apenas o nome — não o code), `year` (extrai do `modelYear`), `fipeCode`, `fipeValue`, `fipeReferenceMonth`.
- Pode preencher `fuelType` do form se vazio (mapear FIPE "Gasolina"→`FuelType.gasolina`, "Álcool"→`FuelType.etanol`, "Diesel"→`FuelType.diesel`, "Flex"→`FuelType.flex`).
- **Highlight verde fading**: usar `AnimatedContainer`/`TweenAnimationBuilder` por 800ms nos campos preenchidos.

### 12. Vehicle card mostra valor FIPE
Arquivo: `lib/features/vehicles/widgets/vehicle_card.dart`

Adicionar chip discreto no canto do card: "FIPE R$ 78.420 (jan/26)" quando `fipeValue` preenchido. Color sutil, não competir com info principal.

### 13. Supabase migration
`supabase/migrations/0005_vehicle_fipe.sql`:
```sql
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS fipe_code text;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS fipe_value text;
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS fipe_reference_month text;
```
(`fipe_cache` é local-only — NÃO entra em Supabase.)

## Testes (todos RED até implementação)

### `test/data/remote/fipe_repository_test.dart` (novo)
- `listBrands(carro)` chama URL correta (`/cars/brands`), deserializa JSON em `List<FipeBrand>`.
- `listBrands(moto)` chama `/motorcycles/brands`.
- `listModels`, `listYears`, `getDetails` similar.
- HTTP 500 → `FipeException` com mensagem PT-BR.
- Timeout (>10s) → `FipeException("Timeout...")`.
- Erro de rede genérico → `FipeException` envolvendo causa.
- `getDetails` parseia `priceValue` de campo numérico/string da API (atenção: API parallelum v2 retorna `price` como string formatada "R$ X.XXX,XX" ou número — definir e testar **ambos**; aceitar string→limpar→Decimal e número→Decimal direto).

### `test/data/remote/cached_fipe_repository_test.dart` (novo)
- Primeira chamada vai pro delegate + persiste no cache.
- Segunda chamada (dentro do TTL) NÃO chama delegate — serve do cache.
- TTL expirado → chama delegate, atualiza cache.
- Delegate falha + cache válido → serve cache (mesmo expirado? Sim — fallback graceful).
- Delegate falha + cache vazio → propaga `FipeException`.
- Cache hit não-expirado deserializa corretamente o tipo (FipeBrand, FipeModel etc).

### `test/data/local/fipe_cache_test.dart` (novo)
- `DriftFipeCacheStore.write` + `read` roundtrip.
- `read` em key inexistente → null.
- Overwrite mesma key atualiza value + expiresAt.

### `test/data/local/vehicle_schema_v4_test.dart` (novo)
- `schemaVersion == 4`.
- Insert + read preserva fipeCode/fipeValue/fipeReferenceMonth.
- Migration v3 → v4 adiciona 3 colunas + cria tabela fipe_cache, preserva linhas legadas (vehicles).
- `Vehicle.toJson` inclui as 3 chaves novas (snake_case).

### Não-testes
- Widget test do `FipeSearchSheet` — pesado, fica pra polish posterior.

## Critérios de aceite
- [ ] Todos os testes verdes (426+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Botão "Buscar na FIPE" visível e funcional no form
- [ ] BottomSheet com 3 passos navegável
- [ ] Cache persiste e respeita TTL
- [ ] Modo offline (sem rede) serve cache stale

## Não-objetivos
- Histórico FIPE — Sprint 6.J
- Scan CRLV — Sprint 6.K
- IA preenche specs técnicos — Sprint 6.L
- Tradução completa de tipos de combustível FIPE (mapeia o óbvio; o que não bater fica vazio pra user escolher)

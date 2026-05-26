# Sprint 6.L — IA preenche specs técnicos

> Onda 1, sprint 5/5 — fecha a fundação do cadastro rico.
> Dado `{make, model, year, type}`, IA infere cilindrada/tanque/cavalos.

## Decisões já tomadas
- **Cota compartilhada** `scan_count` (mesmo balde dos outros scans). Inferência conta como 1 scan.
- Trigger explícito (não automático): user toca chip "✨ Preencher com IA" só visível quando make+model+year preenchidos E ao menos um dos 3 campos técnicos vazios.
- **Pipeline confirmatório**: IA preenche → user revisa (Regra de Ouro #3). Não auto-salva.

## Mudanças

### 1. Novo modelo `InferredVehicleSpecs` (`lib/features/vehicles/inferred_vehicle_specs.dart`)
```dart
@freezed
abstract class InferredVehicleSpecs with _$InferredVehicleSpecs {
  const factory InferredVehicleSpecs({
    int? engineDisplacementCc,
    @DecimalNullableJsonConverter() Decimal? tankCapacityL,
    int? horsepower,
    @Default(0.0) double confidence,
  }) = _InferredVehicleSpecs;
  factory InferredVehicleSpecs.fromJson(Map<String, dynamic> json) =>
      _$InferredVehicleSpecsFromJson(json);
}
```

### 2. Service (`lib/features/vehicles/vehicle_specs_inference_service.dart`)

```dart
abstract class VehicleSpecsInferenceService {
  Future<InferredVehicleSpecs> infer({
    required VehicleType type,
    required String make,
    required String model,
    required int year,
  });
}

class RealVehicleSpecsInferenceService implements VehicleSpecsInferenceService {
  RealVehicleSpecsInferenceService(this._invoker);
  final EdgeFunctionInvoker _invoker;

  @override
  Future<InferredVehicleSpecs> infer({...}) async {
    try {
      final body = await _invoker.invoke('infer-vehicle-specs', {
        'type': type.wire,
        'make': make,
        'model': model,
        'year': year,
      });
      return InferredVehicleSpecs.fromJson(body);
    } on QuotaExhaustedException { rethrow; }
    on ScanException { rethrow; }
    catch (e) {
      throw ScanException('Falha ao inferir specs do veículo', cause: e);
    }
  }
}

class MockVehicleSpecsInferenceService implements VehicleSpecsInferenceService {
  // padrão: callCount, fixedResult, throwOnCall.
  // default: engineDisplacementCc=1600, tankCapacityL=Decimal.parse('47'),
  //          horsepower=124, confidence=0.85
}

final vehicleSpecsInferenceServiceProvider =
    Provider<VehicleSpecsInferenceService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealVehicleSpecsInferenceService(
    SupabaseEdgeFunctionInvoker(client),
  );
});
```

### 3. Edge function `supabase/functions/infer-vehicle-specs/index.ts`

Espelho do `analyze-history` (sem imagem, só texto). Estrutura:
- Auth JWT + cota `scan_count` (limit 5/mês free, mesmo dos outros scans).
- Body: `{ type, make, model, year }`. Valida tipos. 400 se inválido. `type ∈ {'carro','moto'}`.
- Prompt PT-BR:
  ```
  Você sabe specs técnicas de veículos brasileiros.
  Dado:
    Tipo: {carro|moto}
    Marca: {make}
    Modelo: {model}
    Ano: {year}

  Responda APENAS com JSON, sem markdown.
  Schema: {
    "engine_displacement_cc": int|null,
    "tank_capacity_l": number|null,
    "horsepower": int|null,
    "confidence": number entre 0 e 1
  }
  Regras:
  - engine_displacement_cc: cilindrada em cc (carro 1.6L → 1600). Range válido 50..9999.
  - tank_capacity_l: capacidade do tanque em litros. Decimal. Range 0.5..500.
  - horsepower: potência em cv. Range 1..2000.
  - confidence: sua certeza global no chute (0 = chute total, 1 = informação oficial).
  Se não souber um campo, retorne null.
  Nunca invente — prefira null com baixa confidence a chutar.
  ```
- Modelo: `claude-haiku-4-5`, `max_tokens: 256`.
- Parse defensivo + validação shape (campos fora de range → null).
- Incrementa cota **só se** ≥ 1 dos 3 campos veio não-null E confidence ≥ 0.3.

### 4. UI — Chip "Preencher com IA" na seção técnica
`lib/features/vehicles/vehicle_form_screen.dart`

Na `_TechnicalSpecsSection` (criada no 6.H):
- Quando `_makeController.text.trim().isNotEmpty && _modelController.text.trim().isNotEmpty && _yearController.text.trim().isNotEmpty && (qualquer dos 3 campos técnicos vazio)` → mostrar chip:

```dart
ActionChip(
  avatar: const Icon(Icons.auto_awesome, size: 18),
  label: const Text('Preencher com IA'),
  onPressed: _onInferSpecs,
)
```

`_onInferSpecs`:
1. `_inferring = true` (desabilita o chip + ação).
2. `await ref.read(vehicleSpecsInferenceServiceProvider).infer(...)`.
3. Sucesso:
   - Preenche os 3 controllers (só campos não-null da resposta E só se o controller estava vazio — não sobrescreve user input).
   - `TweenAnimationBuilder` highlight verde nos campos preenchidos.
   - Snackbar PT-BR: "Confira os dados sugeridos" (confidence ≥ 0.7) ou "Sugestão com baixa confiança — revise" (< 0.7).
4. `QuotaExhaustedException` → MaterialBanner "Cota mensal de scans esgotada — preencha manual ou vire premium."
5. Outro `ScanException` → snackbar "Não conseguimos inferir agora. Tente de novo ou preencha manualmente."
6. Sempre: `_inferring = false` no `finally`.

### 5. Mock como default em dev?
Não — mantenha real. Apenas test usa override.

## Testes (todos RED até implementação)

### `test/features/vehicles/inferred_vehicle_specs_test.dart` (novo)
- Parse JSON completo.
- Campos null individuais.
- JSON vazio → tudo null e confidence=0.0.
- Chaves extras ignoradas.
- Confidence ausente → default 0.0.
- Roundtrip toJson/fromJson.

### `test/features/vehicles/vehicle_specs_inference_service_test.dart` (novo)
- Invoca `'infer-vehicle-specs'` com body correto (`type/make/model/year`).
- Retorna `InferredVehicleSpecs` parseado.
- 429 → `QuotaExhaustedException`.
- `ScanException` propaga sem wrap.
- Erro genérico → `ScanException` contendo "specs".
- Mock: callCount/fixedResult/throwOnCall.

## Critérios de aceite
- [ ] Todos os testes verdes (497+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Chip "Preencher com IA" aparece apenas com as condições corretas
- [ ] Não sobrescreve campos já preenchidos pelo user

## Não-objetivos
- Cache de inferências (cada chamada vai pro Haiku).
- Persistência da `confidence` no Vehicle (é só pra decidir tom da mensagem na UI).
- Inferência em lote (1 veículo por vez).

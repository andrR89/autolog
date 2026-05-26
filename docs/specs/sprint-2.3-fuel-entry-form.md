# Spec — Sprint 2.3: Formulário de abastecimento manual

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 2.1 (`FuelEntryRepository`) + 1.3 (Vehicle UI/route patterns).

## Escopo
Formulário criar/editar de abastecimento (`FuelEntry`) com validações PT-BR, **parser de Decimal pt-BR** (aceita vírgula como separador decimal) e auto-cálculo do total. Saver para orquestrar create/update/delete. Rotas registradas — o entry-point na navegação (FAB/lista) vem na 2.4 junto da lista.

Fora de escopo:
- Tela de lista de abastecimentos (2.4).
- Cálculo de consumo na UI (2.4 wires).
- Scan por IA / OCR (Sprint 3).

## Decisões técnicas

### 1. Parser decimal pt-BR (testável puro)
`lib/features/fuel/fuel_form_validators.dart`:
- `Decimal parseDecimalPtBr(String input)`: normaliza vírgula → ponto e chama `Decimal.parse`. Lança `FormatException` se não parseável. **Nunca passa por `double`**. Trim antes.
- `String? validateDecimalPositive(String? raw, {required String fieldLabel})`: vazio/null → "Informe $fieldLabel"; não parseável → "Use apenas números (ex.: 43,219)"; ≤ 0 → "Deve ser maior que zero"; ok → null.
- `String? validateOdometerAtFueling(String? raw)`: igual à 1.3 (`validateInitialOdometer`), mas mensagens podem reutilizar — vou recriar inline com a mesma semântica pra evitar dependência cross-feature.

### 2. Helper de total
`Decimal computeTotalCost(Decimal liters, Decimal pricePerLiter) => liters * pricePerLiter;`
Pura, dois Decimal, nunca double.

### 3. `FuelEntrySaver` (testável)
`lib/features/fuel/fuel_entry_saver.dart` — espelha `VehicleSaver` (1.3). Recebe `FuelEntryRepository` + `String Function() generateId`.
```dart
class FuelEntrySaver {
  FuelEntrySaver(this._repo, {required String Function() generateId});

  Future<FuelEntry> create({
    required String vehicleId,
    required DateTime date,
    required int odometer,
    required Decimal liters,
    required Decimal pricePerLiter,
    required Decimal totalCost,
    required bool fullTank,
    required FuelType fuelType,
    // source sempre = manual (este é o formulário manual)
  });

  Future<FuelEntry> update(
    FuelEntry existing, {
    required DateTime date,
    required int odometer,
    required Decimal liters,
    required Decimal pricePerLiter,
    required Decimal totalCost,
    required bool fullTank,
    required FuelType fuelType,
  });

  Future<void> delete(String id);
}
```
- `create` define `source = FuelSource.manual`, `receiptImageUrl = null`. Repo cuida de timestamps/syncStatus.
- `update` preserva `id`, `vehicleId`, `createdAt`, `source`, `receiptImageUrl` do existing (não troca a origem nem perde o cupom).
- Provider Riverpod `fuelEntrySaverProvider` consumindo `fuelEntryRepositoryProvider` + UUID v4.

### 4. UI (PT-BR, Material 3)
`lib/features/fuel/fuel_entry_form_screen.dart`:
- Title: "Novo abastecimento" / "Editar abastecimento".
- Campos:
  - **Data** (DatePicker, default `DateTime.now()` no create, default `existing.date` no edit).
  - **Odômetro (km)** — numérico inteiro, `FilteringTextInputFormatter.digitsOnly`. Validator de monotônico (`isOdometerMonotonic` de 2.2) compara com o último abastecimento do veículo (lookup via `repo.listByVehicle`); se < anterior, **mostra aviso INLINE não bloqueador** ("Atenção: odômetro menor que o anterior — confirma?"). NÃO impede salvar.
  - **Litros**, **Preço por litro**, **Total (R$)** — três `TextFormField` aceitando vírgula. **Litros e preço editáveis**; **total auto-calculado** ao mudar litros ou preço (`computeTotalCost`). O total é editável também? **Não** no MVP — read-only com cálculo automático. Mantém a UX simples e a aritmética consistente.
  - **Tanque cheio** — Switch, default `true`.
  - **Tipo de combustível** — Dropdown (mesmo do form de veículo), default = `vehicle.fuelType`.
- Botão **Salvar** com loading; SnackBar PT-BR amigável em erro.
- Layout cuida do teclado (`SingleChildScrollView`).

### 5. Roteamento
Em `lib/core/router.dart`:
- `/vehicles/:vehicleId/fuel/new` → carrega o `Vehicle` (via `vehicleRepositoryProvider.getById`), passa pra `FuelEntryFormScreen(vehicle: ..., initial: null)`. Vehicle não encontrado → redirect `/vehicles`.
- `/vehicles/:vehicleId/fuel/:entryId/edit` → carrega `vehicle` + `entry` (via `fuelEntryRepositoryProvider.getById`); entry null → redirect `/vehicles/:vehicleId`.

Sem entry-point visível ainda (a 2.4 vai adicionar a FAB na lista de abastecimentos).

## Critérios de aceite (= testes em `test/features/fuel/`)

**`fuel_form_validators_test.dart`** (parsers/validadores/helper):
1. `parseDecimalPtBr`: "5,5"→`5.5`; "5.5"→`5.5`; "  43,219  "→`43.219`; "abc"→`FormatException`; ""→`FormatException`.
2. `parseDecimalPtBr` — alta precisão: "12345678901234,123456789" roundtrip exato (sem double).
3. `validateDecimalPositive`: vazio/null → erro com label; "0"/"-1" → "Deve ser maior que zero"; "abc" → "Use apenas números (ex.: 43,219)"; "0,1" → null.
4. `validateOdometerAtFueling`: vazio → erro; "abc" → erro; "-1" → erro; "0" → null; "45000" → null.
5. `computeTotalCost(43.219, 5.799)` = `Decimal.parse('250.626981')` (multiplicação exata: 43219 × 5799 = 250_626_981 → 6 casas decimais).

**`fuel_entry_saver_test.dart`** (com `FakeFuelEntryRepository`):
6. `create` chama `repo.create` com FuelEntry montado: id do generateId, todos os campos do params, `source = FuelSource.manual`, `receiptImageUrl = null`. Decimal exato.
7. `update` preserva `id`, `vehicleId`, `createdAt`, `source`, `receiptImageUrl` do existing; aplica os campos novos. Decimal exato.
8. `delete` chama `repo.softDelete(id)`.
9. Erros do repo propagam intactos.

**Deliverables (Haiku + homologação):**
10. Form abre via URL `/vehicles/:vehicleId/fuel/new`, valida campos, calcula total, salva, navega de volta pra `/vehicles/:vehicleId` (ainda placeholder — vai virar lista na 2.4).
11. Edição de abastecimento existente funciona via `/vehicles/:vehicleId/fuel/:entryId/edit`.
12. Aviso de odômetro não monotônico aparece mas não bloqueia salvar.

## Definition of Done
- 9 testes verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Nenhum `double` no path Decimal.
- `source = manual` hardcoded no `create` (este é o form manual).

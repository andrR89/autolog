# Spec — Sprint 4.1b: UI de despesas (form + lista)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa; André homologa.
> Depende de 4.1a (`ExpenseRepository`) + padrões 1.3/2.3/2.4 (forms, validators, saver).

## Escopo
- `ExpenseSaver` orquestrando create/update/delete via repo.
- Form criar/editar despesa (PT-BR, categoria, valor decimal pt-BR, data, odômetro opcional, descrição).
- Tela de lista de despesas do veículo.
- Entry-point pra navegar do detalhe do veículo (`FuelHistoryScreen`) pra `ExpensesListScreen`.
- Rotas novas: `/vehicles/:vehicleId/expenses`, `/expenses/new`, `/expenses/:id/edit`.

Fora de escopo: lembretes (4.2), notificações (4.3), validações cruzadas data↔odômetro pra expenses (odômetro é opcional aqui — sem regra).

## Decisões técnicas

### 1. `ExpenseSaver` (testável, espelha `VehicleSaver`/`FuelEntrySaver`)
`lib/features/expenses/expense_saver.dart`:
```dart
class ExpenseSaver {
  ExpenseSaver(this._repo, {required String Function() generateId});

  Future<Expense> create({
    required String vehicleId,
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    required Decimal amount,
    int? odometer,
  });

  Future<Expense> update(
    Expense existing, {
    required DateTime date,
    required ExpenseCategory category,
    required String description,
    required Decimal amount,
    int? odometer,
  });

  Future<void> delete(String id);
}
```
- `create`: gera id via `generateId`, repo cuida de timestamps/syncStatus.
- `update`: preserva `id`, `vehicleId`, `createdAt`.
- Provider `expenseSaverProvider` consumindo `expenseRepositoryProvider` + UUID v4.

### 2. Validador de valor (pode reusar do form de combustível)
`validateDecimalPositive` (de `fuel_form_validators.dart`) já serve. Pra descrição: `validateRequired(value)` simples ("Informe uma descrição").

### 3. Form `ExpenseFormScreen`
`lib/features/expenses/expense_form_screen.dart`:
- Title: "Nova despesa" / "Editar despesa".
- AppBar com `BackButton` explícito (padrão 3.6).
- Campos PT-BR:
  - **Data** (DatePicker, default today no create).
  - **Categoria** (dropdown: Manutenção / Lavagem / Estacionamento / Multa / Seguro / IPVA / Outro — labels PT-BR ligadas aos enum `ExpenseCategory`).
  - **Descrição** (text, required).
  - **Valor (R$)** (numérico decimal pt-BR via `parseDecimalPtBr` + `validateDecimalPositive(fieldLabel: 'valor')`).
  - **Odômetro (km)** — opcional, vazio é OK, se preenchido valida int >= 0.
- Botão **Salvar** com loading; SnackBar PT-BR em erro; ao salvar volta pra `/vehicles/$vehicleId/expenses`.

### 4. Lista `ExpensesListScreen`
`lib/features/expenses/expenses_list_screen.dart`:
- AppBar título "Despesas" + pencil pra editar veículo (consistente com fuel history).
- Body: `StreamProvider.family` ouvindo `repo.watchByVehicle(vehicleId)`. Loading / erro / vazio (placeholder "Nenhuma despesa registrada. Toque em + pra começar.") / lista.
- Cada item em `Card`:
  - Header: data formatada (esquerda) + valor `formatCurrencyBr(amount)` em destaque (direita).
  - Sub: categoria PT-BR (ícone por categoria opcional) • descrição (max 2 linhas) • odômetro se houver.
  - Trash icon → AlertDialog confirm → `saver.delete(id)`.
  - Tap → `/vehicles/$vehicleId/expenses/$id/edit`.
- FAB **+** → push `/vehicles/$vehicleId/expenses/new`.

### 5. Entry-point no detalhe do veículo
`FuelHistoryScreen`: adicionar um botão/tile **"Despesas"** acima da lista (ou um ícone na AppBar) que push pra `/vehicles/$vehicleId/expenses`.

Decisão: na AppBar adicionar um `IconButton` `Icons.attach_money` com tooltip "Despesas", ANTES do pencil. Push pra rota.

### 6. Roteamento
Adicionar em `lib/core/router.dart`:
- `/vehicles/:vehicleId/expenses` → carrega `Vehicle` → `ExpensesListScreen(vehicle: ...)`.
- `/vehicles/:vehicleId/expenses/new` → loader → `ExpenseFormScreen(vehicle: ..., initial: null)`.
- `/vehicles/:vehicleId/expenses/:expenseId/edit` → loader → carrega expense também → `ExpenseFormScreen(vehicle: ..., initial: expense)`.

### 7. Categoria PT-BR
Map enum → label PT-BR no widget de dropdown:
```dart
const _categoryLabels = {
  ExpenseCategory.manutencao: 'Manutenção',
  ExpenseCategory.lavagem: 'Lavagem',
  ExpenseCategory.estacionamento: 'Estacionamento',
  ExpenseCategory.multa: 'Multa',
  ExpenseCategory.seguro: 'Seguro',
  ExpenseCategory.ipva: 'IPVA',
  ExpenseCategory.outro: 'Outro',
};
```

## Critérios de aceite

**`test/features/expenses/expense_saver_test.dart`** (com `_FakeExpenseRepository`):

1. `create`: chama `repo.create` com Expense montado: id do generateId, vehicleId/date/category/description/amount/odometer dos params.
2. `update`: preserva `id`, `vehicleId`, `createdAt` do existing; aplica os novos campos.
3. `delete`: chama `repo.softDelete(id)`.
4. Erro do repo propaga intacto (StateError, etc.).

**Deliverables (Haiku + homologação):**
5. Botão Despesas na AppBar do detalhe do veículo navega pra lista.
6. Criar/listar/editar/excluir despesa funciona; valor em PT-BR (vírgula); categoria em dropdown PT-BR; data via picker.
7. Lista ordena por data desc (com tiebreaker createdAt desc da 4.1a).
8. Validação de valor positivo bloqueia salvar.

## Definition of Done
- 4 testes do saver verdes; suíte completa verde (~205); `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Sem hard delete; sem `double` no path do amount.
- PT-BR em tudo.

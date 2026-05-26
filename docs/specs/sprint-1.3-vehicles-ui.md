# Spec — Sprint 1.3: CRUD de veículos na UI

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa; André homologa visualmente.
> Depende de 1.1 (`VehicleRepository`) + 0.5 (auth → `userId`).

## Escopo
Primeira tela funcional do app: lista de veículos do usuário, com criar, editar e "excluir" (soft delete). Sem sync trigger explícito ainda (1.4 cuida do indicador; sync efetivo conecta na homologação do Sprint 1).

Fora de escopo: indicador de sync na UI (1.4); demais entidades (vêm depois).

## Decisões técnicas

### 1. Roteamento
- `/home` deixa de ser placeholder → **redireciona pra `/vehicles`** (lista).
- Novas rotas:
  - `/vehicles` — lista (FAB pra adicionar; botão sair no AppBar).
  - `/vehicles/new` — form em modo criar.
  - `/vehicles/:id/edit` — form em modo editar.
- Mantém o `authRedirect` existente; quem não está logado segue indo pro `/login`.

### 2. Validadores (testáveis, puros)
`lib/features/vehicles/vehicle_form_validators.dart`:
- `validateNickname(String?) → String?`: vazio/null → "Informe um apelido"; ok → null.
- `validateInitialOdometer(String?) → String?`: vazio/null → "Informe o odômetro inicial"; não-int → "Use apenas números"; negativo → "Não pode ser negativo"; ok (incluindo `"0"`) → null.
- `parseOdometer(String) → int`: parser puro usado pelo controller. Lança `FormatException` se inválido (a UI confia na validação prévia).

### 3. Controller de salvamento (testável)
`lib/features/vehicles/vehicle_saver.dart` — uma classe que orquestra a criação/edição via repo. Recebe `VehicleRepository` + `String Function() generateId` injetáveis (UUID via `package:uuid`).
```dart
class VehicleSaver {
  VehicleSaver(this._repo, {required String Function() generateId});

  /// Cria um veículo novo. Repositório define timestamps e sync_status.
  Future<Vehicle> create({
    required String userId,
    required String nickname,
    String? make,
    String? model,
    String? plate,
    required FuelType fuelType,
    required int initialOdometer,
  });

  /// Atualiza um veículo existente, preservando id/userId/createdAt.
  /// O repositório bumpa updated_at e volta sync_status para pending.
  Future<Vehicle> update(
    Vehicle existing, {
    required String nickname,
    String? make,
    String? model,
    String? plate,
    required FuelType fuelType,
    required int initialOdometer,
  });

  Future<void> delete(String id);
}
```
Provider Riverpod `vehicleSaverProvider`.

### 4. Lista reativa
`vehiclesProvider` = `StreamProvider<List<Vehicle>>` que escuta `repo.watchByUser(currentUserId)`. `currentUserId` é derivado do `authServiceProvider` (Supabase user.id; lança/expõe erro claro se chamado sem sessão — não deve acontecer porque o redirect garante login).

### 5. UI (PT-BR, Material 3)
- **`VehiclesListScreen`**: `AppBar` "Meus veículos" + ícone sair; corpo = `AsyncValue` da lista (loading/erro/lista); vazio mostra placeholder amigável "Você ainda não cadastrou nenhum veículo. Toque em **+** pra começar."; FAB **+** abre `/vehicles/new`; cada item da lista mostra apelido, marca/modelo (se houver), placa (se houver), tipo de combustível e odômetro inicial; **tap no item** abre `/vehicles/:id/edit`; **icon button de lixeira** abre `AlertDialog` de confirmação ("Excluir este veículo? Pode ser recuperado depois.") → confirmar chama `saver.delete(id)`.
- **`VehicleFormScreen`** (cria ou edita conforme rota): título "Novo veículo" ou "Editar veículo"; campos: Apelido, Marca (opcional), Modelo (opcional), Placa (opcional), Tipo de combustível (dropdown: Gasolina/Etanol/Diesel/Flex/GNV, default Flex no novo), Odômetro inicial (numérico); botão **Salvar** com loading; mensagens de erro PT-BR inline (do validador) e SnackBar pra erro de save; ao salvar, faz `context.go('/vehicles')`.

### 6. Soft delete UX
Confirmação obrigatória antes de excluir. Mensagem deixa claro que é reversível (a coluna `deleted_at` é soft; recuperação não está exposta na UI no MVP, mas o copy não mente: "pode ser recuperado depois" implica que existe a possibilidade — não promete que já está implementado).

## Critérios de aceite

**Testes (`test/features/vehicles/vehicle_form_validators_test.dart` + `vehicle_saver_test.dart`) — verdes:**

Validadores:
1. `validateNickname`: vazio/null → erro PT-BR; "Meu Civic" → null.
2. `validateInitialOdometer`: vazio/null → erro; "abc" → "Use apenas números"; "-1" → "Não pode ser negativo"; "0" → null; "45000" → null.
3. `parseOdometer`: "45000" → 45000; "abc" → lança `FormatException`.

VehicleSaver (com `FakeVehicleRepository` em memória):
4. `create` chama `repo.create` com um Vehicle montado: id do `generateId`, userId/nickname/etc. dos params, `createdAt/updatedAt` em valores quaisquer (são sobrescritos pelo repo — verificar que o saver passou um Vehicle válido). Retorna o `Vehicle` que o repo devolveu.
5. `update` chama `repo.update` preservando `id`, `userId` e `createdAt` do `existing`, aplicando apenas os campos novos da assinatura.
6. `delete` chama `repo.softDelete(id)`.
7. Erros do repo (ex.: `StateError` no update de soft-deletado) propagam intactos para o caller — saver não engole.

**Deliverables (revisão Haiku + homologação André):**
8. Cria-listar-editar-excluir funcionando contra o Supabase real (após login).
9. PT-BR, validações inline, confirmação de exclusão, estados de loading/erro tratados.
10. Roteamento atualizado; `/home` redireciona pra `/vehicles`.

## Definition of Done
- Testes verdes (validadores + saver); suíte completa verde; `dart format`; `flutter analyze` limpo.
- Builda no simulador iOS (`flutter build ios --simulator --debug --dart-define-from-file=dart_define.json`).
- Sem hard delete na UI nem no controller.
- `Vehicle` UI usa o `vehicleRepositoryProvider` existente; nada de chamar Supabase direto na camada de UI.

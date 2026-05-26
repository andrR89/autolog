# Spec — Sprint 3.7: Validação cronológica cruzada (data ↔ odômetro)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> **Classificação: B (spec da 2.3 era incompleto — culpa do Opus).** A 2.3 só validava monotonicidade contra o último abastecimento; faltava o caso de inserir/editar entry no meio da linha do tempo.

## Problema
A sequência `(date, odometer)` ordenada cronologicamente deve ser monotônica não-decrescente — carro não anda pra trás no tempo. Atualmente o form só compara com o entry mais recente, então é possível:
- Salvar entry com data antiga e odômetro alto (entre dois cheios) — quebra a ordem.
- Salvar entry com odômetro menor que o anterior cronológico mais próximo (com data igual ou diferente).

Resultado: lista mostra pares `(data, odômetro)` inconsistentes; cálculo de consumo do 2.2 vira lixo nesses casos.

## Decisão
Substituir o `isOdometerMonotonic` (simples) por uma função mais rica:

```dart
/// Verifica se inserir/editar um entry com [date] e [odometer] mantém a ordem
/// cronológica monotônica não-decrescente do odômetro.
///
/// Retorna null se consistente, ou mensagem PT-BR descrevendo a violação.
/// [exclude] é o id da entry sendo editada (pra não comparar consigo mesma).
String? checkChronoConsistency({
  required DateTime date,
  required int odometer,
  required List<FuelEntry> existing,
  String? excludeId,
});
```

Algoritmo:
1. Filtrar `existing` removendo `excludeId`.
2. Ordenar por `date` ascendente.
3. Encontrar `prior` = último entry com `entry.date <= date` (mais próximo no passado, ou empate).
4. Encontrar `next` = primeiro entry com `entry.date > date` (mais próximo no futuro).
5. Validar:
   - Se `prior != null && odometer < prior.odometer` → "Odômetro menor que o de um abastecimento anterior em $dataAnterior ($odomAnterior km)".
   - Se `next != null && odometer > next.odometer` → "Odômetro maior que o de um abastecimento posterior em $dataPosterior ($odomPosterior km)".
   - Se ambos violam, prioriza a mensagem do `prior` (mais comum o usuário digitar baixo demais).
6. Caso ok, retorna null.

Datas iguais: tratadas como "no passado" → `prior` captura entry com mesma data; se odômetro novo é menor que dele, viola.

**Não-bloqueador** (segue PRD §7: avisar, não bloquear). Form mostra a mensagem inline em vermelho debaixo do campo de odômetro, mas o botão Salvar continua habilitado.

## Mudanças

### `lib/features/fuel/fuel_form_validators.dart` (ou novo `chrono_consistency.dart`)
- Adicionar `checkChronoConsistency(...)` no mesmo arquivo dos outros validadores.
- Manter `isOdometerMonotonic` em `consumption_calculator.dart` por enquanto (não removo, mas o form para de usar).

### `lib/features/fuel/fuel_entry_form_screen.dart`
- Substituir o `_checkOdometerMonotonic` debounced existente por `_checkChrono` que chama a função nova (passando `date`, `odometer`, lista completa do veículo, `excludeId` se edit).
- Dispara debounced quando muda **odômetro** OU **data**.
- Em vez de `_odometerWarning: bool`, usa `_chronoWarning: String?` (a própria mensagem).
- Mostra a mensagem em `Text(_chronoWarning!, style: TextStyle(color: ColorScheme.error))` abaixo do campo odômetro quando não-null.

## Critérios de aceite

**`test/features/fuel/chrono_consistency_test.dart` (novo)**:

Helper `_entry(id, date, odometer)` minimal.

1. **Lista vazia** → null (consistente).
2. **Único entry no histórico, novo posterior com odômetro maior** → null.
3. **Único entry, novo posterior com odômetro menor** → mensagem PT-BR contendo "menor".
4. **Novo entry no meio**: existing tem (20/05, 45000) e (22/05, 46000); novo (21/05, 45500) → null (cabe).
5. **Novo entry no meio, odômetro acima do posterior**: existing (20/05, 45000) e (22/05, 46000); novo (21/05, 50000) → mensagem PT-BR contendo "maior" e a data do posterior (22/05).
6. **Novo entry no meio, odômetro abaixo do anterior**: existing (20/05, 45000) e (22/05, 46000); novo (21/05, 44000) → mensagem PT-BR contendo "menor" e data do anterior (20/05).
7. **Mesma data, odômetro maior** → null (carro andou no mesmo dia, ok).
8. **Mesma data, odômetro menor** → mensagem PT-BR.
9. **Edit mode (excludeId)**: existing já contém a entry sendo editada — passando `excludeId` ela é ignorada e o resultado é como se ela não estivesse na lista.
10. **Múltiplas violações** (acima do posterior E abaixo do anterior simultâneo): prioriza mensagem do anterior.

**Deliverable (Haiku + homologação)**:
11. Form mostra mensagem inline PT-BR colorida; aviso aparece tanto ao mexer no odômetro quanto na data; é **não-bloqueador**.

## Definition of Done
- 10 testes verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Form continua salvando com inconsistência (não bloqueia — PRD).

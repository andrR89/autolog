# Spec — Sprint 3.8: Validação bloqueante de odômetro (substitui 3.7 + estende)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> **Classificação: C (direção)** — homologação do 3.7 mostrou que aviso não-bloqueador é fraco demais; mudança de direção do PRD §7 (avisar→bloquear) com regra refinada do Diretor.

## Regra unificada (palavra do Diretor)
1. **Odômetro nunca menor que `vehicle.initial_odometer`** (carro tem um marco de partida — não pode ter abastecimento abaixo dele).
2. **Cross-date monotônico estrito**:
   - Não pode existir abastecimento em data **anterior** com odômetro **maior** que o novo.
   - Não pode existir abastecimento em data **posterior** com odômetro **menor** que o novo.
3. **Mesma data: sem restrição entre entries** — não registramos hora, então não dá pra saber qual veio antes dentro do dia. Permite qualquer ordem.
4. **Botão Salvar desabilitado** quando alguma regra é violada, com mensagem PT-BR clara dizendo qual regra quebrou.

## Decisões técnicas

### 1. Refatora `checkChronoConsistency` → `validateOdometerForEntry`
Em `lib/features/fuel/fuel_form_validators.dart`, substituir/renomear. Nova assinatura:
```dart
/// Valida que (date, odometer) cabe na linha do tempo do veículo + respeita o
/// odômetro inicial. Retorna null se válido, ou mensagem PT-BR explicando a
/// violação. [excludeId] ignora a própria entry em modo edição.
String? validateOdometerForEntry({
  required DateTime date,
  required int odometer,
  required int initialOdometer,
  required List<FuelEntry> existing,
  String? excludeId,
});
```

Lógica:
1. Se `odometer < initialOdometer` → "Odômetro menor que o inicial do veículo ($initialOdometer km)".
2. Filtrar existing por `excludeId`.
3. Para `prior` = qualquer entry com `date < new_date` (estrito): se `prior.odometer > odometer` → "Já existe abastecimento em $dataAnterior com odômetro maior ($X km)".
4. Para `next` = qualquer entry com `date > new_date` (estrito): se `next.odometer < odometer` → "Já existe abastecimento em $dataPosterior com odômetro menor ($X km)".
5. Pega o pior violador de cada lado (max odometer dos anteriores; min odometer dos posteriores) pra dar a mensagem mais informativa.
6. **Mesma data não é avaliada** (regra 3).
7. Caso ok → null.

> `checkChronoConsistency` da 3.7 pode ser removido (não é usado fora do form e a nova função substitui). Os testes da 3.7 viram do nova função, atualizados pelo Opus.

### 2. Form: botão Salvar condicional
`lib/features/fuel/fuel_entry_form_screen.dart`:
- `String? _validationError` substitui `String? _chronoWarning` (agora bloqueia).
- `_runValidation()` chama `validateOdometerForEntry(...)` passando `widget.vehicle.initialOdometer`.
- Dispara on-change de odômetro (debounced 600ms) E on-change de data (imediato).
- Botão "Salvar":
  - `onPressed: _validationError == null && !_saving ? _submit : null` (disabled quando há erro).
  - Mostra `Text(_validationError!, style: red)` debaixo do campo de odômetro quando não-null.
  - Tooltip no botão desabilitado: "Corrija o odômetro pra salvar" (opcional).

### 3. Vehicle precisa expor `initialOdometer` à validação
Já existe em `Vehicle` (passamos no form via `widget.vehicle`). Sem mudança de modelo.

## Critérios de aceite

**Atualizar `test/features/fuel/chrono_consistency_test.dart`** → renomear pra `test/features/fuel/odometer_validation_test.dart` e reescrever pra cobrir:

`validateOdometerForEntry`:
1. **Odômetro abaixo do inicial**: vehicle initial=1500, novo odometer=1200, existing vazio → mensagem PT-BR contendo "inicial" e "1500".
2. **Odômetro == inicial, existing vazio**: ok → null.
3. **Odômetro acima do inicial, existing vazio**: ok → null.
4. **Anterior em data com odômetro maior**: existing=[(20/05, 46000)], novo (22/05, 45000), initial=1000 → mensagem com "anterior" e "46000".
5. **Posterior em data com odômetro menor**: existing=[(22/05, 46000)], novo (20/05, 47000), initial=1000 → mensagem com "posterior" e "46000".
6. **Novo no meio cabe**: existing=[(20/05, 45000), (22/05, 46000)], novo (21/05, 45500), initial=1000 → null.
7. **Novo no meio acima do posterior**: existing=[(20/05, 45000), (22/05, 46000)], novo (21/05, 50000), initial=1000 → mensagem "posterior" "46000".
8. **Novo no meio abaixo do anterior**: existing=[(20/05, 45000), (22/05, 46000)], novo (21/05, 44000), initial=1000 → mensagem "anterior" "45000".
9. **Mesma data, odômetro qualquer**: existing=[(22/05, 45000)], novo (22/05, 40000), initial=1000 → null (mesma data não checa).
10. **Edit mode (excludeId)**: ignora a própria entry.
11. **Inicial é o pior anterior**: vehicle initial=1500, existing=[(20/05, 2000)], novo (22/05, 1800), initial=1500 → bloqueia por "anterior 2000" (não pelo inicial, porque 1800 > 1500).

**Form (revisado por Haiku + homologação):**
12. Botão Salvar desabilita quando há violação; reabilita quando corrige.
13. Mensagem PT-BR aparece em vermelho embaixo do campo odômetro.
14. Mudança de data dispara revalidação imediata.

## Definition of Done
- ~11 testes da nova função verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Bloqueio real (não só visual): tap em Salvar desabilitado não dispara.
- PRD §7 fica desatualizado intencionalmente — atualizar `PRD.md §7` pra refletir mudança de regra: "Odômetro deve ser **>= odômetro inicial** e **monotônico crescente entre datas distintas**. Mesma data permite qualquer ordem (não registramos hora)."

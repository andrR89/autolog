# Spec — Sprint 3.3: Fluxo de scan → form pré-preenchido (com mock)

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa.
> Depende de 3.0 (`ImageSource`), 3.2 (`ImagePreprocessor`), 2.3 (form de abastecimento), 2.1 (`FuelEntrySaver`).
> **Decisão estratégica**: adia a Edge Function real (3.1). Usamos `MockScanService` que devolve JSON fake. Quando 3.1 estiver pronta, troca-se a impl do provider e o fluxo continua funcionando sem mudança de UI.

## Escopo
- `ScannedReceipt` (modelo do que a IA extrai — todos os campos **nullable** porque IA pode falhar em campo individual).
- `ScanService` (interface) + `MockScanService` (devolve dados fake realistas) + `RealScanService` placeholder lançando `UnimplementedError('Sprint 3.1')`.
- `ScanController` (Riverpod Notifier) orquestra: captura → preprocess → scan → estado.
- Integração no `FuelEntryFormScreen`: botão **"Escanear cupom"** na AppBar; ao tocar → fluxo de scan → pré-preenche os campos → usuário **revisa** → salva normal (`source = ai_scan`).
- Atualização do `FuelEntrySaver.create` pra aceitar `source` opcional (default `manual`).

Fora de escopo: Edge Function real (3.1), cota (3.5), OCR de odômetro (3.4).

## Regras de Ouro relevantes (não-negociáveis)

- **#3**: scan **nunca** salva cego — IA pré-preenche, usuário revisa e confirma.
- **#3b**: fallback manual é o caminho base — qualquer campo pode ser editado depois do scan; usuário pode também ignorar o scan e digitar do zero.
- **#10**: pipeline recebe **bytes**, não conhece a câmera (já garantido pela `ImageSource` da 3.0).

## Decisões técnicas

### 1. Modelo `ScannedReceipt`
`lib/features/scan/scanned_receipt.dart` — freezed (consistência com os outros models):
```dart
@freezed
abstract class ScannedReceipt with _$ScannedReceipt {
  const factory ScannedReceipt({
    Decimal? liters,
    Decimal? pricePerLiter,
    Decimal? totalCost,
    DateTime? date,
    FuelType? fuelType,
  }) = _ScannedReceipt;
  factory ScannedReceipt.fromJson(Map<String, dynamic> json) =>
      _$ScannedReceiptFromJson(json);
}
```
Todos os campos nullable. Usa os mesmos converters de Decimal/enum da 0.3. Build com `build_runner`.

### 2. `ScanService` (interface + mock + placeholder real)
`lib/features/scan/scan_service.dart`:
```dart
abstract class ScanService {
  /// Extrai dados estruturados de uma imagem de cupom.
  /// Lança [ScanException] em erro real. Cancelamento não passa por aqui
  /// (é tratado upstream em quem chama o ImageSource).
  Future<ScannedReceipt> scan(Uint8List imageBytes);
}

class ScanException implements Exception {
  ScanException(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => 'ScanException: $message';
}
```

`MockScanService implements ScanService`:
- Aceita opcional `Duration delay` (default 800ms — pra UX de loading não-instantânea).
- Aceita `ScannedReceipt? fixedResult` (override pra testes).
- Aceita `bool throwOnCall` (override pra testes).
- Default real return: `ScannedReceipt(liters: Decimal.parse('42.5'), pricePerLiter: Decimal.parse('5.79'), totalCost: Decimal.parse('246.07'), date: DateTime.now(), fuelType: FuelType.gasolina)`.

`RealScanService implements ScanService`: stub que lança `UnimplementedError('Real scan service vem na Sprint 3.1')`.

Provider `scanServiceProvider`: **retorna `MockScanService()` por enquanto** (com comentário TODO referenciando 3.1).

### 3. `ScanController` (Notifier)
`lib/features/scan/scan_controller.dart`:
```dart
sealed class ScanState {
  const ScanState();
}
class ScanIdle extends ScanState { const ScanIdle(); }
class ScanInProgress extends ScanState { const ScanInProgress(); }
class ScanSuccess extends ScanState {
  const ScanSuccess(this.receipt);
  final ScannedReceipt receipt;
}
class ScanError extends ScanState {
  const ScanError(this.message);
  final String message;
}

class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanIdle();

  /// Executa o fluxo completo:
  ///   1. captura via [ImageSource] (origem default câmera)
  ///   2. valida tamanho via [ImagePreprocessor]
  ///   3. envia pro [ScanService]
  /// Retorna o [ScannedReceipt] em sucesso, OU `null` em cancelamento, OU
  /// publica [ScanError] no state e retorna `null` em erro.
  /// NUNCA lança — o caller (form) só observa o state ou o retorno.
  Future<ScannedReceipt?> scanFromCamera();
}
```

Reads `imageSourceProvider`, `imagePreprocessorProvider`, `scanServiceProvider`.

Transições:
- Início → `ScanInProgress`.
- Captura `null` (cancelado) → volta pra `ScanIdle`, retorna `null`. (Sem erro.)
- Imagem maior que limite → `ScanError('A imagem ficou grande demais. Tente novamente com menos zoom.')`, retorna `null`.
- `ScanService` lança → `ScanError('Não foi possível ler o cupom. Tente de novo ou preencha manualmente.')`, retorna `null`.
- Sucesso → `ScanSuccess(receipt)`, retorna `receipt`.

Provider `scanControllerProvider = NotifierProvider<ScanController, ScanState>(ScanController.new);`

### 4. `FuelEntrySaver.create` ganha `source`
Adicionar parâmetro opcional `FuelSource source = FuelSource.manual` em `create`. `update` continua preservando `source` do existing.

### 5. Form: botão "Escanear cupom"
`FuelEntryFormScreen` (`lib/features/fuel/fuel_entry_form_screen.dart`):
- AppBar `actions`: `IconButton(icon: Icon(Icons.document_scanner), tooltip: 'Escanear cupom', onPressed: _scan)`.
- `_scan()`: chama `ref.read(scanControllerProvider.notifier).scanFromCamera()`.
  - Durante `ScanInProgress`: AppBar mostra `CircularProgressIndicator` no lugar do ícone.
  - `ScanSuccess(receipt)`: pré-preenche os campos do form (litros, preço, total auto-recalcula, data, tipo de combustível); marca `_scannedFromCamera = true`; mostra um `MaterialBanner` PT-BR: **"Dados extraídos do cupom. Revise antes de salvar."** com botão "OK".
  - `ScanError(msg)`: `SnackBar` com `msg` (PT-BR — vem do controller). Form fica como estava.
  - Cancelado: nada (UX silenciosa).
- No `_submit`, se `_scannedFromCamera == true`, passa `source: FuelSource.aiScan` pro saver. Caso contrário, default `manual`.
- **Fallback manual sempre**: usuário pode editar qualquer campo após o scan, e pode salvar sem nunca ter escaneado.

## Critérios de aceite

**`test/features/scan/scanned_receipt_test.dart`**:
1. Construção com todos os campos nulos: ok.
2. `toJson` / `fromJson` roundtrip preserva Decimal exato (`liters=43.219`, etc.) e enum por wire (`fuel_type: gasolina`).
3. JSON snake_case (`price_per_liter`, `fuel_type`).

**`test/features/scan/mock_scan_service_test.dart`**:
4. Sem config: devolve `ScannedReceipt` com `liters`, `pricePerLiter`, `totalCost`, `date`, `fuelType` não-nulos.
5. `fixedResult` é honrado.
6. `throwOnCall` lança `ScanException`.

**`test/features/scan/scan_controller_test.dart`** (com fakes pra `ImageSource`, `ImagePreprocessor`, `ScanService`):
7. **Sucesso**: state vai `idle → inProgress → success(receipt)`; retorno é o receipt; `scanService.scan` chamado com os bytes corretos.
8. **Cancelado** (image source retorna null): state termina em `idle`; retorno `null`; scan service NÃO foi chamado.
9. **Imagem grande demais**: state termina em `error` com mensagem PT-BR amigável; retorno `null`.
10. **ScanService lança**: state termina em `error` com mensagem PT-BR amigável; retorno `null`.
11. **NUNCA lança**: mesmo se algum provider lançar inesperado, `scanFromCamera` captura e devolve `null` com state `error`.

**`test/features/fuel/fuel_entry_saver_source_test.dart`** (novo arquivo pra não conflitar com os 4 testes existentes do saver):
12. `create` com `source: FuelSource.aiScan` repassa o source corretamente pro `repo.create` (verificando no fake).
13. `create` sem `source` usa `FuelSource.manual` (default — comportamento original).

**Deliverables (Haiku + homologação visual):**
14. Botão "Escanear cupom" na AppBar do form; loading; banner PT-BR de revisão; pré-preenchimento; `source = ai_scan` quando salvar com origem scan.

## Definition of Done
- ~13 testes verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Sem nova dependência (freezed + json_serializable + uuid + intl + image_picker já temos).
- `scanServiceProvider` aponta pro `MockScanService` com TODO de troca pelo real na 3.1.
- Nenhum salvamento cego — scan **sempre** abre o form pra revisão.

# Sprint 6.K — Scan CRLV

> Onda 1, sprint 4/5. Mesmo padrão do 6.F (scan de despesa), agora pro documento
> de licenciamento (CRLV-e PDF ou foto do CRLV físico).

## Decisões já tomadas
- **Cota compartilhada** `scan_count` (mesma usada pelo `scan-receipt` e `scan-expense`).
- **PDF + foto** aceitos. Anthropic suporta `image/*` e `application/pdf` via API messages.
- **Pipeline confirmatório** (Regra de Ouro #3): IA extrai → form pré-preenchido → user confirma.
- **Fallback manual** preservado (Regra #3b).

## Mudanças

### 1. Novo modelo `ScannedCrlv` (`lib/features/scan/scanned_crlv.dart`)
```dart
@freezed
abstract class ScannedCrlv with _$ScannedCrlv {
  const factory ScannedCrlv({
    String? plate,       // ABC1D23 (Mercosul) ou ABC1234 (antigo)
    String? renavam,     // ~11 dígitos
    String? chassi,      // VIN 17 chars
    String? color,       // texto livre
    @FuelTypeNullableConverter() FuelType? fuelType,
    String? make,
    String? model,
    int? year,           // ano de fabricação
  }) = _ScannedCrlv;
  factory ScannedCrlv.fromJson(Map<String, dynamic> json) =>
      _$ScannedCrlvFromJson(json);
}
```
Precisa `FuelTypeNullableConverter` em `json_converters.dart` (defensivo, igual ao `ExpenseCategoryNullableConverter` do 6.F):
```dart
class FuelTypeNullableConverter implements JsonConverter<FuelType?, String?> {
  const FuelTypeNullableConverter();
  @override
  FuelType? fromJson(String? json) {
    if (json == null) return null;
    try { return FuelType.fromWire(json); } catch (_) { return null; }
  }
  @override
  String? toJson(FuelType? object) => object?.wire;
}
```

### 2. Novo serviço `CrlvScanService` (`lib/features/scan/crlv_scan_service.dart`)

Espelho exato de `ExpenseScanService`, com 2 diferenças:
- Aceita `Uint8List bytes` E `String mimeType` (ex: `'image/jpeg'`, `'application/pdf'`).
- Função invocada: `'scan-crlv'`.

```dart
abstract class CrlvScanService {
  Future<ScannedCrlv> scan(Uint8List bytes, {required String mimeType});
}

class RealCrlvScanService implements CrlvScanService {
  RealCrlvScanService(this._invoker);
  final EdgeFunctionInvoker _invoker;

  @override
  Future<ScannedCrlv> scan(Uint8List bytes, {required String mimeType}) async {
    final encoded = base64Encode(bytes);
    try {
      final body = await _invoker.invoke('scan-crlv', {
        'document_base64': encoded,
        'mime_type': mimeType,
      });
      return ScannedCrlv.fromJson(body);
    } on QuotaExhaustedException { rethrow; }
    on ScanException { rethrow; }
    catch (e) {
      throw ScanException('Falha ao escanear CRLV', cause: e);
    }
  }
}

class MockCrlvScanService implements CrlvScanService {
  MockCrlvScanService({ this.delay = const Duration(milliseconds: 800),
                        this.fixedResult, this.throwOnCall = false });
  final Duration delay;
  final ScannedCrlv? fixedResult;
  final bool throwOnCall;
  int callCount = 0;

  static final _default = ScannedCrlv(
    make: 'Honda',
    model: 'CIVIC LX 1.7',
    year: 2018,
    plate: 'ABC1D23',
    color: 'preto',
    fuelType: FuelType.flex,
  );

  @override
  Future<ScannedCrlv> scan(Uint8List bytes, {required String mimeType}) async {
    callCount++;
    await Future<void>.delayed(delay);
    if (throwOnCall) throw ScanException('Erro simulado por MockCrlvScanService');
    return fixedResult ?? _default;
  }
}

final crlvScanServiceProvider = Provider<CrlvScanService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealCrlvScanService(SupabaseEdgeFunctionInvoker(client));
});
```

### 3. Edge function `supabase/functions/scan-crlv/index.ts`

Espelho de `scan-expense/index.ts` com diferenças:

- **Body**: `{ document_base64: string, mime_type: string }`. Valida `mime_type ∈ {'image/jpeg','image/png','image/heic','application/pdf'}`. 400 se inválido.
- **Cota**: mesma `scan_count` (compartilhada com receipt/expense).
- **Mensagem Anthropic** condicional ao mime_type:
  - Image: usa `type: 'image'` (como o scan-expense).
  - PDF: usa `type: 'document', source: { type: 'base64', media_type: 'application/pdf', data: ... }`.
- **Prompt**:
  ```
  Você extrai dados do CRLV-e (Certificado de Registro e Licenciamento do Veículo)
  brasileiro. Responda APENAS com JSON válido, sem markdown.
  Schema: {
    "plate": string|null, "renavam": string|null, "chassi": string|null,
    "color": string|null, "fuel_type": string|null,
    "make": string|null, "model": string|null, "year": number|null
  }
  Normalize:
  - plate: maiúsculas, sem espaço, sem hífen. Aceita formato ABC1D23 (Mercosul) ou ABC1234.
  - renavam: só dígitos.
  - chassi: 17 caracteres alfanuméricos maiúsculos, sem espaço.
  - fuel_type: um de "gasolina","etanol","diesel","flex","gnv". Se "ÁLCOOL" → "etanol". Mapeie o que conseguir; null se incerto.
  - year: ano de fabricação (não modelo). Inteiro.
  Se um campo não for legível, use null. Nunca invente.
  ```
- **Validadores** server-side: `toPlateOrNull`, `toRenavamOrNull` (só dígitos, 9-11 chars), `toChassiOrNull` (alfanumérico, 17 chars), `toFuelTypeOrNull` (mesmo do scan-receipt — copia), `toYearOrNull` (int 1900..currentYear+1).
- **Incrementa cota** se ao menos uma de `plate`, `chassi` ou (`make` + `model`) vierem não-null. Ou seja, se foi útil.
- **Response shape** compatível com `ScannedCrlv.fromJson`.

### 4. UI — Form ganha 3º botão
`lib/features/vehicles/vehicle_form_screen.dart`

Logo abaixo do botão "Buscar na FIPE" (6.I), adicionar **"Escanear CRLV"** com `Icons.document_scanner` (ou `Icons.upload_file`). Mesma largura. Apresentação visual: 2 botões lado a lado (Row + Expanded) economiza espaço, mas pode ficar apertado — decisão UX: empilhados, cada um full-width, sem prejuízo de cliques.

Tap → mostra `ScanSourceSheet` adaptada (a do 6.F só tem câmera/galeria; pra CRLV adicionar opção "Arquivo PDF"):

```dart
enum ScanSource { camera, gallery, file }
```

Implementação:
- `camera` e `gallery` → `image_picker` (já em uso).
- `file` → `file_picker` (nova dependência, FilePicker; aceita `['pdf','jpg','png']`).

Pipeline:
1. Source escolhida → bytes + mimeType (do MIME-detect ou da extensão).
2. **Imagens** passam pelo `ImagePreprocessor` (resize 1280, q80). **PDFs** vão raw (Anthropic aceita até 32MB).
3. Chama `crlvScanServiceProvider.scan(bytes, mimeType: mt)`.
4. Aplica resultado preenchendo controllers (plate/make/model/year/color/fuelType) com highlight verde fading (reuso do TweenAnimationBuilder do FIPE).
5. **`renavam` e `chassi`** são novos campos no form (ver §5).

Tratamento de erros mesmo do scan-expense.

### 5. Form ganha 2 campos novos: RENAVAM e Chassi
`lib/features/vehicles/vehicle_form_screen.dart`

Adicionar na seção "Detalhes do veículo" (após `plate`):
- **RENAVAM** (TextField texto numérico, opcional, 9-11 dígitos).
- **Chassi** (TextField texto alfanumérico, opcional, exatos 17 chars).

Validators:
```dart
String? validateRenavam(String? raw); // opcional; só dígitos; 9..11
String? validateChassi(String? raw);  // opcional; alfanumérico; exatos 17
```

E no `Vehicle` model, adicionar:
```dart
String? renavam,
String? chassi,
```

Drift table + schema v6 + migration v5→v6 + Supabase migration 0006.

### 6. `file_picker` package
`pubspec.yaml`: `file_picker: ^8.0.0`.

## Testes (todos RED até implementação)

### `test/features/scan/scanned_crlv_test.dart` (novo)
- Parse JSON completo → modelo populado.
- Campos null individuais.
- JSON vazio → tudo null.
- Chaves extras ignoradas.
- `fuel_type` desconhecido → null (defensivo).
- Roundtrip `toJson` → `fromJson`.

### `test/features/scan/crlv_scan_service_test.dart` (novo)
- Invoca `scan-crlv` com `document_base64` + `mime_type`.
- Retorna `ScannedCrlv` parseado.
- 429 → `QuotaExhaustedException`.
- Erro genérico → `ScanException` com "CRLV" na mensagem.
- Mock: callCount, fixedResult, throwOnCall.

### `test/features/vehicles/vehicle_form_validators_test.dart` (adicionar)
- `validateRenavam`: vazio→null; "abc"→erro; "1234"→erro (curto); "12345678901"→null; "0000000000"→null.
- `validateChassi`: vazio→null; "abc"→erro (curto); 17 alfanum maiúsculo→null; 17 com espaço/hífen→erro.

### `test/data/local/vehicle_schema_v6_test.dart` (novo)
- `schemaVersion == 6`.
- Insert+read preserva renavam/chassi.
- Migration v5→v6 adiciona 2 colunas.

## Critérios de aceite
- [ ] Todos testes verdes (465+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Form tem 3 botões no topo: FIPE / CRLV / (manual implícito sem botão)
- [ ] Source sheet aceita câmera/galeria/arquivo
- [ ] PDF de CRLV-e processa corretamente (testar manualmente)

## Não-objetivos
- Validação geográfica (placa vs UF, RENAVAM vs Detran).
- Sincronização automática com Detran (rejeitado anteriormente).
- Detecção de fraude/adulteração no documento (pós-MVP).

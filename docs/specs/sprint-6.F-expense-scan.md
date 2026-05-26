# Sprint 6.F — Scan de despesa

> Generaliza o pipeline de scan: do hoje "só cupom de combustível" pra
> "qualquer comprovante de despesa". Espelha o padrão existente em vez de
> refatorar o `RealScanService` (zero risco no fluxo já em produção).

## Pré-requisitos
- Sprint 3.x — scan de combustível ✅ (referência)
- Sprint 6.E — vehicle expandido ✅ (não bloqueia, mas insights futuros dependem)

## Decisões já tomadas (com o Diretor)
- **Cota compartilhada** com scan de combustível (`scan_count` no `usage_quota`). Limite continua 5/mês free.
- **Pipeline confirmatório**: foto → IA → form pré-preenchido → user **confirma** (Regra de Ouro #3).
- **Fallback manual continua sendo o caminho base** (Regra de Ouro #3b) — botão de scan é atalho opcional.

## Mudanças

### 1. Enum (`lib/domain/models/enums.dart`)
Adicionar `licenciamento('licenciamento')` em `ExpenseCategory` (entre `ipva` e `outro`).

### 2. Novo modelo `ScannedExpense` (`lib/features/scan/scanned_expense.dart`)
```dart
@freezed
abstract class ScannedExpense with _$ScannedExpense {
  const factory ScannedExpense({
    @DecimalJsonConverter() Decimal? amount,
    DateTime? date,
    @ExpenseCategoryNullableConverter() ExpenseCategory? category,
    String? description,
    String? documentType, // 'cupom' | 'boleto' | 'nfe' | 'outro' | null
  }) = _ScannedExpense;
  factory ScannedExpense.fromJson(Map<String, dynamic> json) =>
      _$ScannedExpenseFromJson(json);
}
```
Precisa de um `ExpenseCategoryNullableConverter` em `json_converters.dart` que devolve `null` para qualquer string desconhecida (defensivo, igual ao `toFuelTypeOrNull` da edge fn).

### 3. Novo serviço `ExpenseScanService` (`lib/features/scan/expense_scan_service.dart`)
Espelho exato de `RealScanService` trocando o `functionName` e o tipo retornado:
```dart
abstract class ExpenseScanService {
  Future<ScannedExpense> scan(Uint8List imageBytes);
}

class RealExpenseScanService implements ExpenseScanService {
  RealExpenseScanService(this._invoker);
  final EdgeFunctionInvoker _invoker;

  @override
  Future<ScannedExpense> scan(Uint8List imageBytes) async {
    final encoded = base64Encode(imageBytes);
    try {
      final body = await _invoker.invoke('scan-expense', {
        'image_base64': encoded,
      });
      return ScannedExpense.fromJson(body);
    } on QuotaExhaustedException { rethrow; }
    on ScanException { rethrow; }
    catch (e) { throw ScanException('Falha ao escanear comprovante', cause: e); }
  }
}

class MockExpenseScanService implements ExpenseScanService { ... }

final expenseScanServiceProvider = Provider<ExpenseScanService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RealExpenseScanService(SupabaseEdgeFunctionInvoker(client));
});
```
Reusa `EdgeFunctionInvoker`, `QuotaExhaustedException`, `ScanException` — sem duplicação.

### 4. Edge function `supabase/functions/scan-expense/index.ts`
Espelho de `scan-receipt/index.ts` com 3 diferenças:
- **Prompt** novo (categorias canônicas BR):
  ```
  Você extrai dados de comprovantes de despesa veicular brasileiros
  (cupom fiscal, boleto IPVA/licenciamento, nota de serviço de manutenção,
  recibo de lavagem, multa, etc).
  Responda APENAS com JSON válido, sem markdown.
  Schema: {
    "amount": number|null,
    "date": "YYYY-MM-DD"|null,
    "category": string|null,
    "description": string|null,
    "document_type": string|null
  }
  category deve ser um de: "manutencao", "lavagem", "estacionamento",
    "multa", "seguro", "ipva", "licenciamento", "outro".
  document_type deve ser um de: "cupom", "boleto", "nfe", "outro".
  Se um campo não for legível, use null. Nunca invente valores.
  ```
- **Validação `toCategoryOrNull`** com a lista canônica acima.
- **Validação `toDocTypeOrNull`** com `["cupom","boleto","nfe","outro"]`.
- **Resposta** com chaves `amount`, `date`, `category`, `description`, `document_type`.
- **Incremento de cota**: só se `amount !== null` (mínimo útil — o resto pode ficar null e a UX ainda é boa).

Cota compartilhada com `scan-receipt`: mesma tabela `usage_quota`, mesma lógica de bump (`scan_count + 1`), mesmo limite `5` pra free.

### 5. UI — `ExpenseFormScreen`
Adicionar botão "Escanear comprovante" no topo do form (espelha o pattern usado no fuel). Ao tocar:
1. Mostra `SourceChoiceSheet` (câmera/galeria) — reusa o do scan de combustível.
2. Pré-processa via `ImagePreprocessor` (1280px/q80) — reusa.
3. Chama `ExpenseScanService.scan(bytes)`.
4. Se sucesso: pré-preenche os campos `amount`, `date`, `category`, `description` no form. Mostra snackbar "Confira e salve" (Regra #3).
5. Se `QuotaExhaustedException`: mensagem PT-BR "Cota mensal de scans esgotada — vire premium ou preencha manual". Form continua editável.
6. Se outra `ScanException`: snackbar "Não conseguimos ler o comprovante. Tente outra foto ou preencha manual." Form continua editável.

Estados de loading isolados (CTAs do form desabilitados durante scan).

## Testes

### `test/features/scan/scanned_expense_test.dart` (novo)
- Parse JSON completo → modelo populado.
- Campos null individuais → modelo com nulls.
- Categoria desconhecida → `category = null` (defensivo via converter).
- Document type desconhecido → `documentType = null`.
- JSON com chaves a mais → ignora silenciosamente.

### `test/features/scan/expense_scan_service_test.dart` (novo)
- Chama `_invoker.invoke('scan-expense', {image_base64})`.
- Retorna `ScannedExpense` com base no fake invoker.
- 429 → propaga `QuotaExhaustedException`.
- Erro genérico → lança `ScanException`.
- Mock service: callCount, fixedResult, throwOnCall, delay.

### Não-testes (out of scope local)
- Edge function Deno (não tem suite Dart) — testar manual via Supabase CLI ou homologação.
- Widget test do form com scan integrado — fica pra Sprint 7.

## Critérios de aceite
- [ ] Todos testes verdes (355+ existentes + novos)
- [ ] `flutter analyze` limpo
- [ ] iOS sim builds
- [ ] Botão "Escanear comprovante" aparece no `ExpenseFormScreen` e usa o pipeline completo
- [ ] Cota compartilhada respeitada (mesma `scan_count`)

## Não-objetivos
- Refatorar `RealScanService` (mantém intocado).
- Detector visual de "tipo de documento" automático na UI (Sprint futura).
- Análise por veículo (Sprint 6.G).

# Spec — Sprint 3.1: Edge Function de scan (Claude Haiku 4.5) + RealScanService

> Papel: **Opus (especificação + TDD)**. Sonnet implementa; Haiku revisa; André faz deploy do CLI e homologa.
> Fonte: `docs/ARCHITECTURE.md §5, §6` (pipeline de scan + economia) + Regras de Ouro #4 (chave nunca toca app) e #5 (cota no backend).
> Substitui o `MockScanService` da 3.3 pela impl real, sem mudar a UI.

## Escopo
- **Edge Function** `supabase/functions/scan-receipt/index.ts` (Deno/TypeScript) que:
  1. Identifica o usuário via JWT do header `Authorization`.
  2. Checa cota mensal em `usage_quota` (free: 5/mês; premium: ilimitado).
  3. Chama Claude Haiku 4.5 com a imagem + prompt estrito.
  4. Parseia o JSON da resposta de forma defensiva (nunca confia).
  5. Incrementa `scan_count` apenas em **sucesso** (resposta válida).
  6. Devolve o JSON estruturado pro cliente.
- **`RealScanService`** Dart que invoca a função via `supabase.functions.invoke`.
- **`QuotaExhaustedException`** (subtipo de `ScanException`) pra 3.5 detectar.
- Provider passa a retornar `RealScanService` (Mock fica pra testes via override).

Fora de escopo: UI de paywall (3.5).

## Decisões técnicas

### 1. Auth + isolamento
Edge Function roda com `verify_jwt = true` (default). O JWT do usuário chega no header. Dentro da função:
- Cria cliente Supabase com **`SUPABASE_SERVICE_ROLE_KEY`** (auto-injetada — bypassa RLS pra escrita atômica de cota).
- Extrai `user_id` decodificando o JWT (`supabase.auth.getUser(jwt)`).
- Erro de auth → 401.

### 2. Algoritmo da cota (compatível com `usage_quota` da 0.4)
A tabela tem 1 linha por usuário com `month` (YYYY-MM), `scan_count`, `is_premium`. Quando o mês rola, resetamos o count.

```ts
const currentMonth = new Date().toISOString().slice(0, 7); // "2026-05"
const { data: quotaRow } = await supabase
  .from('usage_quota')
  .select('*').eq('user_id', userId).maybeSingle();

const isPremium = quotaRow?.is_premium ?? false;
const effectiveCount = (quotaRow?.month === currentMonth) ? quotaRow.scan_count : 0;

if (!isPremium && effectiveCount >= 5) {
  return json({ error: 'quota_exhausted' }, 429);
}
```

Após sucesso (Claude respondeu JSON válido):
```ts
await supabase.from('usage_quota').upsert({
  user_id: userId,
  month: currentMonth,
  scan_count: effectiveCount + 1,
  is_premium: isPremium,
});
```

### 3. Chamada ao Claude Haiku 4.5
- Endpoint: `https://api.anthropic.com/v1/messages`.
- Header `x-api-key: Deno.env.get('ANTHROPIC_API_KEY')`.
- Header `anthropic-version: 2023-06-01`.
- Body: `model: 'claude-haiku-4-5'`, `max_tokens: 512`, `messages: [{role: 'user', content: [{type: 'image', source: {type: 'base64', media_type: 'image/jpeg', data: <base64>}}, {type: 'text', text: PROMPT}]}]`.
- PROMPT (ARCHITECTURE §5):
  ```
  Você extrai dados de cupons fiscais de postos de combustível brasileiros.
  Responda APENAS com JSON válido, sem markdown, sem explicação.
  Schema: {"liters": number|null, "price_per_liter": number|null, "total": number|null, "date": "YYYY-MM-DD"|null, "fuel_type": string|null}
  Se um campo não for legível, use null. Nunca invente valores.
  fuel_type deve ser um de: "gasolina", "etanol", "diesel", "flex", "gnv".
  ```

### 4. Parse defensivo
- Se Claude responder com markdown (` ```json {...} ``` `), strip do markdown antes de `JSON.parse`.
- Se `JSON.parse` falhar → log + retorna `{}` (todos os campos null, cliente trata como "scan ruim, preencha manual").
- Validar tipos:
  - `liters`, `price_per_liter`, `total`: aceitar number → converter pra string (Decimal-as-string no contrato com o app).
  - `date`: validar `/^\d{4}-\d{2}-\d{2}$/`.
  - `fuel_type`: validar contra os 5 valores; caso contrário null.
- **Nunca lança exceção que retorne 500** — qualquer parse ruim vira ScannedReceipt vazia (campos null), o usuário preenche manual e ainda assim a cota **NÃO** incrementa (porque não foi sucesso útil — alternativa: pode-se argumentar que o custo já foi gasto; vou contar SEMPRE que Claude respondeu, mesmo que tenha sido nulo. Decisão: **incrementa só se pelo menos `liters` E `price_per_liter` vierem não-nulos** — alinha cobrança da cota com valor entregue ao usuário).

### 5. Response shape (contrato com o app)
```json
{
  "liters": "43.219" | null,
  "price_per_liter": "5.799" | null,
  "total_cost": "250.626981" | null,
  "date": "2026-05-23" | null,
  "fuel_type": "gasolina" | null
}
```
Note: `total_cost` no JSON (snake_case), bate com o `ScannedReceipt.toJson` do app. Decimais como **string** (precisão).

Erro de cota: status 429, body `{"error": "quota_exhausted"}`.

### 6. Lado Dart: abstração `EdgeFunctionInvoker` (testável)
`lib/features/scan/edge_function_invoker.dart`:
```dart
abstract class EdgeFunctionInvoker {
  /// Retorna o JSON body. Lança [QuotaExhaustedException] em 429 com
  /// {"error":"quota_exhausted"}. Outras falhas viram [ScanException].
  Future<Map<String, dynamic>> invoke(String functionName, Map<String, dynamic> body);
}
```
- Impl real `SupabaseEdgeFunctionInvoker(SupabaseClient client)`: chama `client.functions.invoke(name, body: body)`; mapeia status/erro.
- Fake `_FakeEdgeFunctionInvoker` nos testes do `RealScanService`.

### 7. `RealScanService implements ScanService`
`lib/features/scan/scan_service.dart` (substitui o stub):
```dart
class RealScanService implements ScanService {
  RealScanService(this._invoker);
  final EdgeFunctionInvoker _invoker;
  @override
  Future<ScannedReceipt> scan(Uint8List imageBytes) async {
    final base64 = base64Encode(imageBytes);
    try {
      final body = await _invoker.invoke('scan-receipt', {'image_base64': base64});
      return ScannedReceipt.fromJson(body);
    } on QuotaExhaustedException {
      rethrow; // a UI/form decide o que fazer (3.5)
    } on ScanException {
      rethrow;
    } catch (e) {
      throw ScanException('Falha inesperada ao escanear cupom', cause: e);
    }
  }
}

class QuotaExhaustedException extends ScanException {
  QuotaExhaustedException() : super('Cota de scan esgotada — vire premium ou siga manual');
}
```

### 8. Provider switch
`scanServiceProvider` muda pra retornar `RealScanService(SupabaseEdgeFunctionInvoker(ref.watch(supabaseClientProvider)))`. Comentário marca que o `MockScanService` continua existindo só pra ser injetado em testes via override.

## Critérios de aceite

**`test/features/scan/real_scan_service_test.dart`** (usando `_FakeInvoker` mockando o Edge Function):

1. **Sucesso**: invoker retorna JSON válido (liters/price/total/date/fuel_type) → `scan()` retorna `ScannedReceipt` correspondente; bytes foram base64-encodados na chave `image_base64` da body.
2. **JSON parcial**: invoker retorna `{}` (todos null) → `scan()` retorna `ScannedReceipt()` (todos null), não lança.
3. **Quota esgotada**: invoker lança `QuotaExhaustedException` → `scan()` propaga (rethrow), preservando o tipo.
4. **Erro de rede / ScanException genérico**: invoker lança `ScanException('rede')` → propaga.
5. **Erro inesperado** (Exception qualquer): invoker lança Exception desconhecida → `scan()` embrulha em `ScanException` com `cause` preservado.

**`test/features/scan/supabase_edge_function_invoker_test.dart`** (skip ou minimal — depende de mockability do `SupabaseClient`):
- Se viável: 429 → `QuotaExhaustedException`. Outros 4xx/5xx → `ScanException`. Sucesso → body devolvido.
- Se inviável: classe revisada por Haiku, validada por André no homologa.

**Deliverable (deploy + homologação):**
6. Edge Function deployada com `supabase functions deploy scan-receipt --no-verify-jwt false`.
7. Smoke test contra projeto real:
   - Logado, tirar foto de cupom → recebe JSON → form pré-preenche → user confirma → salva com `source = ai_scan`.
   - Tabela `usage_quota` no Supabase mostra `scan_count` incrementado.
   - 6ª chamada do mês (free) → 429 → toast "Cota esgotada" (3.5 polirá UX).

## Definition of Done
- 5 testes do `RealScanService` verdes; suíte completa verde; `dart format`; `flutter analyze` limpo.
- `flutter build ios --simulator --debug --dart-define-from-file=dart_define.json` passa.
- Edge Function escrita em `supabase/functions/scan-receipt/index.ts` — revisada por Haiku (TypeScript, não roda em flutter test); deploy = André.
- Provider `scanServiceProvider` agora retorna `RealScanService`.
- **Zero menção** à chave Anthropic no código Dart (vive só na Edge Function via env).
- Quota incrementa **só** quando Claude entrega valor útil (liters + price não-nulos).

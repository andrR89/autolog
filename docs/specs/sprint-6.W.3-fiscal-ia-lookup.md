# Sprint 6.W.3 — Fiscal por IA (lookup com fallback hardcoded)

> Substitui o jogo de adivinhar 27 UFs por consulta IA contextual. Cada
> erro reportado virava patch manual — agora deixa a IA pesquisar e
> mantém hardcoded só como fallback offline.

## Decisões
- Edge fn nova `fiscal-calendar-lookup`. Body: `{uf, plate_last_digit, year}`.
- Haiku 4.5 com prompt instruindo pesquisa SEFAZ/Detran + citar fonte.
- Cota compartilhada `chat_count` (já provisionada — 10/mês free, ilimitado premium).
- Cache local 90 dias em nova tabela `fiscal_lookup_cache`.
- Fallback: se IA falhar/quota/network → usa `brFiscalCalendar` hardcoded atual.
- UI mostra "fonte: IA / fonte: estimativa local" pra dar transparência.

## Mudanças

### 1. Schema v11 — `fiscal_lookup_cache` (local-only)
`lib/data/local/tables.dart`:
```dart
@DataClassName('FiscalLookupCacheRow')
class FiscalLookupCache extends Table {
  TextColumn get cacheKey => text()(); // "UF-digit-year" ex "SC-6-2026"
  TextColumn get value => text()();    // JSON serializado
  DateTimeColumn get expiresAt => dateTime()();
  @override
  Set<Column> get primaryKey => {cacheKey};
}
```

Bump `schemaVersion` 10 → 11. `if (from < 11) { await m.createTable(fiscalLookupCache); }`.

### 2. Modelo `FiscalLookupResult` (`lib/features/insights/fiscal_lookup_result.dart`)
```dart
@freezed
abstract class FiscalLookupResult with _$FiscalLookupResult {
  const factory FiscalLookupResult({
    required FiscalEntry ipva,
    required FiscalEntry licensing,
    required FiscalLookupSource source,
  }) = _FiscalLookupResult;
  factory FiscalLookupResult.fromJson(Map<String, dynamic> json) =>
      _$FiscalLookupResultFromJson(json);
}

@freezed
abstract class FiscalEntry with _$FiscalEntry {
  const factory FiscalEntry({
    required int month,      // 1..12
    int? day,                // null se desconhecido
    String? sourceCitation,  // ex: "SEFAZ-SP 2026"
  }) = _FiscalEntry;
  factory FiscalEntry.fromJson(Map<String, dynamic> json) =>
      _$FiscalEntryFromJson(json);
}

enum FiscalLookupSource { ai, localFallback, cache }
```

### 3. Service (`lib/features/insights/fiscal_lookup_service.dart`)
```dart
abstract class FiscalLookupService {
  Future<FiscalLookupResult> lookup({
    required String uf, required int plateLastDigit, required int year,
  });
}

class RealFiscalLookupService implements FiscalLookupService {
  RealFiscalLookupService(this._invoker, this._cache, this._fallback);
  final EdgeFunctionInvoker _invoker;
  final FiscalLookupCache _cache;
  final FallbackComputer _fallback;

  @override
  Future<FiscalLookupResult> lookup({...}) async {
    final key = '$uf-$plateLastDigit-$year';

    // 1) Cache hit válido
    final cached = await _cache.read(key);
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      return _parseWithSource(cached.value, FiscalLookupSource.cache);
    }

    // 2) IA
    try {
      final body = await _invoker.invoke('fiscal-calendar-lookup', {
        'uf': uf, 'plate_last_digit': plateLastDigit, 'year': year,
      });
      final result = FiscalLookupResult.fromJson(body);
      // persiste no cache (90 dias)
      await _cache.write(key, jsonEncode(body),
          DateTime.now().add(const Duration(days: 90)));
      return result;
    } on QuotaExhaustedException {
      return _fallback.compute(uf, plateLastDigit, year);
    } on ScanException {
      return _fallback.compute(uf, plateLastDigit, year);
    } catch (_) {
      return _fallback.compute(uf, plateLastDigit, year);
    }
  }
}

class MockFiscalLookupService implements FiscalLookupService { ... }
```

`FallbackComputer` envolve `brFiscalCalendar` atual e retorna
`FiscalLookupResult` com `source: localFallback`.

### 4. `FiscalLookupCache` abstract + Drift impl
`lib/data/local/fiscal_lookup_cache.dart` — espelha `FipeCacheStore`.

### 5. Edge fn `supabase/functions/fiscal-calendar-lookup/index.ts`
Espelha `infer-vehicle-specs`. Body `{uf, plate_last_digit, year}`.
Prompt:
```
Você é especialista em calendário fiscal automotivo brasileiro.
Para a UF [UF] no ano [year], qual o mês de vencimento típico do IPVA
e do licenciamento para um veículo com placa terminada em [digit]?

Responda APENAS com JSON, sem markdown:
{
  "ipva": {"month": int 1-12, "day": int|null, "source": string|null},
  "licensing": {"month": int 1-12, "day": int|null, "source": string|null}
}

Considere o calendário da SEFAZ/Detran do estado. Se a UF tem cota única
(mesmo mês para todas as placas), use esse mês. Caso contrário, use a
distribuição por final de placa do calendário oficial.

source: cite o órgão ("SEFAZ-SP", "Detran-RJ", etc) se souber. null se não.
```
Cota `chat_count` (10/mês free). Incrementa em sucesso.

### 6. UI — `FiscalPlanScreen`
- Substitui chamada direta a `suggestFiscalReminders` por chamada ao service.
- Mostra loading state durante lookup.
- Adiciona chip "fonte: IA · SEFAZ-SP" ou "fonte: estimativa local" abaixo de cada card.
- Cache hit é instantâneo — sem loading visível.

## Testes RED

- `test/features/insights/fiscal_lookup_result_test.dart` — parse defensivo do JSON.
- `test/features/insights/fiscal_lookup_service_test.dart` — pipeline (cache hit / IA / fallback em cada falha).
- `test/data/local/fiscal_lookup_cache_test.dart` — CRUD da tabela.
- `test/data/local/fiscal_lookup_schema_v11_test.dart` — schema bump + migration.

## Critérios
- Suite verde (775+ + ~25 novos)
- analyze 0, iOS build OK
- Migration `0010_chat_quota_seal.sql` N/A (sem schema servidor — fiscal_lookup_cache é local-only)
- Edge fn `fiscal-calendar-lookup` precisa deploy manual

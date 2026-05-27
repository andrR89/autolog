import 'dart:convert';

import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/local/fiscal_lookup_cache.dart';
import 'package:autolog/data/remote/supabase_client.dart';
import 'package:autolog/features/insights/fiscal_calendar.dart';
import 'package:autolog/features/insights/fiscal_lookup_result.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Contrato
// ---------------------------------------------------------------------------

abstract class FiscalLookupService {
  Future<FiscalLookupResult> lookup({
    required String uf,
    required int plateLastDigit,
    required int year,
  });
}

// ---------------------------------------------------------------------------
// FallbackComputer — envolve brFiscalCalendar
// ---------------------------------------------------------------------------

/// Computa o resultado de fallback usando o calendário hardcoded [brFiscalCalendar].
///
/// NUNCA lança — retorna `FiscalLookupResult(source: localFallback)` sempre.
class FallbackComputer {
  const FallbackComputer();

  FiscalLookupResult compute(String uf, int plateLastDigit, int year) {
    try {
      final ufUpper = uf.toUpperCase();
      final calendar =
          brFiscalCalendar.containsKey(ufUpper)
              ? brFiscalCalendar[ufUpper]!
              : _defaultCalendar;

      final ipvaMonth = calendar.ipva.monthFor(plateLastDigit);
      final licMonth = calendar.licensing.monthFor(plateLastDigit);

      return FiscalLookupResult(
        ipva: FiscalEntry(month: ipvaMonth),
        licensing: FiscalEntry(month: licMonth),
        source: FiscalLookupSource.localFallback,
      );
    } catch (_) {
      // Fallback absoluto — jamais propaga erro.
      return const FiscalLookupResult(
        ipva: FiscalEntry(month: 1),
        licensing: FiscalEntry(month: 6),
        source: FiscalLookupSource.localFallback,
      );
    }
  }
}

// Default calendar re-exposed for FallbackComputer (mirrors fiscal_calendar.dart's private).
const UfFiscalCalendar _defaultCalendar = UfFiscalCalendar(
  ipva: FiscalScheduleByDigit({
    0: 1,
    1: 1,
    2: 2,
    3: 2,
    4: 3,
    5: 3,
    6: 4,
    7: 4,
    8: 5,
    9: 5,
  }),
  licensing: FiscalScheduleByDigit({
    0: 6,
    1: 6,
    2: 7,
    3: 7,
    4: 8,
    5: 8,
    6: 9,
    7: 9,
    8: 10,
    9: 10,
  }),
);

// ---------------------------------------------------------------------------
// Implementação real
// ---------------------------------------------------------------------------

class RealFiscalLookupService implements FiscalLookupService {
  RealFiscalLookupService(this._invoker, this._cache, this._fallback);

  final EdgeFunctionInvoker _invoker;
  final FiscalLookupCache _cache;
  final FallbackComputer _fallback;

  static const _ttl = Duration(days: 90);

  @override
  Future<FiscalLookupResult> lookup({
    required String uf,
    required int plateLastDigit,
    required int year,
  }) async {
    final key = '$uf-$plateLastDigit-$year';

    // 1) Cache hit válido
    final cached = await _cache.read(key);
    if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
      try {
        final decoded = jsonDecode(cached.value) as Map<String, dynamic>;
        final r = FiscalLookupResult.fromJson(decoded);
        return r.copyWith(source: FiscalLookupSource.cache);
      } catch (_) {
        // Cache corrompido — prossegue para IA.
      }
    }

    // 2) IA (edge function)
    try {
      final body = await _invoker.invoke('fiscal-calendar-lookup', {
        'uf': uf,
        'plate_last_digit': plateLastDigit,
        'year': year,
      });
      final result = FiscalLookupResult.fromJson(body);
      // Persiste no cache (90 dias).
      await _cache.write(key, jsonEncode(body), DateTime.now().add(_ttl));
      return result.copyWith(source: FiscalLookupSource.ai);
    } on QuotaExhaustedException {
      return _fallback.compute(uf, plateLastDigit, year);
    } on ScanException {
      return _fallback.compute(uf, plateLastDigit, year);
    } catch (_) {
      return _fallback.compute(uf, plateLastDigit, year);
    }
  }
}

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

/// Implementação mock do [FiscalLookupService] para testes.
///
/// Por default retorna resultado de IA plausível para SC-6-2026.
/// Configurável para:
/// - retornar [fixedResult] personalizado;
/// - lançar [ScanException] via [throwOnCall];
/// - lançar [QuotaExhaustedException] via [throwQuota];
/// - simular latência via [delay].
class MockFiscalLookupService implements FiscalLookupService {
  MockFiscalLookupService({
    this.delay = Duration.zero,
    this.fixedResult,
    this.throwOnCall = false,
    this.throwQuota = false,
  });

  final Duration delay;
  final FiscalLookupResult? fixedResult;
  final bool throwOnCall;
  final bool throwQuota;

  int callCount = 0;

  static const _defaultResult = FiscalLookupResult(
    ipva: FiscalEntry(month: 6, sourceCitation: 'SEFAZ-SC'),
    licensing: FiscalEntry(month: 10),
    source: FiscalLookupSource.ai,
  );

  @override
  Future<FiscalLookupResult> lookup({
    required String uf,
    required int plateLastDigit,
    required int year,
  }) async {
    callCount++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (throwQuota) throw QuotaExhaustedException();
    if (throwOnCall) {
      throw ScanException('Erro simulado pelo MockFiscalLookupService');
    }
    return fixedResult ?? _defaultResult;
  }
}

// ---------------------------------------------------------------------------
// Providers Riverpod
// ---------------------------------------------------------------------------

/// Provider do [FiscalLookupCache] (Drift).
final fiscalLookupCacheProvider = Provider<FiscalLookupCache>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFiscalLookupCache(db);
});

/// Provider do [FallbackComputer].
final fallbackComputerProvider = Provider<FallbackComputer>((ref) {
  return const FallbackComputer();
});

/// Provider do [FiscalLookupService].
///
/// Em produção: [RealFiscalLookupService].
/// Em testes: `overrideWithValue(MockFiscalLookupService(...))`.
final fiscalLookupServiceProvider = Provider<FiscalLookupService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final cache = ref.watch(fiscalLookupCacheProvider);
  final fallback = ref.watch(fallbackComputerProvider);
  return RealFiscalLookupService(
    SupabaseEdgeFunctionInvoker(client),
    cache,
    fallback,
  );
});

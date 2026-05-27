import 'dart:convert';

import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/local/fiscal_lookup_cache.dart';
import 'package:autolog/features/insights/fiscal_lookup_result.dart';
import 'package:autolog/features/insights/fiscal_lookup_service.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.W.3 — FiscalLookupService: cache hit / IA / fallback.

// ---------------------------------------------------------------------------
// Fake EdgeFunctionInvoker
// ---------------------------------------------------------------------------

class _FakeInvoker {
  _FakeInvoker({this.result, this.throwQuota = false, this.throwScan = false});

  final Map<String, dynamic>? result;
  final bool throwQuota;
  final bool throwScan;
  int callCount = 0;

  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    callCount++;
    if (throwQuota) throw QuotaExhaustedException();
    if (throwScan) throw ScanException('fake error');
    if (result != null) return result!;
    throw ScanException('no result configured');
  }
}

// Adapter que implementa EdgeFunctionInvoker com _FakeInvoker.
class _AdapterInvoker implements EdgeFunctionInvoker {
  _AdapterInvoker(this._fake);
  final _FakeInvoker _fake;

  @override
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  ) =>
      _fake.invoke(functionName, body);
}


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _aiResponse({int ipvaMonth = 6, int licMonth = 10}) => {
      'ipva': {'month': ipvaMonth, 'day': null, 'source': 'SEFAZ-SC 2026'},
      'licensing': {
        'month': licMonth,
        'day': null,
        'source': 'Detran-SC',
      },
    };

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late DriftFiscalLookupCache cache;
  const fallback = FallbackComputer();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = DriftFiscalLookupCache(db);
  });

  tearDown(() => db.close());

  group('RealFiscalLookupService', () {
    test('cache hit válido — não chama IA', () async {
      // Pré-popula o cache com dado válido.
      const key = 'SC-6-2026';
      final body = _aiResponse();
      await cache.write(
        key,
        jsonEncode(body),
        DateTime.now().add(const Duration(days: 90)),
      );

      final fakeInvoker = _FakeInvoker(result: body);
      final service = RealFiscalLookupService(
        _AdapterInvoker(fakeInvoker),
        cache,
        fallback,
      );

      final result = await service.lookup(uf: 'SC', plateLastDigit: 6, year: 2026);

      expect(result.source, FiscalLookupSource.cache);
      expect(result.ipva.month, 6);
      expect(fakeInvoker.callCount, 0); // IA não chamada
    });

    test('cache expirado → chama IA e salva no cache', () async {
      // Cache expirado.
      const key = 'SC-6-2026';
      final body = _aiResponse(ipvaMonth: 6);
      await cache.write(
        key,
        jsonEncode(body),
        DateTime.now().subtract(const Duration(days: 1)), // expirado
      );

      final fakeInvoker = _FakeInvoker(result: _aiResponse(ipvaMonth: 6));
      final service = RealFiscalLookupService(
        _AdapterInvoker(fakeInvoker),
        cache,
        fallback,
      );

      final result = await service.lookup(uf: 'SC', plateLastDigit: 6, year: 2026);

      expect(result.source, FiscalLookupSource.ai);
      expect(fakeInvoker.callCount, 1); // IA chamada
      // Cache atualizado.
      final cached = await cache.read(key);
      expect(cached, isNotNull);
      expect(cached!.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('IA sucesso — source = ai, ipva.sourceCitation correto', () async {
      final fakeInvoker = _FakeInvoker(result: _aiResponse(ipvaMonth: 6));
      final service = RealFiscalLookupService(
        _AdapterInvoker(fakeInvoker),
        cache,
        fallback,
      );

      final result = await service.lookup(uf: 'SC', plateLastDigit: 6, year: 2026);

      expect(result.source, FiscalLookupSource.ai);
      expect(result.ipva.month, 6);
      expect(result.ipva.sourceCitation, 'SEFAZ-SC 2026');
    });

    test('IA falha (ScanException) → fallback localFallback, não lança', () async {
      final fakeInvoker = _FakeInvoker(throwScan: true);
      final service = RealFiscalLookupService(
        _AdapterInvoker(fakeInvoker),
        cache,
        fallback,
      );

      final result = await service.lookup(uf: 'SC', plateLastDigit: 6, year: 2026);

      expect(result.source, FiscalLookupSource.localFallback);
      expect(result.ipva.month, greaterThanOrEqualTo(1));
      expect(result.ipva.month, lessThanOrEqualTo(12));
    });

    test('QuotaExhaustedException → fallback localFallback, não lança', () async {
      final fakeInvoker = _FakeInvoker(throwQuota: true);
      final service = RealFiscalLookupService(
        _AdapterInvoker(fakeInvoker),
        cache,
        fallback,
      );

      final result = await service.lookup(uf: 'SC', plateLastDigit: 6, year: 2026);

      expect(result.source, FiscalLookupSource.localFallback);
    });

    test('UF inválida → fallback nunca lança', () async {
      final fakeInvoker = _FakeInvoker(throwScan: true);
      final service = RealFiscalLookupService(
        _AdapterInvoker(fakeInvoker),
        cache,
        fallback,
      );

      // UF desconhecida — fallback usa default calendar, não lança.
      final result = await service.lookup(
        uf: 'XX',
        plateLastDigit: 5,
        year: 2026,
      );

      expect(result.source, FiscalLookupSource.localFallback);
    });
  });

  group('FallbackComputer', () {
    test('UF conhecida (SC) retorna meses corretos', () {
      final r = fallback.compute('SC', 6, 2026);
      expect(r.source, FiscalLookupSource.localFallback);
      expect(r.ipva.month, 6); // SC: final 6 → mês 6
      expect(r.licensing.month, 9); // SC: final 6 → mês 9
    });

    test('UF desconhecida não lança', () {
      expect(() => fallback.compute('XX', 0, 2026), returnsNormally);
      final r = fallback.compute('XX', 0, 2026);
      expect(r.source, FiscalLookupSource.localFallback);
    });

    test('UF vazia não lança', () {
      expect(() => fallback.compute('', 5, 2026), returnsNormally);
    });
  });

  group('MockFiscalLookupService', () {
    test('retorna fixedResult quando configurado', () async {
      const fixed = FiscalLookupResult(
        ipva: FiscalEntry(month: 3),
        licensing: FiscalEntry(month: 7),
        source: FiscalLookupSource.ai,
      );
      final mock = MockFiscalLookupService(fixedResult: fixed);
      final r = await mock.lookup(uf: 'SP', plateLastDigit: 1, year: 2026);
      expect(r.ipva.month, 3);
      expect(mock.callCount, 1);
    });

    test('throwOnCall lança ScanException', () async {
      final mock = MockFiscalLookupService(throwOnCall: true);
      expect(
        () => mock.lookup(uf: 'SP', plateLastDigit: 1, year: 2026),
        throwsA(isA<ScanException>()),
      );
    });

    test('throwQuota lança QuotaExhaustedException', () async {
      final mock = MockFiscalLookupService(throwQuota: true);
      expect(
        () => mock.lookup(uf: 'SP', plateLastDigit: 1, year: 2026),
        throwsA(isA<QuotaExhaustedException>()),
      );
    });
  });
}


import 'package:autolog/features/insights/fiscal_lookup_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.W.3 — parse defensivo do FiscalLookupResult.
void main() {
  group('FiscalLookupResult.fromJson', () {
    test('JSON completo com source citado', () {
      final r = FiscalLookupResult.fromJson({
        'ipva': {'month': 6, 'day': 15, 'source': 'SEFAZ-SC 2026'},
        'licensing': {'month': 10, 'day': null, 'source': 'Detran-SC'},
      });
      expect(r.ipva.month, 6);
      expect(r.ipva.day, 15);
      expect(r.ipva.sourceCitation, 'SEFAZ-SC 2026');
      expect(r.licensing.month, 10);
      expect(r.licensing.day, isNull);
    });

    test('source ausente → null', () {
      final r = FiscalLookupResult.fromJson({
        'ipva': {'month': 1},
        'licensing': {'month': 6},
      });
      expect(r.ipva.sourceCitation, isNull);
      expect(r.licensing.sourceCitation, isNull);
    });

    test('roundtrip toJson/fromJson', () {
      const original = FiscalLookupResult(
        ipva: FiscalEntry(month: 6, day: 15, sourceCitation: 'SEFAZ-SC'),
        licensing: FiscalEntry(month: 10),
        source: FiscalLookupSource.ai,
      );
      final back = FiscalLookupResult.fromJson(original.toJson());
      // source NÃO entra no JSON serializado pra IA — é client-side só.
      expect(back.ipva.month, 6);
      expect(back.licensing.month, 10);
    });
  });
}

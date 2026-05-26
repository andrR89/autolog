import 'dart:typed_data';

import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_receipt.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.3 — MockScanService.
/// Spec: docs/specs/sprint-3.3-scan-flow.md
void main() {
  group('MockScanService', () {
    test('sem config: devolve ScannedReceipt com campos não-nulos', () async {
      final mock = MockScanService(delay: Duration.zero);
      final r = await mock.scan(Uint8List(0));
      expect(r.liters, isNotNull);
      expect(r.pricePerLiter, isNotNull);
      expect(r.totalCost, isNotNull);
      expect(r.date, isNotNull);
      expect(r.fuelType, isNotNull);
    });

    test('fixedResult é honrado', () async {
      final custom = ScannedReceipt(liters: Decimal.parse('99.999'));
      final mock = MockScanService(delay: Duration.zero, fixedResult: custom);
      final r = await mock.scan(Uint8List(0));
      expect(r.liters, Decimal.parse('99.999'));
      expect(r.pricePerLiter, isNull); // só liters foi setado
    });

    test('throwOnCall lança ScanException', () async {
      final mock = MockScanService(delay: Duration.zero, throwOnCall: true);
      expect(() => mock.scan(Uint8List(0)), throwsA(isA<ScanException>()));
    });
  });
}

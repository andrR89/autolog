import 'dart:convert';
import 'dart:typed_data';

import 'package:autolog/features/scan/crlv_scan_service.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_crlv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.K — pipeline do scan de CRLV.
/// Spec: docs/specs/sprint-6.K-scan-crlv.md

class _FakeInvoker implements EdgeFunctionInvoker {
  _FakeInvoker({this.response, this.throwOnInvoke});
  final Map<String, dynamic>? response;
  final Object? throwOnInvoke;

  String? lastFunctionName;
  Map<String, dynamic>? lastBody;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    callCount++;
    lastFunctionName = functionName;
    lastBody = body;
    if (throwOnInvoke != null) throw throwOnInvoke!;
    return response ?? <String, dynamic>{};
  }
}

void main() {
  final bytes = Uint8List.fromList([10, 20, 30, 40, 50]);

  group('RealCrlvScanService.scan', () {
    test('invoca "scan-crlv" com document_base64 + mime_type (image)', () async {
      final invoker = _FakeInvoker(response: <String, dynamic>{'plate': 'ABC1234'});
      final svc = RealCrlvScanService(invoker);

      await svc.scan(bytes, mimeType: 'image/jpeg');

      expect(invoker.lastFunctionName, 'scan-crlv');
      expect(invoker.lastBody!['document_base64'], base64Encode(bytes));
      expect(invoker.lastBody!['mime_type'], 'image/jpeg');
      expect(invoker.callCount, 1);
    });

    test('passa mime_type pdf corretamente', () async {
      final invoker = _FakeInvoker(response: <String, dynamic>{});
      final svc = RealCrlvScanService(invoker);
      await svc.scan(bytes, mimeType: 'application/pdf');
      expect(invoker.lastBody!['mime_type'], 'application/pdf');
    });

    test('retorna ScannedCrlv parseado', () async {
      final invoker = _FakeInvoker(response: <String, dynamic>{
        'plate': 'ABC1D23',
        'make': 'Honda',
        'model': 'CIVIC',
        'year': 2018,
      });
      final svc = RealCrlvScanService(invoker);
      final r = await svc.scan(bytes, mimeType: 'image/jpeg');
      expect(r.plate, 'ABC1D23');
      expect(r.make, 'Honda');
      expect(r.year, 2018);
    });

    test('429 → propaga QuotaExhaustedException', () async {
      final invoker = _FakeInvoker(throwOnInvoke: QuotaExhaustedException());
      final svc = RealCrlvScanService(invoker);
      expect(svc.scan(bytes, mimeType: 'image/jpeg'),
          throwsA(isA<QuotaExhaustedException>()));
    });

    test('ScanException existente propaga sem wrap', () async {
      final invoker = _FakeInvoker(throwOnInvoke: ScanException('rede caiu'));
      final svc = RealCrlvScanService(invoker);
      try {
        await svc.scan(bytes, mimeType: 'image/jpeg');
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, 'rede caiu');
      }
    });

    test('erro genérico vira ScanException com "CRLV" PT-BR', () async {
      final invoker = _FakeInvoker(throwOnInvoke: StateError('boom'));
      final svc = RealCrlvScanService(invoker);
      try {
        await svc.scan(bytes, mimeType: 'image/jpeg');
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, contains('CRLV'));
        expect(e.cause, isA<StateError>());
      }
    });
  });

  group('MockCrlvScanService', () {
    test('callCount incrementa, retorna fixedResult', () async {
      const fixed = ScannedCrlv(plate: 'XYZ9999', make: 'Fiat');
      final mock = MockCrlvScanService(
        delay: Duration.zero,
        fixedResult: fixed,
      );
      await mock.scan(bytes, mimeType: 'image/jpeg');
      await mock.scan(bytes, mimeType: 'application/pdf');
      expect(mock.callCount, 2);
    });

    test('throwOnCall lança ScanException', () async {
      final mock = MockCrlvScanService(
        delay: Duration.zero,
        throwOnCall: true,
      );
      expect(mock.scan(bytes, mimeType: 'image/jpeg'),
          throwsA(isA<ScanException>()));
    });

    test('default retorna ScannedCrlv com plate/make/model', () async {
      final mock = MockCrlvScanService(delay: Duration.zero);
      final r = await mock.scan(bytes, mimeType: 'image/jpeg');
      expect(r.plate, isNotNull);
      expect(r.make, isNotNull);
      expect(r.model, isNotNull);
    });
  });
}

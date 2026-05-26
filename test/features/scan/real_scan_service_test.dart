import 'dart:convert';
import 'dart:typed_data';

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 3.1 — RealScanService chamando a Edge Function via abstração.
/// Spec: docs/specs/sprint-3.1-edge-function.md

/// Fake invoker pra testar o RealScanService sem rede.
class _FakeInvoker implements EdgeFunctionInvoker {
  Map<String, dynamic>? returnBody;
  Object? throwError;

  // Capturas pra asserts.
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
    if (throwError != null) throw throwError!;
    return returnBody ?? <String, dynamic>{};
  }
}

void main() {
  late _FakeInvoker invoker;
  late RealScanService service;

  setUp(() {
    invoker = _FakeInvoker();
    service = RealScanService(invoker);
  });

  test('sucesso: invoker devolve JSON válido → ScannedReceipt correspondente; '
      'bytes vão base64-encodados em image_base64', () async {
    invoker.returnBody = {
      'liters': '43.219',
      'price_per_liter': '5.799',
      'total_cost': '250.626981',
      'date': '2026-05-23T00:00:00.000Z',
      'fuel_type': 'gasolina',
    };

    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final result = await service.scan(bytes);

    expect(invoker.callCount, 1);
    expect(invoker.lastFunctionName, 'scan-receipt');
    expect(invoker.lastBody!['image_base64'], base64Encode(bytes));

    expect(result.liters, Decimal.parse('43.219'));
    expect(result.pricePerLiter, Decimal.parse('5.799'));
    expect(result.totalCost, Decimal.parse('250.626981'));
    expect(result.fuelType, FuelType.gasolina);
  });

  test('JSON parcial: invoker devolve {} → ScannedReceipt com tudo null, sem '
      'lançar', () async {
    invoker.returnBody = <String, dynamic>{};
    final result = await service.scan(Uint8List.fromList([0]));
    expect(result.liters, isNull);
    expect(result.pricePerLiter, isNull);
    expect(result.totalCost, isNull);
    expect(result.date, isNull);
    expect(result.fuelType, isNull);
  });

  test('cota esgotada: invoker lança QuotaExhaustedException → propaga '
      'preservando o tipo', () async {
    invoker.throwError = QuotaExhaustedException();
    expect(
      () => service.scan(Uint8List.fromList([0])),
      throwsA(isA<QuotaExhaustedException>()),
    );
  });

  test('ScanException genérico (ex.: rede): propaga sem embrulhar', () async {
    invoker.throwError = ScanException('falha de rede');
    try {
      await service.scan(Uint8List.fromList([0]));
      fail('Deveria ter lançado');
    } on ScanException catch (e) {
      expect(e.message, 'falha de rede');
      // Confirma que NÃO embrulhou de novo (mensagem intacta, não "Falha inesperada").
      expect(e is QuotaExhaustedException, isFalse);
    }
  });

  test('erro inesperado (qualquer Exception): embrulha em ScanException '
      'preservando cause', () async {
    final original = StateError('boom');
    invoker.throwError = original;
    try {
      await service.scan(Uint8List.fromList([0]));
      fail('Deveria ter lançado');
    } on ScanException catch (e) {
      expect(e.message, contains('Falha inesperada'));
      expect(e.cause, original);
    }
  });
}

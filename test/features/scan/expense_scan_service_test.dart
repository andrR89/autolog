import 'dart:convert';
import 'dart:typed_data';

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/edge_function_invoker.dart';
import 'package:autolog/features/scan/expense_scan_service.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/scan/scanned_expense.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.F — pipeline do scan de despesa.
/// Spec: docs/specs/sprint-6.F-expense-scan.md

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
  final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

  group('RealExpenseScanService.scan', () {
    test('invoca função "scan-expense" com image_base64', () async {
      final invoker = _FakeInvoker(response: <String, dynamic>{
        'amount': '100', 'category': 'lavagem',
      });
      final svc = RealExpenseScanService(invoker);

      await svc.scan(bytes);

      expect(invoker.lastFunctionName, 'scan-expense');
      expect(invoker.lastBody!['image_base64'], base64Encode(bytes));
      expect(invoker.callCount, 1);
    });

    test('retorna ScannedExpense parseado da resposta', () async {
      final invoker = _FakeInvoker(response: <String, dynamic>{
        'amount': '250.50',
        'date': '2026-05-20T00:00:00.000Z',
        'category': 'ipva',
        'description': 'IPVA 2026',
        'document_type': 'boleto',
      });
      final svc = RealExpenseScanService(invoker);

      final r = await svc.scan(bytes);
      expect(r.amount, Decimal.parse('250.50'));
      expect(r.category, ExpenseCategory.ipva);
      expect(r.documentType, 'boleto');
    });

    test('429 → propaga QuotaExhaustedException', () async {
      final invoker = _FakeInvoker(throwOnInvoke: QuotaExhaustedException());
      final svc = RealExpenseScanService(invoker);
      expect(svc.scan(bytes), throwsA(isA<QuotaExhaustedException>()));
    });

    test('ScanException existente propaga sem wrap', () async {
      final invoker = _FakeInvoker(
        throwOnInvoke: ScanException('rede caiu'),
      );
      final svc = RealExpenseScanService(invoker);
      try {
        await svc.scan(bytes);
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, 'rede caiu');
      }
    });

    test('erro genérico vira ScanException com mensagem PT-BR', () async {
      final invoker = _FakeInvoker(throwOnInvoke: StateError('boom'));
      final svc = RealExpenseScanService(invoker);
      try {
        await svc.scan(bytes);
        fail('esperava ScanException');
      } on ScanException catch (e) {
        expect(e.message, contains('comprovante'));
        expect(e.cause, isA<StateError>());
      }
    });
  });

  group('MockExpenseScanService', () {
    test('callCount incrementa, retorna fixedResult', () async {
      final fixed = ScannedExpense(
        amount: Decimal.parse('42'),
        category: ExpenseCategory.outro,
      );
      final mock = MockExpenseScanService(
        delay: Duration.zero,
        fixedResult: fixed,
      );

      final a = await mock.scan(bytes);
      final b = await mock.scan(bytes);
      expect(mock.callCount, 2);
      expect(a.amount, Decimal.parse('42'));
      expect(b, a);
    });

    test('throwOnCall lança ScanException', () async {
      final mock = MockExpenseScanService(
        delay: Duration.zero,
        throwOnCall: true,
      );
      expect(mock.scan(bytes), throwsA(isA<ScanException>()));
    });

    test('sem fixedResult retorna receipt default não-vazio', () async {
      final mock = MockExpenseScanService(delay: Duration.zero);
      final r = await mock.scan(bytes);
      expect(r.amount, isNotNull);
      expect(r.category, isNotNull);
    });
  });
}

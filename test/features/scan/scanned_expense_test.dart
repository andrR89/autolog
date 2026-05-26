import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/scan/scanned_expense.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.F — parse defensivo do ScannedExpense.
/// Spec: docs/specs/sprint-6.F-expense-scan.md
void main() {
  group('ScannedExpense.fromJson', () {
    test('JSON completo com todos os campos válidos', () {
      final json = <String, dynamic>{
        'amount': '250.50',
        'date': '2026-05-20T00:00:00.000Z',
        'category': 'ipva',
        'description': 'IPVA 2026',
        'document_type': 'boleto',
      };
      final r = ScannedExpense.fromJson(json);
      expect(r.amount, Decimal.parse('250.50'));
      expect(r.date, DateTime.utc(2026, 5, 20));
      expect(r.category, ExpenseCategory.ipva);
      expect(r.description, 'IPVA 2026');
      expect(r.documentType, 'boleto');
    });

    test('todos os campos null → modelo válido com tudo null', () {
      final r = ScannedExpense.fromJson(<String, dynamic>{
        'amount': null,
        'date': null,
        'category': null,
        'description': null,
        'document_type': null,
      });
      expect(r.amount, isNull);
      expect(r.date, isNull);
      expect(r.category, isNull);
      expect(r.description, isNull);
      expect(r.documentType, isNull);
    });

    test('JSON vazio (sem chaves) → modelo todo null', () {
      final r = ScannedExpense.fromJson(<String, dynamic>{});
      expect(r.amount, isNull);
      expect(r.date, isNull);
      expect(r.category, isNull);
      expect(r.description, isNull);
      expect(r.documentType, isNull);
    });

    test('chaves extras são ignoradas silenciosamente', () {
      final r = ScannedExpense.fromJson(<String, dynamic>{
        'amount': '100',
        'foo': 'bar',
        'extra_field': 42,
      });
      expect(r.amount, Decimal.parse('100'));
    });

    test('categoria conhecida — todos os 8 valores', () {
      for (final c in ExpenseCategory.values) {
        final r = ScannedExpense.fromJson({'category': c.wire});
        expect(r.category, c, reason: 'categoria ${c.wire}');
      }
    });

    test('categoria desconhecida → null (defensivo)', () {
      final r = ScannedExpense.fromJson({'category': 'combustivel'});
      expect(r.category, isNull);
    });

    test('amount como string decimal precisa', () {
      final r = ScannedExpense.fromJson({'amount': '1234.5678'});
      expect(r.amount, Decimal.parse('1234.5678'));
    });

    test('description com texto livre', () {
      final r = ScannedExpense.fromJson({
        'description': 'Troca de pastilhas de freio',
      });
      expect(r.description, 'Troca de pastilhas de freio');
    });

    test('documentType com qualquer string fica preservado (validação na edge)',
        () {
      // Edge function já normaliza pra "cupom"/"boleto"/"nfe"/"outro"/null.
      // O modelo só armazena — não re-valida.
      final r = ScannedExpense.fromJson({'document_type': 'boleto'});
      expect(r.documentType, 'boleto');
    });
  });

  group('ScannedExpense roundtrip JSON', () {
    test('toJson → fromJson preserva campos', () {
      final original = ScannedExpense(
        amount: Decimal.parse('99.99'),
        date: DateTime.utc(2026, 5, 25),
        category: ExpenseCategory.manutencao,
        description: 'Troca de óleo',
        documentType: 'nfe',
      );
      final back = ScannedExpense.fromJson(original.toJson());
      expect(back, original);
    });
  });
}

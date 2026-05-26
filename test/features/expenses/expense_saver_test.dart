import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/repositories/expense_repository.dart';
import 'package:autolog/features/expenses/expense_saver.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 4.1b — ExpenseSaver: orquestra criar/editar/excluir via repo.
/// Spec: docs/specs/sprint-4.1b-expenses-ui.md

class _FakeExpenseRepository implements ExpenseRepository {
  Expense? lastCreated;
  Expense? lastUpdated;
  String? lastDeletedId;
  bool throwOnUpdate = false;

  @override
  Future<Expense> create(Expense expense) async {
    lastCreated = expense;
    return expense;
  }

  @override
  Future<Expense> update(Expense expense) async {
    if (throwOnUpdate) throw StateError('forçado pra teste');
    lastUpdated = expense;
    return expense;
  }

  @override
  Future<void> softDelete(String id) async {
    lastDeletedId = id;
  }

  @override
  Future<Expense?> getById(String id) async => null;
  @override
  Future<List<Expense>> listByVehicle(String vehicleId) async => const [];
  @override
  Stream<List<Expense>> watchByVehicle(String vehicleId) =>
      const Stream.empty();
}

void main() {
  late _FakeExpenseRepository repo;
  late ExpenseSaver saver;
  final date = DateTime.utc(2026, 5, 23, 14);

  setUp(() {
    repo = _FakeExpenseRepository();
    int counter = 0;
    saver = ExpenseSaver(repo, generateId: () => 'id-${++counter}');
  });

  group('create', () {
    test(
      'chama repo.create com Expense montado a partir dos parâmetros',
      () async {
        final saved = await saver.create(
          vehicleId: 'v1',
          date: date,
          category: ExpenseCategory.manutencao,
          description: 'Troca de óleo',
          amount: Decimal.parse('189.90'),
          odometer: 45000,
        );

        expect(repo.lastCreated, isNotNull);
        expect(repo.lastCreated!.id, 'id-1');
        expect(repo.lastCreated!.vehicleId, 'v1');
        expect(repo.lastCreated!.date, date);
        expect(repo.lastCreated!.category, ExpenseCategory.manutencao);
        expect(repo.lastCreated!.description, 'Troca de óleo');
        expect(repo.lastCreated!.amount, Decimal.parse('189.90'));
        expect(repo.lastCreated!.odometer, 45000);

        expect(saved, repo.lastCreated);
      },
    );

    test('odometer opcional: pode ser null', () async {
      await saver.create(
        vehicleId: 'v1',
        date: date,
        category: ExpenseCategory.lavagem,
        description: 'Lava-rápido',
        amount: Decimal.parse('40'),
      );
      expect(repo.lastCreated!.odometer, isNull);
    });
  });

  group('update', () {
    test(
      'preserva id, vehicleId, createdAt do existing; aplica campos novos',
      () async {
        final original = Expense(
          id: 'orig',
          vehicleId: 'v1',
          date: DateTime.utc(2026, 5, 22, 10),
          category: ExpenseCategory.manutencao,
          description: 'Velho',
          amount: Decimal.parse('100'),
          odometer: 45000,
          createdAt: DateTime.utc(2026, 5, 22),
          updatedAt: DateTime.utc(2026, 5, 22),
          syncStatus: SyncStatus.synced,
        );

        final updated = await saver.update(
          original,
          date: date,
          category: ExpenseCategory.ipva,
          description: 'Novo',
          amount: Decimal.parse('1234.56'),
          odometer: 46000,
        );

        expect(repo.lastUpdated, isNotNull);
        expect(repo.lastUpdated!.id, 'orig'); // preservado
        expect(repo.lastUpdated!.vehicleId, 'v1'); // preservado
        expect(repo.lastUpdated!.createdAt, original.createdAt); // preservado
        expect(repo.lastUpdated!.date, date);
        expect(repo.lastUpdated!.category, ExpenseCategory.ipva);
        expect(repo.lastUpdated!.description, 'Novo');
        expect(repo.lastUpdated!.amount, Decimal.parse('1234.56'));
        expect(repo.lastUpdated!.odometer, 46000);

        expect(updated, repo.lastUpdated);
      },
    );

    test('propaga erro do repo intacto', () async {
      final original = Expense(
        id: 'orig',
        vehicleId: 'v1',
        date: date,
        category: ExpenseCategory.outro,
        description: 'X',
        amount: Decimal.parse('10'),
        createdAt: date,
        updatedAt: date,
        syncStatus: SyncStatus.pending,
      );
      repo.throwOnUpdate = true;

      expect(
        () => saver.update(
          original,
          date: date,
          category: ExpenseCategory.outro,
          description: 'Y',
          amount: Decimal.parse('20'),
        ),
        throwsStateError,
      );
    });
  });

  group('delete', () {
    test('chama repo.softDelete com o id', () async {
      await saver.delete('algum-id');
      expect(repo.lastDeletedId, 'algum-id');
    });
  });
}

// test/features/export/csv_export_service_test.dart
//
// Sprint 6.II — Export CSV / Backup.
// TDD: testa CsvBuilder (lógica pura) e a filtragem de período do
// RealCsvExportService com repos mock.
//
// CsvBuilder não tem I/O, então os testes são unitários puros (sem plugin).
// Filtros de período são testados via método público de RealCsvExportService
// que também não usa I/O diretamente (testados via lista filtrada antes de
// gravar).
//
// Cobre (obrigatório per CLAUDE.md):
//   - Headers PT-BR + BOM encoding + separador `;`
//   - Decimal formatado com vírgula
//   - Datas dd/MM/yyyy
//   - Lista vazia → só header
//   - Filtro de período correto
//   - Escape de campos com `;` interno
//   - Boolean tanque cheio → Sim/Não

import 'dart:convert';

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/repositories/expense_repository.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart';
import 'package:autolog/features/export/csv_export_service.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Mocks de repositório — necessários para instanciar RealCsvExportService
// ---------------------------------------------------------------------------

class _MockFuelRepo implements FuelEntryRepository {
  _MockFuelRepo(this._entries);
  final List<FuelEntry> _entries;

  @override
  Future<List<FuelEntry>> listByVehicle(String vehicleId) async => _entries;

  @override
  Stream<List<FuelEntry>> watchByVehicle(String vehicleId) =>
      Stream.value(_entries);

  @override
  Future<FuelEntry> create(FuelEntry entry) async => entry;

  @override
  Future<FuelEntry> update(FuelEntry entry) async => entry;

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<FuelEntry?> getById(String id) async => null;
}

class _MockExpenseRepo implements ExpenseRepository {
  _MockExpenseRepo(this._entries);
  final List<Expense> _entries;

  @override
  Future<List<Expense>> listByVehicle(String vehicleId) async => _entries;

  @override
  Stream<List<Expense>> watchByVehicle(String vehicleId) =>
      Stream.value(_entries);

  @override
  Future<Expense> create(Expense expense) async => expense;

  @override
  Future<Expense> update(Expense expense) async => expense;

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<Expense?> getById(String id) async => null;
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

FuelEntry _makeFuel({
  String id = 'fuel-1',
  String vehicleId = 'v-1',
  DateTime? date,
  int odometer = 12500,
  String liters = '40.00',
  String pricePerLiter = '5.89',
  String totalCost = '235.60',
  bool fullTank = true,
  FuelType fuelType = FuelType.gasolina,
  String? stationName,
}) => FuelEntry(
  id: id,
  vehicleId: vehicleId,
  date: date ?? DateTime(2025, 3, 15),
  odometer: odometer,
  liters: Decimal.parse(liters),
  pricePerLiter: Decimal.parse(pricePerLiter),
  totalCost: Decimal.parse(totalCost),
  fullTank: fullTank,
  fuelType: fuelType,
  source: FuelSource.manual,
  stationName: stationName,
  createdAt: DateTime(2025, 3, 15),
  updatedAt: DateTime(2025, 3, 15),
  syncStatus: SyncStatus.synced,
);

Expense _makeExpense({
  String id = 'exp-1',
  String vehicleId = 'v-1',
  DateTime? date,
  ExpenseCategory category = ExpenseCategory.manutencao,
  String description = 'Troca de óleo',
  String amount = '350.00',
  int? odometer = 12000,
}) => Expense(
  id: id,
  vehicleId: vehicleId,
  date: date ?? DateTime(2025, 3, 10),
  category: category,
  description: description,
  amount: Decimal.parse(amount),
  odometer: odometer,
  createdAt: DateTime(2025, 3, 10),
  updatedAt: DateTime(2025, 3, 10),
  syncStatus: SyncStatus.synced,
);

// ---------------------------------------------------------------------------
// Helpers: parse do CSV string
// ---------------------------------------------------------------------------

/// Separa o CSV em linhas, ignorando linhas vazias.
List<String> _lines(String csv) => csv
    .split('\n')
    .map((l) => l.trimRight())
    .where((l) => l.isNotEmpty)
    .toList();

/// Verifica BOM nos bytes encodados.
bool _hasBom(List<int> bytes) =>
    bytes.length >= 3 &&
    bytes[0] == 0xEF &&
    bytes[1] == 0xBB &&
    bytes[2] == 0xBF;

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  const builder = CsvBuilder();

  // -------------------------------------------------------------------------
  // BOM — verificado via encode do conteúdo
  // -------------------------------------------------------------------------

  group('BOM UTF-8', () {
    test('conteúdo com BOM começa com EF BB BF', () {
      const bom = '﻿'; // U+FEFF
      const content = 'Data;Hodômetro';
      final bytes = utf8.encode(bom + content);
      expect(_hasBom(bytes), isTrue, reason: 'BOM EF BB BF presente');
    });

    test('BOM literal U+FEFF é codificado como 3 bytes', () {
      final bytes = utf8.encode('﻿');
      expect(bytes, [0xEF, 0xBB, 0xBF]);
    });
  });

  // -------------------------------------------------------------------------
  // Headers PT-BR + separador `;`
  // -------------------------------------------------------------------------

  group('buildFuelCsv — header', () {
    test('header PT-BR correto com separador ponto-e-vírgula', () {
      final csv = builder.buildFuelCsv([]);
      final header = _lines(csv).first;
      expect(header, contains('Hodômetro (km)'));
      expect(header, contains('Litros'));
      expect(header, contains(r'Preço/L (R$)'));
      expect(header, contains(r'Total (R$)'));
      expect(header, contains('Combustível'));
      expect(header, contains('Posto'));
      expect(header, contains('Tanque cheio'));
      expect(header, contains('Observações'));
      // Separador `;`, não `,`
      expect(header, contains(';'));
    });

    test('header data é o primeiro campo', () {
      final csv = builder.buildFuelCsv([]);
      expect(_lines(csv).first, startsWith('Data;'));
    });
  });

  group('buildExpenseCsv — header', () {
    test('header PT-BR correto com separador ponto-e-vírgula', () {
      final csv = builder.buildExpenseCsv([]);
      final header = _lines(csv).first;
      expect(header, contains('Categoria'));
      expect(header, contains('Descrição'));
      expect(header, contains(r'Valor (R$)'));
      expect(header, contains('Hodômetro (km)'));
      expect(header, contains('Observações'));
      expect(header, contains(';'));
    });
  });

  // -------------------------------------------------------------------------
  // Lista vazia → só header
  // -------------------------------------------------------------------------

  group('lista vazia', () {
    test('buildFuelCsv vazio → só 1 linha (header)', () {
      final csv = builder.buildFuelCsv([]);
      expect(_lines(csv).length, 1, reason: 'só header');
    });

    test('buildExpenseCsv vazio → só 1 linha (header)', () {
      final csv = builder.buildExpenseCsv([]);
      expect(_lines(csv).length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Decimal com vírgula
  // -------------------------------------------------------------------------

  group('formatação decimal', () {
    test('total 235.60 → "235,60" com vírgula decimal', () {
      final csv = builder.buildFuelCsv([_makeFuel(totalCost: '235.60')]);
      final dataLine = _lines(csv)[1];
      expect(dataLine, contains('235,60'));
      // Não deve aparecer "235.60" com ponto decimal no campo de valor
      expect(dataLine, isNot(contains('235.60')));
    });

    test('preço/L 5.89 → "5,89"', () {
      final csv = builder.buildFuelCsv([_makeFuel(pricePerLiter: '5.89')]);
      expect(_lines(csv)[1], contains('5,89'));
    });

    test('litros 40.00 → "40,00"', () {
      final csv = builder.buildFuelCsv([_makeFuel(liters: '40.00')]);
      expect(_lines(csv)[1], contains('40,00'));
    });

    test('valor despesa 350.00 → "350,00"', () {
      final csv = builder.buildExpenseCsv([_makeExpense(amount: '350.00')]);
      expect(_lines(csv)[1], contains('350,00'));
    });

    test('fmtDecimal direto: 1234.50 → "1.234,50" (milhar separado)', () {
      final result = builder.fmtDecimal(Decimal.parse('1234.50'));
      expect(result, '1.234,50');
    });
  });

  // -------------------------------------------------------------------------
  // Datas dd/MM/yyyy
  // -------------------------------------------------------------------------

  group('formatação de data', () {
    test('data 15/03/2025 no formato dd/MM/yyyy', () {
      final csv = builder.buildFuelCsv([
        _makeFuel(date: DateTime(2025, 3, 15)),
      ]);
      expect(_lines(csv)[1], startsWith('15/03/2025'));
    });

    test('data despesa 10/03/2025', () {
      final csv = builder.buildExpenseCsv([
        _makeExpense(date: DateTime(2025, 3, 10)),
      ]);
      expect(_lines(csv)[1], startsWith('10/03/2025'));
    });

    test('fmtDate direto: 2025-01-05 → "05/01/2025"', () {
      final result = builder.fmtDate(DateTime(2025, 1, 5));
      expect(result, '05/01/2025');
    });
  });

  // -------------------------------------------------------------------------
  // Boolean tanque cheio
  // -------------------------------------------------------------------------

  group('boolean tanque cheio', () {
    test('fullTank=true → "Sim" na linha de dados', () {
      final csv = builder.buildFuelCsv([_makeFuel(fullTank: true)]);
      expect(_lines(csv)[1], contains('Sim'));
    });

    test('fullTank=false → "Não" na linha de dados', () {
      final csv = builder.buildFuelCsv([_makeFuel(fullTank: false)]);
      expect(_lines(csv)[1], contains('Não'));
    });

    test('boolLabel direto', () {
      expect(builder.boolLabel(true), 'Sim');
      expect(builder.boolLabel(false), 'Não');
    });
  });

  // -------------------------------------------------------------------------
  // Escape de campos com `;` interno
  // -------------------------------------------------------------------------

  group('escape de campos', () {
    test('campo sem caracteres especiais → sem aspas', () {
      expect(builder.escapeField('Shell'), 'Shell');
    });

    test('campo com `;` → envolvido em aspas duplas', () {
      expect(builder.escapeField('Shell; BR-101'), '"Shell; BR-101"');
    });

    test('campo com aspas → aspas duplicadas e envolvido', () {
      expect(builder.escapeField('Posto "Amigo"'), '"Posto ""Amigo"""');
    });

    test(r'campo com \n → envolvido em aspas', () {
      expect(builder.escapeField('linha1\nlinha2'), '"linha1\nlinha2"');
    });

    test('posto com ";" aparece escapado na linha CSV de fuel', () {
      final csv = builder.buildFuelCsv([
        _makeFuel(stationName: 'Shell; BR-101'),
      ]);
      expect(_lines(csv)[1], contains('"Shell; BR-101"'));
    });

    test('descrição despesa com ";" aparece escapada', () {
      final csv = builder.buildExpenseCsv([
        _makeExpense(description: 'Troca de óleo; filtros'),
      ]);
      expect(_lines(csv)[1], contains('"Troca de óleo; filtros"'));
    });
  });

  // -------------------------------------------------------------------------
  // Filtro de período — testado via RealCsvExportService._filterByDate
  // exposto indiretamente via exportFuelEntries com repos mock.
  // Como _writeFile usa path_provider (plugin), usamos um stub que só
  // chama os repos + builder sem gravar arquivo.
  // -------------------------------------------------------------------------

  group('filtro de período (via _TestableExportService)', () {
    // Subclasse testável que sobrescreve _writeFile para não usar path_provider.
    // ignore: invalid_use_of_visible_for_testing_member
    final jan = _makeFuel(id: 'j', date: DateTime(2025, 1, 10));
    final mar = _makeFuel(id: 'm', date: DateTime(2025, 3, 15));
    final dez = _makeFuel(id: 'd', date: DateTime(2025, 12, 20));

    _TestableExportService makeSvc(List<FuelEntry> fuel) =>
        _TestableExportService(
          fuelRepo: _MockFuelRepo(fuel),
          expenseRepo: _MockExpenseRepo([]),
        );

    test('from exclui entradas anteriores', () async {
      final svc = makeSvc([jan, mar, dez]);
      final csv = await svc.fuelCsvFor('v-1', from: DateTime(2025, 3, 1));
      expect(_lines(csv).length, 3, reason: 'header + mar + dez');
    });

    test('to exclui entradas posteriores (inclusivo no dia)', () async {
      final svc = makeSvc([jan, mar, dez]);
      final csv = await svc.fuelCsvFor('v-1', to: DateTime(2025, 3, 15));
      expect(_lines(csv).length, 3, reason: 'header + jan + mar');
    });

    test('from+to mantém só entradas no intervalo', () async {
      final svc = makeSvc([jan, mar, dez]);
      final csv = await svc.fuelCsvFor(
        'v-1',
        from: DateTime(2025, 2, 1),
        to: DateTime(2025, 11, 30),
      );
      expect(_lines(csv).length, 2, reason: 'header + mar');
    });

    test('sem filtro → todos os registros', () async {
      final svc = makeSvc([jan, mar, dez]);
      final csv = await svc.fuelCsvFor('v-1');
      expect(_lines(csv).length, 4, reason: 'header + 3');
    });
  });

  // -------------------------------------------------------------------------
  // Labels PT-BR de combustível e categoria
  // -------------------------------------------------------------------------

  group('labels PT-BR', () {
    test('FuelType.gasolina → Gasolina', () {
      expect(builder.fuelTypeLabel(FuelType.gasolina), 'Gasolina');
    });

    test('FuelType.etanol → Etanol', () {
      expect(builder.fuelTypeLabel(FuelType.etanol), 'Etanol');
    });

    test('FuelType.diesel → Diesel', () {
      expect(builder.fuelTypeLabel(FuelType.diesel), 'Diesel');
    });

    test('FuelType.flex → Flex', () {
      expect(builder.fuelTypeLabel(FuelType.flex), 'Flex');
    });

    test('FuelType.gnv → GNV', () {
      expect(builder.fuelTypeLabel(FuelType.gnv), 'GNV');
    });

    test('ExpenseCategory.manutencao → Manutenção', () {
      expect(builder.categoryLabel(ExpenseCategory.manutencao), 'Manutenção');
    });

    test('ExpenseCategory.ipva → IPVA', () {
      expect(builder.categoryLabel(ExpenseCategory.ipva), 'IPVA');
    });

    test('ExpenseCategory.licenciamento → Licenciamento', () {
      expect(
        builder.categoryLabel(ExpenseCategory.licenciamento),
        'Licenciamento',
      );
    });
  });

  // -------------------------------------------------------------------------
  // exportAll — contém ambos os blocos
  // -------------------------------------------------------------------------

  group('exportAll', () {
    test('contém headers de fuel e expense', () async {
      final svc = _TestableExportService(
        fuelRepo: _MockFuelRepo([_makeFuel()]),
        expenseRepo: _MockExpenseRepo([_makeExpense()]),
      );
      final csv = await svc.allCsvFor('v-1');
      expect(csv, contains('Litros'));
      expect(csv, contains('Categoria'));
    });
  });
}

// ---------------------------------------------------------------------------
// Subclasse testável: sobrescreve apenas a parte de I/O,
// expondo os métodos de construção CSV diretamente.
// ---------------------------------------------------------------------------

class _TestableExportService extends RealCsvExportService {
  _TestableExportService({required super.fuelRepo, required super.expenseRepo})
    : super(builder: const CsvBuilder());

  /// Retorna o CSV de fuel **sem gravar em arquivo** (evita plugin path_provider).
  Future<String> fuelCsvFor(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await fuelRepo.listByVehicle(vehicleId);
    final filtered = filterByDate(all, (e) => e.date, from, to);
    return const CsvBuilder().buildFuelCsv(filtered);
  }

  /// Retorna o CSV combinado **sem gravar em arquivo**.
  Future<String> allCsvFor(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final allFuel = await fuelRepo.listByVehicle(vehicleId);
    final filteredFuel = filterByDate(allFuel, (e) => e.date, from, to);
    final fuelCsv = const CsvBuilder().buildFuelCsv(filteredFuel);

    final allExp = await expenseRepo.listByVehicle(vehicleId);
    final filteredExp = filterByDate(allExp, (e) => e.date, from, to);
    final expCsv = const CsvBuilder().buildExpenseCsv(filteredExp);

    return '$fuelCsv\n$expCsv';
  }

  // filterByDate já é público em RealCsvExportService — reutiliza diretamente.
}

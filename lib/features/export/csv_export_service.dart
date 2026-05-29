// lib/features/export/csv_export_service.dart
//
// Sprint 6.II — Export CSV / Backup.
//
// Responsabilidades:
//   - Gerar arquivos CSV de abastecimentos e/ou despesas.
//   - Encoding UTF-8 com BOM (Excel BR abre direto).
//   - Separador `;`, decimal com vírgula, datas dd/MM/yyyy.
//   - Salva no temp dir (path_provider) e retorna o path.
//
// Regras de Ouro: offline-first (usa apenas repositórios locais), Decimal no
// domínio (nunca double para dinheiro), soft-delete já filtrado pelos repos.

import 'dart:convert';
import 'dart:io';

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/repositories/expense_repository.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Abstrações
// ---------------------------------------------------------------------------

abstract class CsvExportService {
  /// Gera CSV de abastecimentos de [vehicleId].
  /// Retorna o path do arquivo gerado no temp dir.
  Future<String> exportFuelEntries(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  });

  /// Gera CSV de despesas de [vehicleId].
  /// Retorna o path do arquivo gerado no temp dir.
  Future<String> exportExpenses(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  });

  /// Gera CSV unificado (abastecimentos + despesas) de [vehicleId].
  /// Retorna o path do arquivo gerado no temp dir.
  Future<String> exportAll(String vehicleId, {DateTime? from, DateTime? to});
}

// ---------------------------------------------------------------------------
// CsvBuilder — lógica pura de formatação (testável sem I/O)
// ---------------------------------------------------------------------------

/// Constrói o conteúdo CSV (sem BOM) como [String].
///
/// Separado de I/O para facilitar testes unitários puros. O [RealCsvExportService]
/// usa esta classe internamente; testes podem instanciá-la diretamente.
class CsvBuilder {
  const CsvBuilder();

  static final _dateFormatter = DateFormat('dd/MM/yyyy');
  static final _decimalFormatter = NumberFormat('#,##0.00', 'pt_BR');

  // -------------------------------------------------------------------------
  // Builders públicos
  // -------------------------------------------------------------------------

  String buildFuelCsv(List<FuelEntry> entries) {
    final buf = StringBuffer();
    buf.writeln(
      r'Data;Hodômetro (km);Litros;Preço/L (R$);Total (R$);Combustível;Posto;Tanque cheio;Observações',
    );
    for (final e in entries) {
      buf.writeln(
        [
          fmtDate(e.date),
          e.odometer.toString(),
          fmtDecimal(e.liters),
          fmtDecimal(e.pricePerLiter),
          fmtDecimal(e.totalCost),
          fuelTypeLabel(e.fuelType),
          escapeField(e.stationName ?? ''),
          boolLabel(e.fullTank),
          escapeField(
            '',
          ), // observações — campo reservado (modelo não tem ainda)
        ].join(';'),
      );
    }
    return buf.toString();
  }

  String buildExpenseCsv(List<Expense> entries) {
    final buf = StringBuffer();
    buf.writeln(
      r'Data;Categoria;Descrição;Valor (R$);Hodômetro (km);Observações',
    );
    for (final e in entries) {
      buf.writeln(
        [
          fmtDate(e.date),
          escapeField(categoryLabel(e.category)),
          escapeField(e.description),
          fmtDecimal(e.amount),
          e.odometer?.toString() ?? '',
          escapeField(''), // observações — campo reservado
        ].join(';'),
      );
    }
    return buf.toString();
  }

  // -------------------------------------------------------------------------
  // Formatadores — visibilidade @visibleForTesting (mas públicos no Dart)
  // -------------------------------------------------------------------------

  String fmtDate(DateTime dt) => _dateFormatter.format(dt.toLocal());

  /// Formata [Decimal] com vírgula decimal e 2 casas (padrão BR).
  /// Converte para double só na borda de formatação, nunca em cálculo.
  String fmtDecimal(Decimal d) => _decimalFormatter.format(d.toDouble());

  String boolLabel(bool v) => v ? 'Sim' : 'Não';

  /// Envolve em aspas duplas e duplica aspas internas se o campo contiver
  /// `;`, `"` ou quebra de linha — RFC 4180 adaptado para separador `;`.
  String escapeField(String value) {
    if (value.contains(';') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  String fuelTypeLabel(FuelType t) {
    switch (t) {
      case FuelType.gasolina:
        return 'Gasolina';
      case FuelType.etanol:
        return 'Etanol';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.flex:
        return 'Flex';
      case FuelType.gnv:
        return 'GNV';
    }
  }

  String categoryLabel(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.manutencao:
        return 'Manutenção';
      case ExpenseCategory.lavagem:
        return 'Lavagem';
      case ExpenseCategory.estacionamento:
        return 'Estacionamento';
      case ExpenseCategory.multa:
        return 'Multa';
      case ExpenseCategory.seguro:
        return 'Seguro';
      case ExpenseCategory.ipva:
        return 'IPVA';
      case ExpenseCategory.licenciamento:
        return 'Licenciamento';
      case ExpenseCategory.outro:
        return 'Outro';
    }
  }
}

// ---------------------------------------------------------------------------
// Implementação real
// ---------------------------------------------------------------------------

class RealCsvExportService implements CsvExportService {
  RealCsvExportService({
    required this.fuelRepo,
    required this.expenseRepo,
    CsvBuilder? builder,
  }) : _builder = builder ?? const CsvBuilder();

  final FuelEntryRepository fuelRepo;
  final ExpenseRepository expenseRepo;
  final CsvBuilder _builder;

  @override
  Future<String> exportFuelEntries(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await fuelRepo.listByVehicle(vehicleId);
    final filtered = filterByDate(all, (e) => e.date, from, to);
    final csv = _builder.buildFuelCsv(filtered);
    return _writeFile(csv, 'abastecimentos_${vehicleId}_${_stamp()}.csv');
  }

  @override
  Future<String> exportExpenses(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await expenseRepo.listByVehicle(vehicleId);
    final filtered = filterByDate(all, (e) => e.date, from, to);
    final csv = _builder.buildExpenseCsv(filtered);
    return _writeFile(csv, 'despesas_${vehicleId}_${_stamp()}.csv');
  }

  @override
  Future<String> exportAll(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final allFuel = await fuelRepo.listByVehicle(vehicleId);
    final filteredFuel = filterByDate(allFuel, (e) => e.date, from, to);
    final fuelCsv = _builder.buildFuelCsv(filteredFuel);

    final allExp = await expenseRepo.listByVehicle(vehicleId);
    final filteredExp = filterByDate(allExp, (e) => e.date, from, to);
    final expCsv = _builder.buildExpenseCsv(filteredExp);

    // Combina os dois blocos separados por linha em branco.
    final combined = '$fuelCsv\n$expCsv';
    return _writeFile(combined, 'autolog_${vehicleId}_${_stamp()}.csv');
  }

  // -------------------------------------------------------------------------
  // I/O
  // -------------------------------------------------------------------------

  String _stamp() {
    final now = DateTime.now();
    return DateFormat('yyyyMMdd_HHmmss').format(now);
  }

  Future<String> _writeFile(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    // UTF-8 BOM: 0xEF 0xBB 0xBF — necessário para Excel BR abrir sem garrafar.
    const bom = '﻿';
    await file.writeAsBytes(utf8.encode(bom + content), flush: true);
    return file.path;
  }

  // -------------------------------------------------------------------------
  // Filtro de período — @protected para subclasses de teste
  // -------------------------------------------------------------------------

  /// Filtra [items] pelo intervalo [from, to] (inclusivo no dia de [to]).
  /// Método separado para permitir testes sem chamar I/O.
  List<T> filterByDate<T>(
    List<T> items,
    DateTime Function(T) getDate,
    DateTime? from,
    DateTime? to,
  ) {
    if (from == null && to == null) return items;
    return items.where((item) {
      final d = getDate(item);
      if (from != null && d.isBefore(from)) return false;
      // Inclui o dia inteiro de [to]: compara com início do dia seguinte.
      if (to != null) {
        final endOfDay = DateTime(to.year, to.month, to.day + 1);
        if (!d.isBefore(endOfDay)) return false;
      }
      return true;
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Mock (testes e desenvolvimento)
// ---------------------------------------------------------------------------

/// Mock que retorna paths fixos sem tocar em I/O.
/// Use em testes de widget ou de integração que precisam de um [CsvExportService].
class MockCsvExportService implements CsvExportService {
  const MockCsvExportService({
    this.fuelEntries = const [],
    this.expenses = const [],
  });

  final List<FuelEntry> fuelEntries;
  final List<Expense> expenses;

  @override
  Future<String> exportFuelEntries(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async => '/tmp/mock_abastecimentos.csv';

  @override
  Future<String> exportExpenses(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async => '/tmp/mock_despesas.csv';

  @override
  Future<String> exportAll(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async => '/tmp/mock_autolog.csv';
}

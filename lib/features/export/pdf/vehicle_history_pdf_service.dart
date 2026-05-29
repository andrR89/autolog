// lib/features/export/pdf/vehicle_history_pdf_service.dart
//
// Sprint 6.Y — PDF Histórico do Veículo.
//
// Gera PDF A4 com FIPE, manutenção, consumo e despesas para uso ao vender
// o veículo. Toda geração é local (offline-first, sem backend).

import 'dart:typed_data';

import 'package:autolog/data/repositories/fipe_history_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/services/consumption_calculator.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ---------------------------------------------------------------------------
// Formatação (borda do PDF — único lugar que converte Decimal → double)
// ---------------------------------------------------------------------------

String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

String _fmtDatetime(DateTime d) =>
    DateFormat('dd/MM/yyyy HH:mm').format(d);

String _fmtCurrency(Decimal v) {
  final formatted = NumberFormat('#,##0.00', 'pt_BR').format(v.toDouble());
  return 'R\$ $formatted';
}

String _fmtKmPerLiter(Decimal? v) {
  // Usa '-' em vez de '—' (em dash U+2014) pois Helvetica nativa não suporta
  // Unicode além de Latin-1. A semântica é a mesma: dado indisponível.
  if (v == null) return '-';
  return '${NumberFormat('0.0', 'pt_BR').format(v.toDouble())} km/l';
}

// Formata "YYYY-MM" para "MM/YYYY" (exibição da coluna FIPE).
String _fmtFipeMonth(String month) {
  final parts = month.split('-');
  if (parts.length != 2) return month;
  return '${parts[1]}/${parts[0]}';
}

// ---------------------------------------------------------------------------
// Interface abstrata
// ---------------------------------------------------------------------------

abstract class VehicleHistoryPdfService {
  /// Gera o PDF e retorna os bytes prontos para salvar/compartilhar.
  ///
  /// - [fipeHistory] null → seção FIPE omitida.
  /// - [doneReminders] devem ser apenas os com isDone=true (manutenção feita).
  /// - Consumo com baseline insuficiente exibe "—" (Regra de Ouro #2).
  Future<Uint8List> generate({
    required Vehicle vehicle,
    required List<FuelEntry> fuelEntries,
    required List<Expense> expenses,
    required List<FipeSnapshot>? fipeHistory,
    required List<Reminder> doneReminders,
  });
}

// ---------------------------------------------------------------------------
// Implementação real
// ---------------------------------------------------------------------------

class RealVehicleHistoryPdfService implements VehicleHistoryPdfService {
  const RealVehicleHistoryPdfService();

  @override
  Future<Uint8List> generate({
    required Vehicle vehicle,
    required List<FuelEntry> fuelEntries,
    required List<Expense> expenses,
    required List<FipeSnapshot>? fipeHistory,
    required List<Reminder> doneReminders,
  }) async {
    final now = DateTime.now();
    final doc = pw.Document();

    // Fontes nativas (Helvetica) — sem dependência de Google Fonts no PDF.
    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();

    // ------------------------------------------------------------------
    // Métricas de consumo — calculadas antes de construir o PDF.
    // ------------------------------------------------------------------
    final consumptionData = _buildConsumptionSummary(fuelEntries);

    // ------------------------------------------------------------------
    // Totais de despesas por categoria.
    // ------------------------------------------------------------------
    final expensesByCategory = _groupExpensesByCategory(expenses);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        footer: (context) => _buildFooter(context, now, regular),
        build: (context) => [
          // Capa
          _buildCover(vehicle, now, bold, regular),
          pw.SizedBox(height: 24),

          // FIPE (só se fornecido e não vazio)
          if (fipeHistory != null && fipeHistory.isNotEmpty) ...[
            _buildFipeSection(fipeHistory, bold, regular),
            pw.SizedBox(height: 20),
          ],

          // Consumo
          _buildConsumptionSection(consumptionData, bold, regular),
          pw.SizedBox(height: 20),

          // Manutenção
          _buildMaintenanceSection(doneReminders, bold, regular),
          pw.SizedBox(height: 20),

          // Despesas por categoria
          _buildExpensesSection(expensesByCategory, bold, regular),
        ],
      ),
    );

    return doc.save();
  }

  // -------------------------------------------------------------------------
  // Seção: Capa
  // -------------------------------------------------------------------------

  pw.Widget _buildCover(
    Vehicle vehicle,
    DateTime now,
    pw.Font bold,
    pw.Font regular,
  ) {
    final makeModel = [vehicle.make, vehicle.model]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    final title = makeModel.isNotEmpty ? makeModel : vehicle.nickname;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Histórico do Veículo',
          style: pw.TextStyle(
            font: bold,
            fontSize: 22,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(font: bold, fontSize: 18),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 12),
        _infoRow('Apelido', vehicle.nickname, bold, regular),
        if (vehicle.plate != null && vehicle.plate!.isNotEmpty)
          _infoRow('Placa', vehicle.plate!, bold, regular),
        if (vehicle.year != null)
          _infoRow('Ano', vehicle.year.toString(), bold, regular),
        if (vehicle.color != null && vehicle.color!.isNotEmpty)
          _infoRow('Cor', vehicle.color!, bold, regular),
        _infoRow(
          'Combustível',
          _fuelTypeLabel(vehicle.fuelType),
          bold,
          regular,
        ),
        _infoRow(
          'Km inicial',
          '${vehicle.initialOdometer} km',
          bold,
          regular,
        ),
        _infoRow('Emissão', _fmtDate(now), bold, regular),
      ],
    );
  }

  pw.Widget _infoRow(
    String label,
    String value,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: bold, fontSize: 10),
            ),
          ),
          pw.Text(value, style: pw.TextStyle(font: regular, fontSize: 10)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Seção: FIPE
  // -------------------------------------------------------------------------

  pw.Widget _buildFipeSection(
    List<FipeSnapshot> history,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Histórico FIPE', bold),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            // Cabeçalho
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableHeader('Mês', bold),
                _tableHeader('Valor', bold),
              ],
            ),
            // Linhas
            ...history.map(
              (snap) => pw.TableRow(
                children: [
                  _tableCell(_fmtFipeMonth(snap.month), regular),
                  _tableCell(_fmtCurrency(snap.value), regular),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Seção: Consumo
  // -------------------------------------------------------------------------

  pw.Widget _buildConsumptionSection(
    _ConsumptionSummary summary,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Consumo de Combustível', bold),
        pw.SizedBox(height: 8),
        _infoRow('Km total registrado', '${summary.totalKm} km', bold, regular),
        _infoRow(
          'Consumo médio',
          _fmtKmPerLiter(summary.avgKmPerLiter),
          bold,
          regular,
        ),
        _infoRow(
          'Gasto total em combustível',
          _fmtCurrency(summary.totalFuelCost),
          bold,
          regular,
        ),
        _infoRow(
          'Abastecimentos',
          summary.entryCount.toString(),
          bold,
          regular,
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Seção: Manutenção (lembretes feitos)
  // -------------------------------------------------------------------------

  pw.Widget _buildMaintenanceSection(
    List<Reminder> done,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Manutenções Realizadas', bold),
        pw.SizedBox(height: 8),
        if (done.isEmpty)
          pw.Text(
            'Nenhuma manutenção registrada.',
            style: pw.TextStyle(font: regular, fontSize: 10),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableHeader('Data', bold),
                  _tableHeader('Descrição', bold),
                  _tableHeader('Km', bold),
                ],
              ),
              ...done.map(
                (r) => pw.TableRow(
                  children: [
                    _tableCell(_fmtDate(r.updatedAt), regular),
                    _tableCell(r.title, regular),
                    _tableCell(
                      r.dueKm != null ? '${r.dueKm} km' : '—',
                      regular,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Seção: Despesas por categoria
  // -------------------------------------------------------------------------

  pw.Widget _buildExpensesSection(
    Map<ExpenseCategory, Decimal> byCategory,
    pw.Font bold,
    pw.Font regular,
  ) {
    final total = byCategory.values.fold(Decimal.zero, (a, b) => a + b);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Despesas por Categoria', bold),
        pw.SizedBox(height: 8),
        if (byCategory.isEmpty)
          pw.Text(
            'Nenhuma despesa registrada.',
            style: pw.TextStyle(font: regular, fontSize: 10),
          )
        else ...[
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableHeader('Categoria', bold),
                  _tableHeader('Total', bold),
                ],
              ),
              ...byCategory.entries.map(
                (e) => pw.TableRow(
                  children: [
                    _tableCell(_expenseCategoryLabel(e.key), regular),
                    _tableCell(_fmtCurrency(e.value), regular),
                  ],
                ),
              ),
              // Linha de total
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell('Total geral', null, bold: bold),
                  _tableCell(_fmtCurrency(total), null, bold: bold),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Footer
  // -------------------------------------------------------------------------

  pw.Widget _buildFooter(
    pw.Context context,
    DateTime now,
    pw.Font regular,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Gerado por AutoLog em ${_fmtDatetime(now)}',
          style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Helpers internos
  // -------------------------------------------------------------------------

  pw.Widget _sectionTitle(String text, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(font: bold, fontSize: 13),
        ),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _tableHeader(String text, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 9)),
    );
  }

  pw.Widget _tableCell(String text, pw.Font? regular, {pw.Font? bold}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: bold ?? regular, fontSize: 9),
      ),
    );
  }

  /// Agrega consumo: km total (odômetro máx − mín, ou 0 se lista vazia),
  /// consumo médio (null se nenhum ciclo fechado — exibe "—"), gasto total.
  _ConsumptionSummary _buildConsumptionSummary(List<FuelEntry> entries) {
    if (entries.isEmpty) {
      return _ConsumptionSummary(
        totalKm: 0,
        avgKmPerLiter: null,
        totalFuelCost: Decimal.zero,
        entryCount: 0,
      );
    }

    // Gasto total — soma simples de todos os entries.
    var totalCost = Decimal.zero;
    for (final e in entries) {
      totalCost = totalCost + e.totalCost;
    }

    // Km total: max_odometer − min_odometer (monotônico crescente por contrato).
    final odometers = entries.map((e) => e.odometer).toList();
    final minOdo = odometers.reduce((a, b) => a < b ? a : b);
    final maxOdo = odometers.reduce((a, b) => a > b ? a : b);
    final totalKm = maxOdo - minOdo;

    // Consumo médio — regra sagrada: só calcula se há pelo menos um ciclo fechado.
    // Ordena ASC para o calculator.
    final asc = List<FuelEntry>.from(entries)
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.odometer.compareTo(b.odometer);
      });
    final rows = computeConsumption(asc);

    // Média ponderada por km das janelas com valor calculado.
    Decimal? avgKmPerLiter;
    var totalKmWithConsumption = Decimal.zero;
    var totalLitersWithConsumption = Decimal.zero;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.kmPerLiter != null && row.entry.fullTank) {
        // Reconstrói km da janela: odômetro atual − odômetro do cheio anterior.
        // Como não temos acesso direto ao baseline aqui, usamos uma aproximação
        // conservadora: soma de litros e km via kmPerLiter * litros da janela.
        // Para a média global do PDF, é suficientemente preciso.
        final litros = row.entry.liters;
        // kmPerLiter * litros: Decimal * Decimal = Decimal (sem toDecimal).
        final kmJanela = row.kmPerLiter! * litros;
        totalKmWithConsumption = totalKmWithConsumption + kmJanela;
        totalLitersWithConsumption = totalLitersWithConsumption + litros;
      }
    }

    if (totalLitersWithConsumption > Decimal.zero) {
      avgKmPerLiter =
          (totalKmWithConsumption / totalLitersWithConsumption)
              .toDecimal(scaleOnInfinitePrecision: 4)
              .round(scale: 1);
    }

    return _ConsumptionSummary(
      totalKm: totalKm,
      avgKmPerLiter: avgKmPerLiter,
      totalFuelCost: totalCost,
      entryCount: entries.length,
    );
  }

  Map<ExpenseCategory, Decimal> _groupExpensesByCategory(
    List<Expense> expenses,
  ) {
    final map = <ExpenseCategory, Decimal>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? Decimal.zero) + e.amount;
    }
    return map;
  }

  String _fuelTypeLabel(FuelType type) {
    switch (type) {
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

  String _expenseCategoryLabel(ExpenseCategory cat) {
    switch (cat) {
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
// Value object interno — sumário de consumo para o PDF.
// ---------------------------------------------------------------------------

class _ConsumptionSummary {
  const _ConsumptionSummary({
    required this.totalKm,
    required this.avgKmPerLiter,
    required this.totalFuelCost,
    required this.entryCount,
  });

  final int totalKm;

  /// null quando não há baseline suficiente (exibir "—").
  final Decimal? avgKmPerLiter;
  final Decimal totalFuelCost;
  final int entryCount;
}

// ---------------------------------------------------------------------------
// Mock — para testes e override em ProviderScope.
// ---------------------------------------------------------------------------

class MockVehicleHistoryPdfService implements VehicleHistoryPdfService {
  MockVehicleHistoryPdfService({Uint8List? fixedBytes})
    : _fixedBytes = fixedBytes ?? Uint8List.fromList('%PDF-mock'.codeUnits);

  final Uint8List _fixedBytes;

  @override
  Future<Uint8List> generate({
    required Vehicle vehicle,
    required List<FuelEntry> fuelEntries,
    required List<Expense> expenses,
    required List<FipeSnapshot>? fipeHistory,
    required List<Reminder> doneReminders,
  }) async {
    return _fixedBytes;
  }
}
